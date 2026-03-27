//
//  APIJSONDecoder.swift
//  AIChat-iOS
//

import Foundation

enum APIJSONDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(AppDateFormatter.apiDateFormatter)
        return decoder
    }()
}
