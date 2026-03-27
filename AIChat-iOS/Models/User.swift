//
//  User.swift
//  AIChat-iOS
//

import Foundation

struct User: Codable, Equatable {
    let uid: String
    let phoneNumber: String
    let countryCode: String
}
