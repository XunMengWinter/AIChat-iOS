//
//  ChatView.swift
//  AIChat-iOS
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    let role: Role
    private let pageHorizontalPadding: CGFloat = 32

    private let quickTopics = [
        "今天有点累",
        "安慰我一下",
        "陪我聊聊天",
        "听我说说话"
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar
                errorBanner
                transcript
                quickTopicStrip
                inputBar
            }
        }
        .task(id: role.roleCode) {
            await viewModel.loadHistory(
                for: role,
                accessToken: sessionStore.accessToken,
                onUnauthorized: sessionStore.handleUnauthorized
            )
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            RemoteImageView(url: role.backgroundURLValue)
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .white.opacity(0.10),
                    .white.opacity(0.22),
                    .white.opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                sessionStore.showHome()
            } label: {
                Circle()
                    .fill(.white.opacity(0.88))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
            }
            .buttonStyle(.plain)

            RemoteImageView(url: role.avatarURLValue)
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.92), lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(role.nickname)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(role.intro)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    Task {
                        await viewModel.clearChat(
                            for: role,
                            accessToken: sessionStore.accessToken,
                            onUnauthorized: sessionStore.handleUnauthorized
                        )
                    }
                } label: {
                    Label("清空聊天", systemImage: "trash")
                }
            } label: {
                Circle()
                    .fill(.white.opacity(0.88))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
            }
            .disabled(viewModel.isClearing)
        }
        .padding(.horizontal, pageHorizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, pageHorizontalPadding)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.92))
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                if viewModel.isLoadingHistory && viewModel.messages.isEmpty {
                    ProgressScreen(message: "正在加载聊天记录…")
                        .frame(minHeight: 280)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleRow(role: role, message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, pageHorizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.last?.content ?? "") { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var quickTopicStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickTopics, id: \.self) { topic in
                    Button(topic) {
                        viewModel.useQuickTopic(topic)
                        isInputFocused = true
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.84))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, -pageHorizontalPadding)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("说点什么…", text: $viewModel.draftText, axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    Task { await sendCurrentDraft() }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            Button {
                Task { await sendCurrentDraft() }
            } label: {
                Circle()
                    .foregroundStyle(
                        viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.45))
                        : AnyShapeStyle(AppTheme.actionGradient)
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        if viewModel.isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(18))
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSending || viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, pageHorizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private func sendCurrentDraft() async {
        await viewModel.sendMessage(
            for: role,
            accessToken: sessionStore.accessToken,
            onUnauthorized: sessionStore.handleUnauthorized
        )
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastID = viewModel.messages.last?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

private struct MessageBubbleRow: View {
    let role: Role
    let message: ChatMessageItem

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .assistant {
                RemoteImageView(url: role.avatarURLValue)
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 34)
            }

            if message.sender == .user {
                Spacer(minLength: 18)
            }

            VStack(alignment: message.sender == .assistant ? .leading : .trailing, spacing: 4) {
                Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(message.sender == .user ? .white : AppTheme.textPrimary)
                    .multilineTextAlignment(message.sender == .user ? .trailing : .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(AppDateFormatter.timeFormatter.string(from: message.createdAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(message.sender == .user ? Color.white.opacity(0.72) : AppTheme.textSecondary)
            }

            if message.sender == .assistant {
                Spacer(minLength: 18)
            }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.sender == .user {
            AppTheme.actionGradient
        } else {
            Color.white.opacity(0.90)
        }
    }
}
