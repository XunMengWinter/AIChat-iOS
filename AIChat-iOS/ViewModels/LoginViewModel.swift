//
//  LoginViewModel.swift
//  AIChat-iOS
//

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published private(set) var countdown = 0
    @Published private(set) var isSendingCode = false
    @Published private(set) var isLoggingIn = false
    @Published var infoMessage: String?
    @Published var errorMessage: String?

    private let loginService: LoginService
    private var countdownTask: Task<Void, Never>?

    convenience init() {
        self.init(loginService: LoginService(client: APIClient()))
    }

    init(loginService: LoginService) {
        self.loginService = loginService
    }

    deinit {
        countdownTask?.cancel()
    }

    var canSendCode: Bool {
        countdown == 0 && isValidPhoneNumber
    }

    var canLogin: Bool {
        isValidPhoneNumber && verificationCode.count == 4 && !isLoggingIn
    }

    func sendCode() async {
        guard isValidPhoneNumber else {
            errorMessage = "请输入正确的手机号"
            return
        }

        errorMessage = nil
        infoMessage = nil
        isSendingCode = true

        do {
            let response = try await loginService.sendCode(phoneNumber: phoneNumber)
            infoMessage = response.message
            startCountdown()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSendingCode = false
    }

    func login() async throws -> LoginSession {
        guard isValidPhoneNumber else {
            errorMessage = "请输入正确的手机号"
            throw APIError.network("请输入正确的手机号")
        }
        guard verificationCode.count == 4 else {
            errorMessage = "请输入4位验证码"
            throw APIError.network("请输入4位验证码")
        }

        errorMessage = nil
        infoMessage = nil
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            return try await loginService.login(phoneNumber: phoneNumber, verifyCode: verificationCode)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private var isValidPhoneNumber: Bool {
        let digits = phoneNumber.filter(\.isNumber)
        return (5...11).contains(digits.count)
    }

    private func startCountdown(from seconds: Int = 60) {
        countdownTask?.cancel()
        countdown = seconds
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                self.countdown -= 1
            }
        }
    }
}
