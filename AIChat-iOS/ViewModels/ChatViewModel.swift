//
//  ChatViewModel.swift
//  AIChat-iOS
//

import Combine
import CoreGraphics
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
    private struct PendingImageMatch {
        let text: String
        let previewImageData: Data

        func matches(content: String) -> Bool {
            text.trimmingCharacters(in: .whitespacesAndNewlines) == content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

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
    private var pendingImageMatches: [PendingImageMatch] = []
    private var localImagePreviewByHistoryID: [Int: Data] = [:]

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
        if activeRoleCode != role.roleCode {
            resetConversationState(for: role.roleCode)
        }

        guard let accessToken else {
            onUnauthorized()
            return
        }

        isLoadingHistory = true
        errorMessage = nil

        do {
            let history = try await chatService.fetchHistory(roleCode: role.roleCode, accessToken: accessToken)
            applyHistory(history, fallbackOpeningMessage: role.openingMessage)
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            errorMessage = error.localizedDescription
            if messages.isEmpty {
                messages = [openingMessage(role.openingMessage)]
            }
        }

        isLoadingHistory = false
    }

    func sendMessage(
        for role: Role,
        accessToken: String?,
        onUnauthorized: @escaping () -> Void
    ) async {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedDraftImage = draftImage
        guard !trimmedText.isEmpty || selectedDraftImage != nil else { return }
        guard let accessToken else {
            onUnauthorized()
            return
        }

        errorMessage = nil
        draftText = ""
        draftImage = nil

        let userMessage = ChatMessageItem(
            id: UUID().uuidString,
            sender: .user,
            content: trimmedText,
            createdAt: Date(),
            isStreaming: false,
            hasImage: selectedDraftImage != nil,
            imagePreviewData: selectedDraftImage?.previewImageData
        )
        messages.append(userMessage)

        if let selectedDraftImage {
            pendingImageMatches.append(
                PendingImageMatch(
                    text: trimmedText,
                    previewImageData: selectedDraftImage.previewImageData
                )
            )
        }

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

        do {
            try await chatService.streamChat(
                roleCode: role.roleCode,
                message: trimmedText.isEmpty ? nil : trimmedText,
                imageBase64: selectedDraftImage?.imageBase64,
                imageMimeType: selectedDraftImage?.mimeType,
                accessToken: accessToken
            ) { [weak self] delta in
                await MainActor.run {
                    self?.appendStream(delta, to: streamingID)
                }
            }

            let history = try await chatService.fetchHistory(roleCode: role.roleCode, accessToken: accessToken)
            applyHistory(history, fallbackOpeningMessage: role.openingMessage)
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            markStreamingFinished(for: streamingID)
            errorMessage = error.localizedDescription
        }

        isSending = false
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
        guard let accessToken else {
            onUnauthorized()
            return
        }

        isClearing = true
        errorMessage = nil

        do {
            _ = try await chatService.clearChat(roleCode: role.roleCode, accessToken: accessToken)
            pendingImageMatches.removeAll()
            localImagePreviewByHistoryID.removeAll()
            messages = [openingMessage(role.openingMessage)]
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            errorMessage = error.localizedDescription
        }

        isClearing = false
    }

    private func applyHistory(_ history: [HistoryMessage], fallbackOpeningMessage: String) {
        if history.isEmpty {
            messages = [openingMessage(fallbackOpeningMessage)]
            return
        }

        var resolvedPreviewByHistoryID = localImagePreviewByHistoryID
        var unmatchedPendingImages = pendingImageMatches

        for message in history.reversed() where message.isFromUser && message.hasImage {
            guard resolvedPreviewByHistoryID[message.id] == nil else { continue }
            guard let matchIndex = unmatchedPendingImages.lastIndex(where: { $0.matches(content: message.content) }) else {
                continue
            }
            resolvedPreviewByHistoryID[message.id] = unmatchedPendingImages.remove(at: matchIndex).previewImageData
        }

        localImagePreviewByHistoryID = resolvedPreviewByHistoryID
        pendingImageMatches = unmatchedPendingImages

        messages = history.map { message in
            ChatMessageItem(
                id: "history-\(message.id)",
                sender: message.isFromUser ? .user : .assistant,
                content: message.content,
                createdAt: message.createdAt,
                isStreaming: false,
                hasImage: message.hasImage,
                imagePreviewData: resolvedPreviewByHistoryID[message.id]
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

    private func resetConversationState(for roleCode: String) {
        activeRoleCode = roleCode
        messages = []
        draftText = ""
        draftImage = nil
        errorMessage = nil
        pendingImageMatches.removeAll()
        localImagePreviewByHistoryID.removeAll()
    }
}
