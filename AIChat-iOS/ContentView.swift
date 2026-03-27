//
//  ContentView.swift
//  AIChat-iOS
//
//  Created by ice on 27/3/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        Group {
            switch sessionStore.screen {
            case .onboarding:
                OnboardingView()
            case .login:
                LoginView()
            case .home:
                NavigationStack {
                    HomeView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
            case .settings:
                SettingsView()
            case .chat(let roleCode):
                if let role = sessionStore.role(for: roleCode) {
                    ChatView(role: role)
                } else if sessionStore.isLoadingRoles {
                    ProgressScreen(message: "正在加载角色…")
                } else if let errorMessage = sessionStore.rolesErrorMessage {
                    ErrorScreen(message: errorMessage) {
                        Task { await sessionStore.refreshRoles() }
                    }
                } else {
                    ProgressScreen(message: "正在刷新角色信息…")
                        .task {
                            await sessionStore.refreshRoles()
                        }
                }
            }
        }
        .task {
            await sessionStore.bootstrap()
        }
        .animation(.easeInOut(duration: 0.22), value: sessionStore.screen)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSessionStore())
}
