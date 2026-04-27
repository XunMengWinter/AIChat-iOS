//
//  AppSessionStore.swift
//  AIChat-iOS
//

import Combine
import Foundation

@MainActor
final class AppSessionStore: ObservableObject {
    enum Screen: Equatable {
        case onboarding
        case login
        case home
        case settings
        case chat(roleCode: String)
    }

    @Published private(set) var screen: Screen = .onboarding
    @Published private(set) var roles: [Role] = []
    @Published private(set) var isLoadingRoles = false
    @Published private(set) var rolesErrorMessage: String?
    @Published private(set) var loginSession: LoginSession?
    @Published private(set) var selectedRoleCode: String?
    @Published private(set) var hasCompletedSelection = false

    private let storage: AppStorage
    private let chatService: ChatService
    private var hasBootstrapped = false

    convenience init() {
        self.init(
            storage: AppStorage(),
            chatService: ChatService(client: APIClient())
        )
    }

    init(
        storage: AppStorage,
        chatService: ChatService
    ) {
        self.storage = storage
        self.chatService = chatService
        self.loginSession = storage.loadSession()
        self.selectedRoleCode = storage.loadSelectedRoleCode()
        self.hasCompletedSelection = storage.loadHasCompletedSelection()
        updateInitialScreen()
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        await refreshRoles()
    }

    func refreshRoles() async {
        guard !isLoadingRoles else { return }
        isLoadingRoles = true
        rolesErrorMessage = nil

        do {
            let fetchedRoles = try await chatService.fetchRoles()
            roles = fetchedRoles

            if let selectedRoleCode, fetchedRoles.contains(where: { $0.roleCode == selectedRoleCode }) == false {
                self.selectedRoleCode = fetchedRoles.first?.roleCode
                storage.saveSelectedRoleCode(self.selectedRoleCode)
            }

            if self.selectedRoleCode == nil {
                self.selectedRoleCode = fetchedRoles.first?.roleCode
                storage.saveSelectedRoleCode(self.selectedRoleCode)
            }

            if shouldRefreshRolesAffectCurrentScreen {
                updateInitialScreen()
            }
        } catch {
            rolesErrorMessage = error.localizedDescription
        }

        isLoadingRoles = false
    }

    func updateSelectedRole(roleCode: String) {
        selectedRoleCode = roleCode
        storage.saveSelectedRoleCode(roleCode)
    }

    func beginPrimaryFlow() {
        hasCompletedSelection = true
        storage.saveHasCompletedSelection(true)
        screen = loginSession == nil ? .login : .home
    }

    func finishLogin(with session: LoginSession) {
        loginSession = session
        storage.saveSession(session)
        screen = .home
    }

    func openChat(roleCode: String) {
        updateSelectedRole(roleCode: roleCode)
        screen = .chat(roleCode: roleCode)
    }

    func showHome() {
        screen = .home
    }

    func showSettings() {
        screen = .settings
    }

    func showLogin() {
        screen = .login
    }

    func reselectRole() {
        hasCompletedSelection = false
        storage.saveHasCompletedSelection(false)
        screen = .onboarding
    }

    func handleUnauthorized() {
        logout()
    }

    func logout() {
        loginSession = nil
        storage.saveSession(nil)
        updateInitialScreen()
    }

    func clearAccountDataAfterDeletion() {
        loginSession = nil
        selectedRoleCode = nil
        hasCompletedSelection = false
        storage.clearAccountState()
        screen = .onboarding
    }

    func role(for roleCode: String?) -> Role? {
        guard let roleCode else { return nil }
        return roles.first(where: { $0.roleCode == roleCode })
    }

    var selectedRole: Role? {
        role(for: selectedRoleCode)
    }

    var accessToken: String? {
        loginSession?.accessToken
    }

    var isAuthenticated: Bool {
        loginSession != nil
    }

    private func updateInitialScreen() {
        if loginSession != nil, hasCompletedSelection, selectedRoleCode != nil {
            screen = .home
        } else {
            screen = .onboarding
        }
    }

    private var shouldRefreshRolesAffectCurrentScreen: Bool {
        switch screen {
        case .settings, .chat:
            return false
        case .onboarding, .login, .home:
            return true
        }
    }
}
