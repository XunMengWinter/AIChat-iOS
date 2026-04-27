//
//  SettingsViewModel.swift
//  AIChat-iOS
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isDeletingAccount = false
    @Published var errorMessage: String?

    private let loginService: LoginService

    convenience init() {
        self.init(loginService: LoginService(client: APIClient()))
    }

    init(loginService: LoginService) {
        self.loginService = loginService
    }

    func deleteAccount(accessToken: String?) async -> Bool {
        guard !isDeletingAccount else { return false }

        guard let accessToken else {
            errorMessage = APIError.missingAccessToken.localizedDescription
            return false
        }

        isDeletingAccount = true
        errorMessage = nil
        defer { isDeletingAccount = false }

        do {
            _ = try await loginService.deleteAccount(accessToken: accessToken)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
