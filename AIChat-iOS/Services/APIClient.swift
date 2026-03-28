//
//  APIClient.swift
//  AIChat-iOS
//

import Foundation

final class APIClient {
    private final class StreamTimingState {
        var streamOpenedAt: CFAbsoluteTime?
        var didLogFirstDelta = false
    }

    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

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
        accept: String? = "application/json",
        timeoutInterval: TimeInterval = 30,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accept {
            request.setValue(accept, forHTTPHeaderField: "Accept")
        }
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
        let requestID = shortRequestID()
        let startTime = CFAbsoluteTimeGetCurrent()
        logRequest(request, requestID: requestID, isStream: false)

        do {
            let (data, response) = try await session.data(for: request)
            logResponse(response, data: data, requestID: requestID, startedAt: startTime, isStream: false)
            try validate(response: response, data: data)
            do {
                let value = try decoder.decode(T.self, from: data)
                log("[\(requestID)] decode success type=\(String(describing: T.self))")
                return value
            } catch {
                log("[\(requestID)] decode failed type=\(String(describing: T.self)) error=\(error.localizedDescription)")
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            logError(error, requestID: requestID, startedAt: startTime)
            throw error
        } catch {
            let wrappedError = APIError.network(error.localizedDescription)
            logError(wrappedError, requestID: requestID, startedAt: startTime)
            throw wrappedError
        }
    }

    func stream(
        _ request: URLRequest,
        onEvent: @escaping (String) async -> Void
    ) async throws {
        let requestID = shortRequestID()
        let startTime = CFAbsoluteTimeGetCurrent()
        let timingState = StreamTimingState()
        logRequest(request, requestID: requestID, isStream: true)

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
                logResponse(response, data: data, requestID: requestID, startedAt: startTime, isStream: true)
                try validate(response: response, data: data)
                return
            }

            timingState.streamOpenedAt = CFAbsoluteTimeGetCurrent()
            logStreamOpened(httpResponse, requestID: requestID, startedAt: startTime)
            var eventLines: [String] = []

            for try await line in bytes.lines {
                if line.isEmpty {
                    try await processEventLines(
                        eventLines,
                        requestID: requestID,
                        startedAt: startTime,
                        timingState: timingState,
                        onEvent: onEvent
                    )
                    eventLines.removeAll(keepingCapacity: true)
                    continue
                }
                eventLines.append(line)
            }

            if !eventLines.isEmpty {
                try await processEventLines(
                    eventLines,
                    requestID: requestID,
                    startedAt: startTime,
                    timingState: timingState,
                    onEvent: onEvent
                )
            }

