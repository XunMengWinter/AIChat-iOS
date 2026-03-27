//
//  ChatService.swift
//  AIChat-iOS
//

import Foundation

final class ChatService {
    private let client: APIClient
    private let baseURL = URL(string: "https://aichattest-chat-otqjepryyc.cn-hangzhou.fcapp.run")!

    init(client: APIClient) {
        self.client = client
    }

    func fetchRoles() async throws -> [Role] {
        let request = client.makeRequest(
            url: baseURL.appending(path: "chat/roles"),
            method: "GET"
        )
        let response = try await client.perform(request, as: RolesResponse.self)
        return response.roles
    }

    func fetchHistory(roleCode: String, accessToken: String) async throws -> [HistoryMessage] {
        var components = URLComponents(url: baseURL.appending(path: "chat/history"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "role_code", value: roleCode)]
        guard let url = components?.url else {
            throw APIError.invalidResponse
        }
        let request = client.makeRequest(url: url, method: "GET", accessToken: accessToken)
        let response = try await client.perform(request, as: HistoryResponse.self)
        return response.messages.sorted { $0.createdAt < $1.createdAt }
    }

    func clearChat(roleCode: String, accessToken: String) async throws -> ClearChatResponse {
        struct RequestBody: Encodable {
            let roleCode: String
        }

        let body = try client.encodeBody(RequestBody(roleCode: roleCode))
        let request = client.makeRequest(
            url: baseURL.appending(path: "chat/clear"),
            method: "POST",
            accessToken: accessToken,
            body: body
        )
        return try await client.perform(request, as: ClearChatResponse.self)
    }

    func streamChat(
        roleCode: String,
        message: String?,
        imageBase64: String?,
        imageMimeType: String?,
        accessToken: String,
        onDelta: @escaping (String) async -> Void
    ) async throws {
        struct RequestBody: Encodable {
            let roleCode: String
            let message: String?
            let imageBase64: String?
            let imageMimeType: String?
        }

        let body = try client.encodeBody(
            RequestBody(
                roleCode: roleCode,
                message: message,
                imageBase64: imageBase64,
                imageMimeType: imageMimeType
            )
        )
        let request = client.makeRequest(
            url: baseURL.appending(path: "chat/stream"),
            method: "POST",
            accessToken: accessToken,
            body: body
        )
        try await client.stream(request, onEvent: onDelta)
    }
}
