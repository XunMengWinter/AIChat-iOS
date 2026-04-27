//
//  UserProfile.swift
//  AIChat-iOS
//

import Foundation

struct UserProfile: Decodable, Equatable {
    let nickname: String?
    let gender: String?
    let birthday: String?
    let city: String?
    let occupation: String?
    let interests: [String]
    let preferences: [String: String]

    init(
        nickname: String? = nil,
        gender: String? = nil,
        birthday: String? = nil,
        city: String? = nil,
        occupation: String? = nil,
        interests: [String] = [],
        preferences: [String: String] = [:]
    ) {
        self.nickname = nickname
        self.gender = gender
        self.birthday = birthday
        self.city = city
        self.occupation = occupation
        self.interests = interests
        self.preferences = preferences
    }

    private enum CodingKeys: String, CodingKey {
        case nickname
        case gender
        case birthday
        case city
        case occupation
        case interests
        case preferences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        occupation = try container.decodeIfPresent(String.self, forKey: .occupation)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
        preferences = (try? container.decode([String: String].self, forKey: .preferences)) ?? [:]
    }
}

struct UserProfileInput: Encodable {
    let nickname: String?
    let gender: String?
    let birthday: String?
    let city: String?
    let occupation: String?
    let interests: [String]
    let preferences: [String: String]

    private enum CodingKeys: String, CodingKey {
        case nickname
        case gender
        case birthday
        case city
        case occupation
        case interests
        case preferences
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(gender, forKey: .gender)
        try container.encode(birthday, forKey: .birthday)
        try container.encode(city, forKey: .city)
        try container.encode(occupation, forKey: .occupation)
        try container.encode(interests, forKey: .interests)
        try container.encode(preferences, forKey: .preferences)
    }
}
