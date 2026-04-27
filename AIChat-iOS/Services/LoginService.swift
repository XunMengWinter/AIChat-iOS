//
//  LoginService.swift
//  AIChat-iOS
//

import Foundation

final class LoginService {
    private let client: APIClient
    private let baseURL = URL(string: "https://aichattst-login-zgtmdzmukf.cn-hangzhou.fcapp.run")!

    init(client: APIClient) {
        self.client = client
    }

    func sendCode(phoneNumber: String, countryCode: String = "86") async throws -> SendCodeResponse {
        struct RequestBody: Encodable {
            let phoneNumber: String
            let countryCode: String
        }

        let url = baseURL.appending(path: "send_code")
        let body = try client.encodeBody(RequestBody(phoneNumber: phoneNumber, countryCode: countryCode))
        let request = client.makeRequest(url: url, method: "POST", body: body)
        return try await client.perform(request, as: SendCodeResponse.self)
    }

    func login(
        phoneNumber: String,
        verifyCode: String,
        countryCode: String = "86"
    ) async throws -> LoginSession {
        struct RequestBody: Encodable {
            let phoneNumber: String
            let countryCode: String
            let verifyCode: String
        }

        let url = baseURL.appending(path: "login")
        let body = try client.encodeBody(RequestBody(phoneNumber: phoneNumber, countryCode: countryCode, verifyCode: verifyCode))
        let request = client.makeRequest(url: url, method: "POST", body: body)
        let response = try await client.perform(request, as: LoginResponse.self)
        return response.session
    }

    func deleteAccount(accessToken: String) async throws -> DeleteAccountResponse {
        let url = baseURL.appending(path: "account")
        let request = client.makeRequest(
            url: url,
            method: "DELETE",
            accessToken: accessToken
        )
        return try await client.perform(request, as: DeleteAccountResponse.self)
    }

    func fetchProfile(accessToken: String) async throws -> UserProfile {
        let request = client.makeRequest(
            url: baseURL.appending(path: "account/profile"),
            method: "GET",
            accessToken: accessToken
        )
        let response = try await client.perform(request, as: UserProfileResponse.self)
        return response.profile
    }

    func updateProfile(input: UserProfileInput, accessToken: String) async throws -> UserProfile {
        let body = try client.encodeBody(input)
        let request = client.makeRequest(
            url: baseURL.appending(path: "account/profile"),
            method: "PUT",
            accessToken: accessToken,
            body: body
        )
        let response = try await client.perform(request, as: UpdateUserProfileResponse.self)
        return response.profile
    }
}
