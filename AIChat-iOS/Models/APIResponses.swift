//
//  APIResponses.swift
//  AIChat-iOS
//

import Foundation

struct SendCodeResponse: Decodable {
    let success: Bool
    let message: String
    let requestID: String?
    let bizID: String?
    let isTestAccount: Bool?

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case requestID = "requestId"
        case bizID = "bizId"
        case isTestAccount
    }
}

struct LoginResponse: Decodable {
    let success: Bool
    let message: String
    let tokenType: String
    let accessToken: String
    let expiresIn: Int
    let user: User
    let isTestAccount: Bool?

    var session: LoginSession {
        LoginSession(
            tokenType: tokenType,
            accessToken: accessToken,
            expiresIn: expiresIn,
            user: user,
            isTestAccount: isTestAccount ?? false
        )
    }
}

struct RolesResponse: Decodable {
    let success: Bool
    let roles: [Role]
}

struct HistoryResponse: Decodable {
    let success: Bool
    let roleCode: String
    let messages: [HistoryMessage]
}

struct ClearChatResponse: Decodable {
    let success: Bool
    let message: String
    let deletedCount: Int?
}
