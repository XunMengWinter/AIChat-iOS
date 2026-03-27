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
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessageItem] = []
    @Published var draftText = ""
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var isSending = false
    @Published private(set) var isClearing = false
    @Published var errorMessage: String?

    private let chatService: ChatService

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
        guard !trimmedText.isEmpty else { return }
        guard let accessToken else {
            onUnauthorized()
            return
        }

        errorMessage = nil
        draftText = ""

        let userMessage = ChatMessageItem(
            id: UUID().uuidString,
            sender: .user,
            content: trimmedText,
            createdAt: Date(),
            isStreaming: false
        )
        messages.append(userMessage)

        let streamingID = UUID().uuidString
        messages.append(
            ChatMessageItem(
                id: streamingID,
                sender: .assistant,
                content: "",
                createdAt: Date(),
                isStreaming: true
            )
        )

        isSending = true

        do {
            try await chatService.streamChat(
                roleCode: role.roleCode,
                message: trimmedText,
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

        messages = history.map { message in
            ChatMessageItem(
                id: "history-\(message.id)",
                sender: message.isFromUser ? .user : .assistant,
                content: message.content,
                createdAt: message.createdAt,
                isStreaming: false
            )
        }
    }

    private func openingMessage(_ content: String) -> ChatMessageItem {
        ChatMessageItem(
            id: "opening-message",
            sender: .assistant,
            content: content,
            createdAt: Date(),
            isStreaming: false
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
}
