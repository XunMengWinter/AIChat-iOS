//
//  Role.swift
//  AIChat-iOS
//

import Foundation

struct Role: Codable, Equatable, Identifiable {
    let roleCode: String
    let nickname: String
    let intro: String
    let avatarURL: String
    let backgroundURL: String
    let openingMessage: String

    var id: String { roleCode }

    var avatarURLValue: URL? { URL(string: avatarURL) }
    var backgroundURLValue: URL? { URL(string: backgroundURL) }

    private enum CodingKeys: String, CodingKey {
        case roleCode
        case nickname
        case intro
        case avatarURL = "avatarUrl"
        case backgroundURL = "backgroundUrl"
        case openingMessage
    }
}
