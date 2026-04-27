//
//  SettingsViewModel.swift
//  AIChat-iOS
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isDeletingAccount = false
    @Published private(set) var isLoadingProfile = false
    @Published private(set) var isSavingProfile = false
    @Published private(set) var profile: UserProfile?
    @Published var nicknameText = ""
    @Published var selectedGender = "未设置"
    @Published var isBirthdayEnabled = false
    @Published var birthdayDate = Date()
    @Published var cityText = ""
    @Published var occupationText = ""
    @Published var interestsText = ""
    @Published var replyStyleText = ""
    @Published var successMessage: String?
    @Published var errorMessage: String?

    private let loginService: LoginService
    private var hasLoadedProfile = false

    convenience init() {
        self.init(loginService: LoginService(client: APIClient()))
    }

    init(loginService: LoginService) {
        self.loginService = loginService
    }

    func loadProfileIfNeeded(accessToken: String?) async {
        guard !hasLoadedProfile, !isLoadingProfile else { return }
        await loadProfile(accessToken: accessToken)
    }

    func loadProfile(accessToken: String?) async {
        guard let accessToken else {
            errorMessage = APIError.missingAccessToken.localizedDescription
            return
        }

        isLoadingProfile = true
        errorMessage = nil
        successMessage = nil
        defer { isLoadingProfile = false }

        do {
            let profile = try await loginService.fetchProfile(accessToken: accessToken)
            self.profile = profile
            hasLoadedProfile = true
            fillForm(with: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile(accessToken: String?) async {
        guard !isSavingProfile else { return }

        guard let accessToken else {
            errorMessage = APIError.missingAccessToken.localizedDescription
            return
        }

        isSavingProfile = true
        errorMessage = nil
        successMessage = nil
        defer { isSavingProfile = false }

        do {
            let updatedProfile = try await loginService.updateProfile(
                input: makeProfileInput(),
                accessToken: accessToken
            )
            profile = updatedProfile
            hasLoadedProfile = true
            fillForm(with: updatedProfile)
            successMessage = "用户资料已保存"
        } catch {
            errorMessage = error.localizedDescription
        }
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

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func fillForm(with profile: UserProfile) {
        nicknameText = profile.nickname ?? ""
        selectedGender = profile.gender.flatMap { $0.isEmpty ? nil : $0 } ?? "未设置"
        cityText = profile.city ?? ""
        occupationText = profile.occupation ?? ""
        interestsText = profile.interests.joined(separator: "，")
        replyStyleText = profile.preferences["reply_style"] ?? ""

        if let birthday = profile.birthday,
           let date = AppDateFormatter.profileBirthdayFormatter.date(from: birthday) {
            birthdayDate = date
            isBirthdayEnabled = true
        } else {
            birthdayDate = Date()
            isBirthdayEnabled = false
        }
    }

    private func makeProfileInput() -> UserProfileInput {
        var preferences = profile?.preferences ?? [:]
        let replyStyle = normalizedText(replyStyleText)
        if let replyStyle {
            preferences["reply_style"] = replyStyle
        } else {
            preferences.removeValue(forKey: "reply_style")
        }

        return UserProfileInput(
            nickname: normalizedText(nicknameText),
            gender: selectedGender == "未设置" ? nil : selectedGender,
            birthday: isBirthdayEnabled ? AppDateFormatter.profileBirthdayFormatter.string(from: birthdayDate) : nil,
            city: normalizedText(cityText),
            occupation: normalizedText(occupationText),
            interests: parsedInterests(),
            preferences: preferences
        )
    }

    private func normalizedText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parsedInterests() -> [String] {
        interestsText
            .components(separatedBy: CharacterSet(charactersIn: ",，、\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
