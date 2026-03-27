//
//  StreamChunk.swift
//  AIChat-iOS
//

import Foundation

struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta
    }

    let id: String?
    let choices: [Choice]
}
