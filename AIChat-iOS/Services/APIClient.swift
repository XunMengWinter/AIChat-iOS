//
//  APIClient.swift
//  AIChat-iOS
//

import Alamofire
import Foundation

final class APIClient {
    private final class StreamState: @unchecked Sendable {
        private let lock = NSLock()
        private var response: HTTPURLResponse?
        private var streamOpenedAt: CFAbsoluteTime?
        private var didLogFirstDelta = false

        func setResponse(_ response: HTTPURLResponse) {
            lock.lock()
            self.response = response
            lock.unlock()
        }

        func responseValue() -> HTTPURLResponse? {
            lock.lock()
            defer { lock.unlock() }
            return response
        }

        func setStreamOpenedAt(_ streamOpenedAt: CFAbsoluteTime) {
            lock.lock()
            self.streamOpenedAt = streamOpenedAt
            lock.unlock()
        }

        func consumeFirstDeltaStreamOpenedAt() -> CFAbsoluteTime? {
            lock.lock()
            defer { lock.unlock() }

            guard !didLogFirstDelta else { return nil }
            didLogFirstDelta = true
            return streamOpenedAt
        }
    }

    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let session: Session
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: Session = APIClient.makeSession(),
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
            let response = await session
                .request(request)
                .serializingData(automaticallyCancelling: true, dataPreprocessor: PassthroughPreprocessor())
                .response

            let data = response.data ?? Data()

            if let httpResponse = response.response {
                logResponse(httpResponse, data: data, requestID: requestID, startedAt: startTime, isStream: false)
            }

            if let error = response.error {
                throw mapNetworkError(error)
            }

            guard let httpResponse = response.response else {
                throw APIError.invalidResponse
            }

            try validate(response: httpResponse, data: data)
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
        let streamState = StreamState()
        logRequest(request, requestID: requestID, isStream: true)

        do {
            let request = session
                .streamRequest(request, automaticallyCancelOnStreamError: false)
                .onHTTPResponse { response in
                    streamState.setResponse(response)

                    guard (200...299).contains(response.statusCode) else { return }

                    let openedAt = CFAbsoluteTimeGetCurrent()
                    streamState.setStreamOpenedAt(openedAt)
                    self.logStreamOpened(response, requestID: requestID, startedAt: startTime)
                }
            let task = request.streamTask()
            var eventLines: [String] = []
            var pendingText = ""
            var errorText = ""

            for await stream in task.streamingStrings(automaticallyCancelling: true, bufferingPolicy: .unbounded) {
                if let value = stream.value {
                    if let httpResponse = streamState.responseValue(), (200...299).contains(httpResponse.statusCode) {
                        try await processStreamChunk(
                            value,
                            requestID: requestID,
                            startedAt: startTime,
                            streamState: streamState,
                            eventLines: &eventLines,
                            pendingText: &pendingText,
                            onEvent: onEvent
                        )
                    } else {
                        errorText.append(value)
                    }
                }

                if let completion = stream.completion {
                    if let error = completion.error {
                        throw mapNetworkError(error)
                    }

                    let httpResponse = completion.response ?? streamState.responseValue()
                    guard let httpResponse else {
                        throw APIError.invalidResponse
                    }

                    if !(200...299).contains(httpResponse.statusCode) {
                        let data = Data(errorText.utf8)
                        logResponse(httpResponse, data: data, requestID: requestID, startedAt: startTime, isStream: true)
                        try validate(response: httpResponse, data: data)
                    }

                    try await finalizeStreamBuffer(
                        requestID: requestID,
                        startedAt: startTime,
                        streamState: streamState,
                        eventLines: &eventLines,
                        pendingText: &pendingText,
                        onEvent: onEvent
                    )

                    log("[\(requestID)] stream completed duration=\(formattedDuration(since: startTime))")
                }
            }
        } catch let error as APIError {
            logError(error, requestID: requestID, startedAt: startTime)
            throw error
        } catch {
            let wrappedError = mapNetworkError(error)
            logError(wrappedError, requestID: requestID, startedAt: startTime)
            throw wrappedError
        }
    }

    private func processStreamChunk(
        _ chunk: String,
        requestID: String,
        startedAt: CFAbsoluteTime,
        streamState: StreamState,
        eventLines: inout [String],
        pendingText: inout String,
        onEvent: @escaping (String) async -> Void
    ) async throws {
        pendingText.append(chunk)

        let normalizedText = pendingText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalizedText.components(separatedBy: "\n")
        pendingText = lines.last ?? ""

        for line in lines.dropLast() {
            if line.isEmpty {
                try await flushEventLines(
                    requestID: requestID,
                    startedAt: startedAt,
                    streamState: streamState,
                    eventLines: &eventLines,
                    onEvent: onEvent
                )
            } else {
                eventLines.append(line)
            }
        }
    }

    private func finalizeStreamBuffer(
        requestID: String,
        startedAt: CFAbsoluteTime,
        streamState: StreamState,
        eventLines: inout [String],
        pendingText: inout String,
        onEvent: @escaping (String) async -> Void
    ) async throws {
        if !pendingText.isEmpty {
            eventLines.append(pendingText)
            pendingText.removeAll(keepingCapacity: true)
        }

        try await flushEventLines(
            requestID: requestID,
            startedAt: startedAt,
            streamState: streamState,
            eventLines: &eventLines,
            onEvent: onEvent
        )
    }

    private func flushEventLines(
        requestID: String,
        startedAt: CFAbsoluteTime,
        streamState: StreamState,
        eventLines: inout [String],
        onEvent: @escaping (String) async -> Void
    ) async throws {
        guard !eventLines.isEmpty else { return }

        let lines = eventLines
        eventLines.removeAll(keepingCapacity: true)

        try await processEventLines(
            lines,
            requestID: requestID,
            startedAt: startedAt,
            streamState: streamState,
            onEvent: onEvent
        )
    }

    private func processEventLines(
        _ lines: [String],
        requestID: String,
        startedAt: CFAbsoluteTime,
        streamState: StreamState,
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
                    if let streamOpenedAt = streamState.consumeFirstDeltaStreamOpenedAt() {
                        let totalDuration = formattedDuration(since: startedAt)
                        let openDuration = String(format: "%.3fs", CFAbsoluteTimeGetCurrent() - streamOpenedAt)
                        log("[\(requestID)] FIRST DELTA after_request=\(totalDuration) after_stream_open=\(openDuration)")
                    }
                    log("[\(requestID)] delta \(preview(content, limit: 140))")
                    await onEvent(content)
                }
            }
        }
    }

    private func mapNetworkError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        if let afError = error as? AFError {
            if let underlyingError = afError.underlyingError {
                return APIError.network(underlyingError.localizedDescription)
            }
            return APIError.network(afError.localizedDescription)
        }

        return APIError.network(error.localizedDescription)
    }

    private static func makeSession() -> Session {
        let configuration = URLSessionConfiguration.af.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 180
        return Session(configuration: configuration)
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
