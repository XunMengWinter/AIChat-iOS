//
//  AppStorage.swift
//  AIChat-iOS
//

import Foundation

final class AppStorage {
    private enum Key {
        static let loginSession = "app.loginSession"
        static let selectedRoleCode = "app.selectedRoleCode"
        static let hasCompletedSelection = "app.hasCompletedSelection"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSession() -> LoginSession? {
        guard let data = userDefaults.data(forKey: Key.loginSession) else {
            return nil
        }
        return try? decoder.decode(LoginSession.self, from: data)
    }

    func saveSession(_ session: LoginSession?) {
        guard let session else {
            userDefaults.removeObject(forKey: Key.loginSession)
            return
        }
        if let data = try? encoder.encode(session) {
            userDefaults.set(data, forKey: Key.loginSession)
        }
    }

    func loadSelectedRoleCode() -> String? {
        userDefaults.string(forKey: Key.selectedRoleCode)
    }

    func saveSelectedRoleCode(_ roleCode: String?) {
        userDefaults.set(roleCode, forKey: Key.selectedRoleCode)
    }

    func loadHasCompletedSelection() -> Bool {
        userDefaults.bool(forKey: Key.hasCompletedSelection)
    }

    func saveHasCompletedSelection(_ completed: Bool) {
        userDefaults.set(completed, forKey: Key.hasCompletedSelection)
    }
}
