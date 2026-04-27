//
//  SettingsView.swift
//  AIChat-iOS
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isShowingLogoutConfirmation = false
    @State private var isShowingDeleteAccountConfirmation = false

    private let pageHorizontalPadding: CGFloat = 32
    private let genderOptions = ["未设置", "女", "男", "其他"]

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    accountCard
                    profileCard
                    errorBanner
                    successBanner
                    accountActionsSection
                }
                .padding(.horizontal, pageHorizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .task {
            await viewModel.loadProfileIfNeeded(accessToken: sessionStore.accessToken)
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
            Text("退出后会回到引导页，但会保留你已选择的陪伴角色。")
        }
        .confirmationDialog(
            "确认注销当前账号？",
            isPresented: $isShowingDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("注销账号", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteAccount(accessToken: sessionStore.accessToken)
                    if didDelete {
                        sessionStore.clearAccountDataAfterDeletion()
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("注销后将删除账号及相关个人数据。该操作不可撤销。")
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

                    Text("当前账号已登录")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 12) {
                infoRow(
                    title: "国家区号",
                    value: CountryDialCode.displayDialCode(for: sessionStore.loginSession?.user.countryCode),
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

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder
    private var successBanner: some View {
        if let successMessage = viewModel.successMessage {
            Text(successMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.purple)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.purple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.purple)

                Text("用户资料")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if viewModel.isLoadingProfile {
                    ProgressView()
                        .tint(AppTheme.purple)
                }
            }

            VStack(spacing: 14) {
                profileTextField(title: "昵称", placeholder: "小雨", text: $viewModel.nicknameText)
                genderPicker
                birthdayPicker
                profileTextField(title: "城市", placeholder: "杭州", text: $viewModel.cityText)
                profileTextField(title: "职业", placeholder: "学生", text: $viewModel.occupationText)
                profileMultilineTextField(title: "兴趣", placeholder: "电影，散步", text: $viewModel.interestsText)
                profileMultilineTextField(title: "回复偏好", placeholder: "温柔、不要说教", text: $viewModel.replyStyleText)
            }
            .disabled(viewModel.isLoadingProfile || viewModel.isSavingProfile)

            Button {
                Task {
                    await viewModel.saveProfile(accessToken: sessionStore.accessToken)
                }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSavingProfile {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(viewModel.isSavingProfile ? "正在保存…" : "保存资料")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.actionGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.purple.opacity(0.22), radius: 16, x: 0, y: 9)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingProfile || viewModel.isSavingProfile)
        }
        .padding(22)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 18, x: 0, y: 10)
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("性别")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Picker("性别", selection: $viewModel.selectedGender) {
                ForEach(genderOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var birthdayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("填写生日", isOn: $viewModel.isBirthdayEnabled)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .tint(AppTheme.purple)

            if viewModel.isBirthdayEnabled {
                DatePicker(
                    "生日",
                    selection: $viewModel.birthdayDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(14)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.clearMessages()
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
            .disabled(viewModel.isDeletingAccount)

            Text("退出后会回到引导页，不会清除你已选中的角色和聊天入口。")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 4)

            Button {
                viewModel.clearMessages()
                isShowingDeleteAccountConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isDeletingAccount {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(viewModel.isDeletingAccount ? "正在注销账号…" : "注销账号")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.86))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.red.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDeletingAccount)

            Text("注销账号会向服务器提交删除请求。成功后会清除本机登录态、已选角色和聊天入口。")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private func profileTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func profileMultilineTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .lineLimit(2...4)
                .padding(14)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