            log("[\(requestID)] stream completed duration=\(formattedDuration(since: startTime))")
        } catch let error as APIError {
            logError(error, requestID: requestID, startedAt: startTime)
            throw error
        } catch {
            let wrappedError = APIError.network(error.localizedDescription)
            logError(wrappedError, requestID: requestID, startedAt: startTime)
            throw wrappedError
        }
    }

    private func processEventLines(
        _ lines: [String],
        requestID: String,
        startedAt: CFAbsoluteTime,
        timingState: StreamTimingState,
        onEvent: @escaping (String) async -> Void
    ) async throws {
        let payloads = lines.compactMap { line -> String? in
            guard line.hasPrefix("data:") else { return nil }
            return String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        }

        for payload in payloads where !payload.isEmpty {
            if payload == "[DONE]" {
                log("[\(requestID)] stream payload [DONE]")
                return
            }
            log("[\(requestID)] stream payload \(preview(payload, limit: 220))")
            let data = Data(payload.utf8)
            let chunk: StreamChunk
            do {
                chunk = try decoder.decode(StreamChunk.self, from: data)
            } catch {
                throw APIError.invalidStreamPayload
            }
            for choice in chunk.choices {
                if let content = choice.delta.content, !content.isEmpty {
                    if !timingState.didLogFirstDelta {
                        timingState.didLogFirstDelta = true
                        let totalDuration = formattedDuration(since: startedAt)
                        let openDuration = timingState.streamOpenedAt.map { streamOpenedAt in
                            String(format: "%.3fs", CFAbsoluteTimeGetCurrent() - streamOpenedAt)
                        } ?? "n/a"
                        log("[\(requestID)] FIRST DELTA after_request=\(totalDuration) after_stream_open=\(openDuration)")
                    }
                    log("[\(requestID)] delta \(preview(content, limit: 140))")
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

    private func shortRequestID() -> String {
        String(UUID().uuidString.prefix(8))
    }

    private func logRequest(_ request: URLRequest, requestID: String, isStream: Bool) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown>"
        let headers = summarizedHeaders(request.allHTTPHeaderFields ?? [:])
        let body = summarizedBody(request.httpBody)
        let kind = isStream ? "STREAM REQUEST" : "REQUEST"
        log("[\(requestID)] \(kind) \(method) \(url) headers=\(headers) body=\(body)")
    }

    private func logResponse(
        _ response: URLResponse,
        data: Data,
        requestID: String,
        startedAt: CFAbsoluteTime,
        isStream: Bool
    ) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let kind = isStream ? "STREAM RESPONSE" : "RESPONSE"
        let body = summarizedBody(data)
        log("[\(requestID)] \(kind) status=\(statusCode) duration=\(formattedDuration(since: startedAt)) body=\(body)")
    }

    private func logStreamOpened(_ response: HTTPURLResponse, requestID: String, startedAt: CFAbsoluteTime) {
        let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? "<none>"
        log("[\(requestID)] STREAM OPEN status=\(response.statusCode) contentType=\(contentType) duration=\(formattedDuration(since: startedAt))")
    }

    private func logError(_ error: Error, requestID: String, startedAt: CFAbsoluteTime) {
        log("[\(requestID)] ERROR duration=\(formattedDuration(since: startedAt)) message=\(error.localizedDescription)")
    }

    private func log(_ message: String) {
//        let timestamp = Self.logDateFormatter.string(from: Date())
//        print("[API] \(timestamp) \(message)")
    }

    private func formattedDuration(since startTime: CFAbsoluteTime) -> String {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return String(format: "%.3fs", duration)
    }

    private func summarizedHeaders(_ headers: [String: String]) -> String {
        guard !headers.isEmpty else { return "{}" }
        let redacted = headers
            .sorted { $0.key < $1.key }
            .map { key, value in
                let lowercasedKey = key.lowercased()
                if lowercasedKey == "authorization" {
                    return "\(key): <redacted>"
                }
                return "\(key): \(value)"
            }
            .joined(separator: ", ")
        return "{\(redacted)}"
    }

    private func summarizedBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "nil" }

        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let sanitizedObject = sanitizedJSONObject(jsonObject),
            let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitizedObject, options: [.sortedKeys]),
            let jsonString = String(data: sanitizedData, encoding: .utf8)
        {
            return preview(jsonString, limit: 360)
        }

        if let rawString = String(data: data, encoding: .utf8) {
            return preview(rawString, limit: 360)
        }

        return "<\(data.count) bytes>"
    }

    private func sanitizedJSONObject(_ object: Any, key: String? = nil) -> Any? {
        switch object {
        case let dictionary as [String: Any]:
            var sanitizedDictionary: [String: Any] = [:]
            for (key, value) in dictionary {
                sanitizedDictionary[key] = sanitizedJSONObject(value, key: key)
            }
            return sanitizedDictionary
        case let array as [Any]:
            return array.compactMap { sanitizedJSONObject($0) }
        case let string as String:
            return sanitizedString(string, forKey: key)
        default:
            return object
        }
    }

    private func sanitizedString(_ string: String, forKey key: String?) -> String {
        let normalizedKey = (key ?? "").lowercased()
        switch normalizedKey {
        case "authorization", "access_token", "accesstoken":
            return "<redacted>"
        case "verify_code", "verifycode":
            return "<redacted>"
        case "phone_number", "phonenumber":
            return maskedPhoneNumber(string)
        case "image_base64", "imagebase64":
            return "<base64 \(string.count) chars>"
        default:
            return preview(string, limit: 120)
        }
    }

    private func maskedPhoneNumber(_ phoneNumber: String) -> String {
        guard phoneNumber.count > 4 else { return "<redacted>" }
        let suffix = phoneNumber.suffix(4)
        return "***\(suffix)"
    }

    private func preview(_ string: String, limit: Int) -> String {
        guard string.count > limit else { return string }
        let prefix = string.prefix(limit)
        return "\(prefix)…"
    }
}
