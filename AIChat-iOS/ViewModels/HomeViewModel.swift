//
//  HomeViewModel.swift
//  AIChat-iOS
//

import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var recentChats: [RecentChatSummary] = []
    @Published private(set) var isLoadingRecentChats = false
    @Published var recentChatsErrorMessage: String?

    private let chatService: ChatService

    convenience init() {
        self.init(chatService: ChatService(client: APIClient()))
    }

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func refreshRecentChats(
        roles: [Role],
        accessToken: String?,
        onUnauthorized: @escaping () -> Void
    ) async {
        guard !roles.isEmpty else {
            recentChats = []
            return
        }

        guard let accessToken else {
            onUnauthorized()
            return
        }

        isLoadingRecentChats = true
        recentChatsErrorMessage = nil

        do {
            var summaries: [RecentChatSummary] = []
            for role in roles {
                let messages = try await chatService.fetchHistory(roleCode: role.roleCode, accessToken: accessToken)
                guard let lastMessage = messages.last else {
                    continue
                }
                summaries.append(RecentChatSummary(role: role, lastMessage: lastMessage))
            }
            recentChats = summaries.sorted { $0.lastMessage.createdAt > $1.lastMessage.createdAt }
        } catch APIError.unauthorized {
            onUnauthorized()
        } catch {
            recentChatsErrorMessage = error.localizedDescription
        }

        isLoadingRecentChats = false
    }
}
