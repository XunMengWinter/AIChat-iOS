//
//  RecentChatSummary.swift
//  AIChat-iOS
//

import Foundation

struct RecentChatSummary: Equatable, Identifiable {
    let role: Role
    let lastMessage: HistoryMessage

    var id: String { role.roleCode }
}
