//
//  HomeView.swift
//  AIChat-iOS
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var viewModel = HomeViewModel()

    private let recentChatsAnchor = "recentChatsAnchor"
    private let pageHorizontalPadding: CGFloat = 16

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        recommendedCard
                        allRolesSection
                        quickActions { proxy.scrollTo(recentChatsAnchor, anchor: .top) }
                        recentChatsSection
                            .id(recentChatsAnchor)
                    }
                    .padding(.horizontal, pageHorizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button {
                    print("点击设置按钮")
                    sessionStore.showSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.purple)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("设置")
            })
        })
        .task(id: refreshKey) {
            await viewModel.refreshRecentChats(
                roles: sessionStore.roles,
                accessToken: sessionStore.accessToken,
                onUnauthorized: sessionStore.handleUnauthorized
            )
        }
    }

    private var refreshKey: String {
        let roleCodes = sessionStore.roles.map(\.roleCode).joined(separator: ",")
        return "\(sessionStore.accessToken ?? "none")::\(roleCodes)"
    }

    private var backgroundLayer: some View {
        ZStack {
            if let role = sessionStore.selectedRole {
                RemoteImageView(url: role.backgroundURLValue)
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                AppTheme.screenGradient
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    .white.opacity(0.92),
                    .white.opacity(0.84),
                    .white.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.purple)
                    Text(greeting)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text("今天想和谁聊聊天？")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 12)
        }
    }

    @ViewBuilder
    private var recommendedCard: some View {
        if let role = sessionStore.selectedRole {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    RemoteImageView(url: role.avatarURLValue)
                        .scaledToFill()
                        .frame(width: 86, height: 86)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(role.nickname)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("推荐")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.purple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.9))
                                .clipShape(Capsule())
                        }

                        Text(role.intro)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)

                        Label(role.openingMessage, systemImage: "message")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                Button {
                    sessionStore.openChat(roleCode: role.roleCode)
                } label: {
                    Text("立即聊天")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppTheme.actionGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(
                ZStack {
                    RemoteImageView(url: role.backgroundURLValue)
                        .scaledToFill()
                        .opacity(0.18)

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.78),
                            Color(hex: 0xF6EEFF).opacity(0.84),
                            Color(hex: 0xFBEFF7).opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 18, x: 0, y: 12)
        }
    }

    private var allRolesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所有角色")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(sessionStore.roles) { role in
                        Button {
                            sessionStore.openChat(roleCode: role.roleCode)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                RemoteImageView(url: role.avatarURLValue)
                                    .scaledToFill()
                                    .frame(width: 132, height: 132)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                                Text(role.nickname)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(role.intro)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .frame(width: 148, alignment: .leading)
                            .padding(12)
                            .background(.white.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, pageHorizontalPadding)
            }
            .padding(.horizontal, -pageHorizontalPadding)
        }
    }

    private func quickActions(scrollToHistory: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            quickActionButton(
                title: "继续聊天",
                systemImage: "message.fill",
                colors: [Color(hex: 0xEDE1FF), Color(hex: 0xFDE6F3)]
            ) {
                if let roleCode = viewModel.recentChats.first?.role.roleCode ?? sessionStore.selectedRoleCode {
                    sessionStore.openChat(roleCode: roleCode)
                }
            }

            quickActionButton(
                title: "聊天记录",
                systemImage: "clock.fill",
                colors: [Color(hex: 0xE5F1FF), Color(hex: 0xF1ECFF)]
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    scrollToHistory()
                }
            }

            quickActionButton(
                title: "重新选择",
                systemImage: "arrow.trianglehead.clockwise",
                colors: [Color(hex: 0xFFE8F1), Color(hex: 0xF7ECFF)]
            ) {
                sessionStore.reselectRole()
            }
        }
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        colors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.purple)
                    }

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近聊天")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.isLoadingRecentChats {
                ProgressScreen(message: "正在同步最近聊天…")
                    .frame(height: 180)
            } else if let errorMessage = viewModel.recentChatsErrorMessage {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("重试加载") {
                        Task {
                            await viewModel.refreshRecentChats(
                                roles: sessionStore.roles,
                                accessToken: sessionStore.accessToken,
                                onUnauthorized: sessionStore.handleUnauthorized
                            )
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else if viewModel.recentChats.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.purple)
                    Text("还没有真实聊天记录")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("去和喜欢的角色聊上几句，这里就会显示最近会话。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentChats) { summary in
                        Button {
                            sessionStore.openChat(roleCode: summary.role.roleCode)
                        } label: {
                            HStack(spacing: 12) {
                                RemoteImageView(url: summary.role.avatarURLValue)
                                    .scaledToFill()
                                    .frame(width: 54, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(summary.role.nickname)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Spacer()
                                        Text(AppDateFormatter.recentChatLabel(for: summary.lastMessage.createdAt))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Text(summary.lastMessage.content)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(1)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(14)
                            .background(.white.opacity(0.84))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "早上好"
        case 12..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }
}
