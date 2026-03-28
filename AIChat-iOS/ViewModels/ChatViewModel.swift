//
//  ChatViewModel.swift
//  AIChat-iOS
//

import Combine
import Foundation

struct ChatMessageItem: Identifiable, Equatable {
    enum Sender {
        case user
        case assistant
    }

    let id: String
    let sender: Sender
    var content: String
    let createdAt: Date
    var isStreaming: Bool
    let hasImage: Bool
    let imagePreviewData: Data?
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessageItem] = []
    @Published var draftText = ""
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var isSending = false
    @Published private(set) var isClearing = false
    @Published private(set) var isPreparingImage = false
    @Published var errorMessage: String?
    @Published private(set) var draftImage: DraftChatImage?

    private let chatService: ChatService
    private var activeRoleCode: String?
    private var activeConversationID = UUID()
    private var latestHistoryRequestID = UUID()

    convenience init() {
        self.init(chatService: ChatService(client: APIClient()))
    }

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func loadHistory(
        for role: Role,
        accessToken: String?,
        onUnauthorized: @escaping () -> Void
    ) async {
        let conversationID = activateConversationIfNeeded(for: role.roleCode)

        guard let accessToken else {
            onUnauthorized()
            return
        }

        let requestID = UUID()
        latestHistoryRequestID = requestID
        isLoadingHistory = true
        errorMessage = nil
        defer {
            if shouldApplyHistoryResult(
                roleCode: role.roleCode,
                conversationID: conversationID,
                requestID: requestID
            ) {
                isLoadingHistory = false
            }
        }

        do {
            let history = try await chatService.fetchHistory(roleCode: role.roleCode, accessToken: accessToken)
            guard shouldApplyHistoryResult(
                roleCode: role.roleCode,
                conversationID: conversationID,
                requestID: requestID
            ) else {
                return
            }
            applyHistory(history, fallbackOpeningMessage: role.openingMessage)
        } catch is CancellationError {
            return
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            guard shouldApplyHistoryResult(
                roleCode: role.roleCode,
                conversationID: conversationID,
                requestID: requestID
            ) else {
                return
            }
            errorMessage = error.localizedDescription
            if messages.isEmpty {
                messages = [openingMessage(role.openingMessage)]
            }
        }
    }

    func sendMessage(
        for role: Role,
        accessToken: String?,
        onUnauthorized: @escaping () -> Void
    ) async {
        guard !isSending else { return }

        let conversationID = activateConversationIfNeeded(for: role.roleCode)
        let originalDraftText = draftText
        let trimmedText = originalDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedDraftImage = draftImage
        guard !trimmedText.isEmpty || selectedDraftImage != nil else { return }
        guard let accessToken else {
            onUnauthorized()
            return
        }

        errorMessage = nil
        draftText = ""
        draftImage = nil
        invalidateHistoryRequests()

        let userMessageID = UUID().uuidString
        let userMessage = ChatMessageItem(
            id: userMessageID,
            sender: .user,
            content: trimmedText,
            createdAt: Date(),
            isStreaming: false,
            hasImage: selectedDraftImage != nil,
            imagePreviewData: selectedDraftImage?.previewImageData
        )
        messages.append(userMessage)

        let streamingID = UUID().uuidString
        messages.append(
            ChatMessageItem(
                id: streamingID,
                sender: .assistant,
                content: "",
                createdAt: Date(),
                isStreaming: true,
                hasImage: false,
                imagePreviewData: nil
            )
        )

        isSending = true
        defer {
            if isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) {
                isSending = false
            }
        }

        do {
            try await chatService.streamChat(
                roleCode: role.roleCode,
                message: trimmedText.isEmpty ? nil : trimmedText,
                imageBase64: selectedDraftImage?.imageBase64,
                imageMimeType: selectedDraftImage?.mimeType,
                accessToken: accessToken
            ) { [weak self] delta in
                await MainActor.run {
                    guard
                        let self,
                        self.isActiveConversation(roleCode: role.roleCode, conversationID: conversationID)
                    else {
                        return
                    }
                    self.appendStream(delta, to: streamingID)
                }
            }
            guard isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) else {
                return
            }
            markStreamingFinished(for: streamingID)
        } catch is CancellationError {
            guard isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) else {
                return
            }
            rollbackSend(
                userMessageID: userMessageID,
                streamingMessageID: streamingID,
                restoreDraftText: originalDraftText,
                restoreDraftImage: selectedDraftImage
            )
        } catch APIError.unauthorized {
            if isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) {
                removeMessages(withIDs: [userMessageID, streamingID])
            }
            onUnauthorized()
        } catch {
            guard isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) else {
                return
            }
            handleSendFailure(
                error,
                userMessageID: userMessageID,
                streamingMessageID: streamingID,
                originalDraftText: originalDraftText,
                originalDraftImage: selectedDraftImage
            )
        }
    }

    func useQuickTopic(_ topic: String) {
        draftText = topic
    }

    func prepareDraftImage(from imageData: Data) async {
        isPreparingImage = true
        errorMessage = nil

        do {
            let processedImage = try await Task.detached(priority: .userInitiated) {
                try ChatImageProcessor.processImageData(imageData)
            }.value
            draftImage = processedImage
        } catch {
            errorMessage = error.localizedDescription
        }

        isPreparingImage = false
    }

    func clearDraftImage() {
        draftImage = nil
    }

    func setImageSelectionError(_ message: String) {
        errorMessage = message
    }

    func canSendMessage() -> Bool {
        let hasText = !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return !isSending && (hasText || draftImage != nil)
    }

    func clearChat(
        for role: Role,
        accessToken: String?,
        onUnauthorized: @escaping () -> Void
    ) async {
        guard !isClearing, !isSending else { return }

        let conversationID = activateConversationIfNeeded(for: role.roleCode)
        guard let accessToken else {
            onUnauthorized()
            return
        }

        isClearing = true
        errorMessage = nil
        invalidateHistoryRequests()
        defer {
            if isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) {
                isClearing = false
            }
        }

        do {
            _ = try await chatService.clearChat(roleCode: role.roleCode, accessToken: accessToken)
            guard isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) else {
                return
            }
            draftText = ""
            draftImage = nil
            messages = [openingMessage(role.openingMessage)]
        } catch is CancellationError {
            return
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            guard isActiveConversation(roleCode: role.roleCode, conversationID: conversationID) else {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    private func applyHistory(_ history: [HistoryMessage], fallbackOpeningMessage: String) {
        let normalizedHistory = normalizedHistoryMessages(history)

        if normalizedHistory.isEmpty {
            messages = [openingMessage(fallbackOpeningMessage)]
            return
        }

        messages = normalizedHistory.map { message in
            ChatMessageItem(
                id: "history-\(message.id)",
                sender: message.isFromUser ? .user : .assistant,
                content: message.content,
                createdAt: message.createdAt,
                isStreaming: false,
                hasImage: message.hasImage,
                imagePreviewData: nil
            )
        }
    }

    private func openingMessage(_ content: String) -> ChatMessageItem {
        ChatMessageItem(
            id: "opening-message",
            sender: .assistant,
            content: content,
            createdAt: Date(),
            isStreaming: false,
            hasImage: false,
            imagePreviewData: nil
        )
    }

    private func appendStream(_ delta: String, to messageID: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[index].content.append(delta)
        messages[index].isStreaming = true
    }

    private func markStreamingFinished(for messageID: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[index].isStreaming = false
        if messages[index].content.isEmpty {
            messages.remove(at: index)
        }
    }

    private func handleSendFailure(
        _ error: Error,
        userMessageID: String,
        streamingMessageID: String,
        originalDraftText: String,
        originalDraftImage: DraftChatImage?
    ) {
        let hasAssistantReply = messageHasRenderableContent(messageID: streamingMessageID)
        markStreamingFinished(for: streamingMessageID)
        errorMessage = error.localizedDescription

        guard hasAssistantReply == false else { return }

        removeMessages(withIDs: [userMessageID])
        restoreDraftIfPossible(text: originalDraftText, image: originalDraftImage)
    }

    private func rollbackSend(
        userMessageID: String,
        streamingMessageID: String,
        restoreDraftText: String,
        restoreDraftImage: DraftChatImage?
    ) {
        removeMessages(withIDs: [userMessageID, streamingMessageID])
        restoreDraftIfPossible(text: restoreDraftText, image: restoreDraftImage)
    }

    private func restoreDraftIfPossible(text: String, image: DraftChatImage?) {
        let hasExistingDraftText = !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasExistingDraftText == false, draftImage == nil else { return }
        draftText = text
        draftImage = image
    }

    private func removeMessages(withIDs ids: [String]) {
        let idSet = Set(ids)
        messages.removeAll { idSet.contains($0.id) }
    }

    private func messageHasRenderableContent(messageID: String) -> Bool {
        guard let message = messages.first(where: { $0.id == messageID }) else { return false }
        return !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.hasImage
    }

    private func normalizedHistoryMessages(_ history: [HistoryMessage]) -> [HistoryMessage] {
        let committedMessages = history.filter { $0.isPartial == false }
        let sourceMessages = committedMessages.isEmpty ? history : committedMessages

        return sourceMessages.filter { message in
            !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.hasImage
        }
    }

    private func activateConversationIfNeeded(for roleCode: String) -> UUID {
        if activeRoleCode != roleCode {
            resetConversationState(for: roleCode)
        }
        return activeConversationID
    }

    private func isActiveConversation(roleCode: String, conversationID: UUID) -> Bool {
        activeRoleCode == roleCode && activeConversationID == conversationID
    }

    private func shouldApplyHistoryResult(roleCode: String, conversationID: UUID, requestID: UUID) -> Bool {
        isActiveConversation(roleCode: roleCode, conversationID: conversationID) && latestHistoryRequestID == requestID
    }

    private func invalidateHistoryRequests() {
        latestHistoryRequestID = UUID()
    }

    private func resetConversationState(for roleCode: String) {
        activeRoleCode = roleCode
        activeConversationID = UUID()
        invalidateHistoryRequests()
        messages = []
        draftText = ""
        draftImage = nil
        errorMessage = nil
        isLoadingHistory = false
        isSending = false
        isClearing = false
    }
}
