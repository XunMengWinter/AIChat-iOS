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

    private enum KeychainAccount {
        static let loginSession = "loginSession"
    }

    private let userDefaults: UserDefaults
    private let keychainStore: KeychainStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        keychainStore: KeychainStore = KeychainStore()
    ) {
        self.userDefaults = userDefaults
        self.keychainStore = keychainStore
    }

    func loadSession() -> LoginSession? {
        userDefaults.removeObject(forKey: Key.loginSession)

        let data: Data?
        do {
            data = try keychainStore.data(for: KeychainAccount.loginSession)
        } catch {
            return nil
        }

        guard let data else { return nil }
        return try? decoder.decode(LoginSession.self, from: data)
    }

    func saveSession(_ session: LoginSession?) {
        userDefaults.removeObject(forKey: Key.loginSession)

        guard let session else {
            try? keychainStore.delete(account: KeychainAccount.loginSession)
            return
        }
        if let data = try? encoder.encode(session) {
            try? keychainStore.save(data, for: KeychainAccount.loginSession)
        }
    }

    func loadSelectedRoleCode() -> String? {
        userDefaults.string(forKey: Key.selectedRoleCode)
    }

    func saveSelectedRoleCode(_ roleCode: String?) {
        guard let roleCode else {
            userDefaults.removeObject(forKey: Key.selectedRoleCode)
            return
        }
        userDefaults.set(roleCode, forKey: Key.selectedRoleCode)
    }

    func loadHasCompletedSelection() -> Bool {
        userDefaults.bool(forKey: Key.hasCompletedSelection)
    }

    func saveHasCompletedSelection(_ completed: Bool) {
        userDefaults.set(completed, forKey: Key.hasCompletedSelection)
    }

    func clearAccountState() {
        saveSession(nil)
        saveSelectedRoleCode(nil)
        saveHasCompletedSelection(false)
    }
}
