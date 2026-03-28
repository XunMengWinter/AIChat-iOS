//
//  OnboardingView.swift
//  AIChat-iOS
//

import SwiftUI
import NukeUI

struct OnboardingView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @State private var centeredVirtualIndex: Int?

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
        .task(id: roleCodesSignature) {
            syncCarouselSelection()
        }
        .onChange(of: centeredVirtualIndex) { _, newValue in
            guard let newValue, sessionStore.roles.isEmpty == false else { return }

            let normalizedIndex = normalizedRoleIndex(for: newValue)
            let roleCode = sessionStore.roles[normalizedIndex].roleCode
            if sessionStore.selectedRoleCode != roleCode {
                sessionStore.updateSelectedRole(roleCode: roleCode)
            }
            recenterCarouselIfNeeded(from: newValue, normalizedIndex: normalizedIndex)
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
        GeometryReader { geometry in
            let cardWidth = min(geometry.size.width - 90, 340)
            let horizontalInset = max((geometry.size.width - cardWidth) / 2, 0)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 18) {
                    ForEach(virtualRoleIndices, id: \.self) { virtualIndex in
                        let role = role(forVirtualIndex: virtualIndex)
                        let isSelected = virtualIndex == centeredVirtualIndex

                        OnboardingRoleCard(role: role, isSelected: isSelected)
                            .frame(width: cardWidth, height: 500)
                            .scaleEffect(isSelected ? 1 : 0.9)
                            .id(virtualIndex)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredVirtualIndex)
            .scrollClipDisabled()
        }
        .frame(height: 520)
    }

    private var pagination: some View {
        HStack(spacing: 8) {
            ForEach(sessionStore.roles) { role in
                Capsule()
                    .fill(role.roleCode == currentRoleCode ? AnyShapeStyle(AppTheme.actionGradient) : AnyShapeStyle(Color.white.opacity(0.65)))
                    .frame(width: role.roleCode == currentRoleCode ? 28 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentRoleCode)
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
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var roleCodesSignature: String {
        sessionStore.roles.map(\.roleCode).joined(separator: ",")
    }

    private var currentRoleCode: String? {
        guard sessionStore.roles.isEmpty == false else { return nil }

        if let centeredVirtualIndex {
            return role(forVirtualIndex: centeredVirtualIndex).roleCode
        }
        return sessionStore.selectedRoleCode ?? sessionStore.roles.first?.roleCode
    }

    private var isLoopingEnabled: Bool {
        sessionStore.roles.count > 1
    }

    private var virtualRoleIndices: [Int] {
        guard sessionStore.roles.isEmpty == false else { return [] }
        let multiplier = isLoopingEnabled ? 3 : 1
        return Array(0..<(sessionStore.roles.count * multiplier))
    }

    private func syncCarouselSelection() {
        guard sessionStore.roles.isEmpty == false else {
            centeredVirtualIndex = nil
            return
        }

        let fallbackRoleCode = sessionStore.selectedRoleCode ?? sessionStore.roles.first?.roleCode
        let realIndex = sessionStore.roles.firstIndex(where: { $0.roleCode == fallbackRoleCode }) ?? 0
        let targetIndex = isLoopingEnabled ? realIndex + sessionStore.roles.count : realIndex

        if centeredVirtualIndex != targetIndex {
            centeredVirtualIndex = targetIndex
        }

        let roleCode = sessionStore.roles[realIndex].roleCode
        if sessionStore.selectedRoleCode != roleCode {
            sessionStore.updateSelectedRole(roleCode: roleCode)
        }
    }

    private func normalizedRoleIndex(for virtualIndex: Int) -> Int {
        let roleCount = sessionStore.roles.count
        guard roleCount > 0 else { return 0 }

        let remainder = virtualIndex % roleCount
        return remainder >= 0 ? remainder : remainder + roleCount
    }

    private func role(forVirtualIndex virtualIndex: Int) -> Role {
        sessionStore.roles[normalizedRoleIndex(for: virtualIndex)]
    }

    private func recenterCarouselIfNeeded(from virtualIndex: Int, normalizedIndex: Int) {
        guard isLoopingEnabled else { return }

        let roleCount = sessionStore.roles.count
        let lowerBound = roleCount
        let upperBound = roleCount * 2

        guard virtualIndex < lowerBound || virtualIndex >= upperBound else { return }

        let targetIndex = roleCount + normalizedIndex
        guard targetIndex != virtualIndex else { return }

        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                centeredVirtualIndex = targetIndex
            }
        }
    }
}

private struct OnboardingRoleCard: View {
    let role: Role
    let isSelected: Bool

    var body: some View {
        ZStack {
                LazyImage(url: URL(string: role.backgroundURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                        .opacity(0.28)
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    } else {
                        Color.white.opacity(0.8)
                    }
                }
                .frame(width: 320, height: 480)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(.white, lineWidth: 2)
            }


            VStack(spacing: 24) {
                Spacer(minLength: 28)

                RemoteImageView(url: role.avatarURLValue)
                    .scaledToFill()
                    .frame(width: 170, height: 170)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.95), lineWidth: isSelected ? 5 : 4)
                    }
                    .shadow(color: .black.opacity(isSelected ? 0.16 : 0.10), radius: isSelected ? 20 : 14, x: 0, y: isSelected ? 12 : 8)

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
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
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
