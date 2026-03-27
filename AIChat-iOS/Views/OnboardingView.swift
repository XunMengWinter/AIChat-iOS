//
//  OnboardingView.swift
//  AIChat-iOS
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @State private var selectedRoleCode = ""

    var body: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            if sessionStore.isLoadingRoles && sessionStore.roles.isEmpty {
                ProgressScreen(message: "正在加载角色…")
            } else if let errorMessage = sessionStore.rolesErrorMessage, sessionStore.roles.isEmpty {
                ErrorScreen(message: errorMessage) {
                    Task { await sessionStore.refreshRoles() }
                }
            } else {
                content
            }
        }
        .task(id: sessionStore.roles.map(\.roleCode).joined(separator: ",")) {
            if selectedRoleCode.isEmpty {
                selectedRoleCode = sessionStore.selectedRoleCode ?? sessionStore.roles.first?.roleCode ?? ""
            }
        }
        .onChange(of: selectedRoleCode) { _, newValue in
            guard !newValue.isEmpty else { return }
            sessionStore.updateSelectedRole(roleCode: newValue)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            carousel
            pagination
            Spacer(minLength: 12)
            primaryButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.purple)
                Text("欢迎来到陪伴世界")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.purple)
            }

            Text("选择你的陪伴角色")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("每位角色都有不同的性格与陪伴方式")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }

    private var carousel: some View {
        TabView(selection: $selectedRoleCode) {
            ForEach(sessionStore.roles) { role in
                OnboardingRoleCard(role: role)
                    .padding(.horizontal, 6)
                    .tag(role.roleCode)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 520)
    }

    private var pagination: some View {
        HStack(spacing: 8) {
            ForEach(sessionStore.roles) { role in
                Capsule()
                    .fill(role.roleCode == selectedRoleCode ? AnyShapeStyle(AppTheme.actionGradient) : AnyShapeStyle(Color.white.opacity(0.65)))
                    .frame(width: role.roleCode == selectedRoleCode ? 28 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: selectedRoleCode)
            }
        }
        .padding(.top, 22)
    }

    private var primaryButton: some View {
        Button {
            sessionStore.beginPrimaryFlow()
        } label: {
            Text("开始聊天")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.actionGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.purple.opacity(0.25), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(sessionStore.selectedRole == nil)
        .padding(.top, 24)
    }
}

private struct OnboardingRoleCard: View {
    let role: Role

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.white.opacity(0.88))
                .shadow(color: AppTheme.cardShadow, radius: 28, x: 0, y: 18)

            ZStack {
                RemoteImageView(url: role.backgroundURLValue)
                    .scaledToFill()
                    .opacity(0.28)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

                LinearGradient(
                    colors: [
                        .white.opacity(0.72),
                        .white.opacity(0.40),
                        .white.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }

            VStack(spacing: 24) {
                Spacer(minLength: 28)

                RemoteImageView(url: role.avatarURLValue)
                    .scaledToFill()
                    .frame(width: 170, height: 170)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.95), lineWidth: 5)
                    }
                    .shadow(color: .black.opacity(0.14), radius: 20, x: 0, y: 12)

                VStack(spacing: 8) {
                    Text(role.nickname)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(role.intro)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                Spacer()

                Text(role.openingMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }
}

struct ProgressScreen: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorScreen: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.purple)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("重新加载", action: retry)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(AppTheme.actionGradient)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
