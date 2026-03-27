//
//  LoginSession.swift
//  AIChat-iOS
//

import Foundation

struct LoginSession: Codable, Equatable {
    let tokenType: String
    let accessToken: String
    let expiresIn: Int
    let user: User
    let isTestAccount: Bool

    var authorizationHeader: String {
        "\(tokenType) \(accessToken)"
    }
}
