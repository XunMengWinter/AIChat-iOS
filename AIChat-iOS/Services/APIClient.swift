//
//  APIClient.swift
//  AIChat-iOS
//

import Foundation

final class APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = APIJSONDecoder.shared,
        encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return encoder
        }()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func makeRequest(
        url: URL,
        method: String,
        accessToken: String? = nil,
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    func encodeBody<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    func stream(
        _ request: URLRequest,
        onEvent: @escaping (String) async -> Void
    ) async throws {
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if !(200...299).contains(httpResponse.statusCode) {
                var data = Data()
                for try await byte in bytes {
                    data.append(byte)
                }
                try validate(response: response, data: data)
                return
            }

            var eventLines: [String] = []

            for try await line in bytes.lines {
                if line.isEmpty {
                    try await processEventLines(eventLines, onEvent: onEvent)
                    eventLines.removeAll(keepingCapacity: true)
                    continue
                }
                eventLines.append(line)
            }

            if !eventLines.isEmpty {
                try await processEventLines(eventLines, onEvent: onEvent)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    private func processEventLines(
        _ lines: [String],
        onEvent: @escaping (String) async -> Void
    ) async throws {
        let payloads = lines.compactMap { line -> String? in
            guard line.hasPrefix("data:") else { return nil }
            return String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        }

        for payload in payloads where !payload.isEmpty {
            if payload == "[DONE]" {
                return
            }
            let data = Data(payload.utf8)
            let chunk: StreamChunk
            do {
                chunk = try decoder.decode(StreamChunk.self, from: data)
            } catch {
                throw APIError.invalidStreamPayload
            }
            for choice in chunk.choices {
                if let content = choice.delta.content, !content.isEmpty {
                    await onEvent(content)
                }
            }
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard !(httpResponse.statusCode == 401) else {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.server(code: errorResponse.code, message: errorResponse.message)
            }
            if let message = String(data: data, encoding: .utf8), !message.isEmpty {
                throw APIError.server(code: nil, message: message)
            }
            throw APIError.invalidResponse
        }
    }
}
