//
//  SettingsView.swift
//  AIChat-iOS
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @State private var isShowingLogoutConfirmation = false

    private let pageHorizontalPadding: CGFloat = 32

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    accountCard
                    logoutSection
                }
                .padding(.horizontal, pageHorizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .confirmationDialog(
            "确认退出当前账号？",
            isPresented: $isShowingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("退出登录", role: .destructive) {
                sessionStore.logout()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("退出后会回到登录页，但会保留你已选择的陪伴角色。")
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .white.opacity(0.74),
                    .white.opacity(0.58),
                    .white.opacity(0.80)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                sessionStore.showHome()
            } label: {
                Circle()
                    .fill(.white.opacity(0.90))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("设置")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("管理账号与登录状态")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF2E4FF), Color(hex: 0xFFE7F3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.purple)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(maskedPhoneNumber)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(sessionStore.loginSession?.isTestAccount == true ? "当前为测试账号" : "当前账号已登录")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 12) {
                infoRow(
                    title: "国家区号",
                    value: sessionStore.loginSession?.user.countryCode ?? "+86",
                    systemImage: "globe.asia.australia.fill",
                    tint: Color(hex: 0x84A9FF)
                )

                if let role = sessionStore.selectedRole {
                    selectedRoleRow(role)
                }
            }
        }
        .padding(22)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.92),
                        Color(hex: 0xF7EEFF).opacity(0.88),
                        Color(hex: 0xFFF1F8).opacity(0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 180, height: 180)
                    .offset(x: 112, y: -88)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 20, x: 0, y: 12)
    }

    private var logoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isShowingLogoutConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("退出登录")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFF7B96), Color(hex: 0xFF9F7B)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: 0xFF7B96, alpha: 0.24), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)

            Text("退出后会回到登录页，不会清除你已选中的角色和聊天入口。")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private func infoRow(
        title: String,
        value: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.16))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func selectedRoleRow(_ role: Role) -> some View {
        HStack(spacing: 12) {
            RemoteImageView(url: role.avatarURLValue)
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("当前陪伴角色")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(role.nickname)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var maskedPhoneNumber: String {
        guard let phoneNumber = sessionStore.loginSession?.user.phoneNumber, phoneNumber.count >= 7 else {
            return "未获取手机号"
        }

        let prefix = phoneNumber.prefix(3)
        let suffix = phoneNumber.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}
