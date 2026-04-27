//
//  LoginView.swift
//  AIChat-iOS
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var selectedLegalDocument: LegalDocument?

    enum Field {
        case phoneNumber
        case verifyCode
    }

    private enum LegalDocument: Identifiable {
        case userAgreement
        case privacyPolicy

        var id: String {
            switch self {
            case .userAgreement:
                return "userAgreement"
            case .privacyPolicy:
                return "privacyPolicy"
            }
        }

        var url: URL {
            switch self {
            case .userAgreement:
                return AppLegalLinks.userAgreementURL
            case .privacyPolicy:
                return AppLegalLinks.privacyPolicyURL
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    form
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $selectedLegalDocument) { document in
            SafariView(url: document.url)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.purple)
                Text("陪伴世界")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.purple)
            }

            Text("欢迎回来")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("使用手机号验证码登录")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 32)
        .padding(.bottom, 44)
        .frame(maxWidth: .infinity)
    }

    private var form: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                fieldTitle("手机号")
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text("+86")
                            .foregroundStyle(AppTheme.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    TextField("请输入手机号", text: $viewModel.phoneNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phoneNumber)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .onChange(of: viewModel.phoneNumber) { _, newValue in
                            viewModel.phoneNumber = newValue.filter(\.isNumber).prefix(11).description
                        }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldTitle("验证码")
                HStack(spacing: 12) {
                    TextField("请输入验证码", text: $viewModel.verificationCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focusedField, equals: .verifyCode)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .onChange(of: viewModel.verificationCode) { _, newValue in
                            viewModel.verificationCode = newValue.filter(\.isNumber).prefix(4).description
                        }

                    Button {
                        Task { await viewModel.sendCode() }
                    } label: {
                        Group {
                            if viewModel.isSendingCode {
                                ProgressView()
                                    .tint(AppTheme.purple)
                            } else {
                                Text(viewModel.countdown > 0 ? "\(viewModel.countdown)秒" : "获取验证码")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                        }
                        .foregroundStyle(viewModel.countdown > 0 ? Color.gray : AppTheme.purple)
                        .frame(width: 110, height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canSendCode || viewModel.isSendingCode)
                }
            }

            if let infoMessage = viewModel.infoMessage {
                statusCard(text: infoMessage, color: AppTheme.purple.opacity(0.12), textColor: AppTheme.purple)
            }

            if let errorMessage = viewModel.errorMessage {
                statusCard(text: errorMessage, color: Color.red.opacity(0.10), textColor: .red)
            }

            Button {
                Task {
                    do {
                        let session = try await viewModel.login()
                        sessionStore.finishLogin(with: session)
                    } catch {
                        if focusedField == nil {
                            focusedField = .verifyCode
                        }
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("登录")
                    }
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.actionGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.purple.opacity(0.24), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canLogin)
            .padding(.top, 4)

            legalConsent
        }
    }

    private func fieldTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 4)
    }

    private func statusCard(text: String, color: Color, textColor: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var legalConsent: some View {
        VStack(spacing: 4) {
            Text("登录即表示同意")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))

            HStack(spacing: 2) {
                Button("《用户协议》") {
                    selectedLegalDocument = .userAgreement
                }
                Text("和")
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                Button("《隐私政策》") {
                    selectedLegalDocument = .privacyPolicy
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.purple)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }
}
