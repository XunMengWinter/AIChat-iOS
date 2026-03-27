//
//  HistoryMessage.swift
//  AIChat-iOS
//

import Foundation

struct HistoryMessage: Codable, Equatable, Identifiable {
    let id: Int
    let senderRole: String
    let content: String
    let hasImage: Bool
    let isPartial: Bool
    let createdAt: Date

    var isFromUser: Bool {
        senderRole == "user"
    }
}
