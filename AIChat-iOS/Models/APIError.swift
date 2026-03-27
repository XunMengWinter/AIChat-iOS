//
//  APIError.swift
//  AIChat-iOS
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case decodingFailed
    case network(String)
    case unauthorized
    case server(code: String?, message: String)
    case missingAccessToken
    case invalidStreamPayload
    case imageProcessingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务器返回了无法识别的数据。"
        case .decodingFailed:
            return "数据解析失败，请稍后再试。"
        case .network(let message):
            return message
        case .unauthorized:
            return "登录已失效，请重新登录。"
        case .server(_, let message):
            return message
        case .missingAccessToken:
            return "当前未登录，无法继续操作。"
        case .invalidStreamPayload:
            return "聊天流数据解析失败，请重试。"
        case .imageProcessingFailed(let message):
            return message
        }
    }
}

struct APIErrorResponse: Decodable {
    let success: Bool?
    let code: String?
    let message: String
}
