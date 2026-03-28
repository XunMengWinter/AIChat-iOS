//
//  ChatView.swift
//  AIChat-iOS
//

import Combine
import PhotosUI
import SwiftUI
import NukeUI

struct ChatView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?

    let role: Role
    private let pageHorizontalPadding: CGFloat = 16

    private let quickTopics = [
        "今天有点累",
        "安慰我一下",
        "陪我聊聊天",
        "听我说说话"
    ]

    var body: some View {
        ZStack {
            Color.clear.overlay(content: {
                LazyImage(url: URL(string: role.backgroundURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        Color.white.opacity(0.8)
                    }
                }
            })
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                errorBanner
                transcript
                if isInputFocused == false {
                    quickTopicStrip
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                inputBar
            }

        }
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .task(id: role.roleCode) {
            await viewModel.loadHistory(
                for: role,
                accessToken: sessionStore.accessToken,
                onUnauthorized: sessionStore.handleUnauthorized
            )
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await loadSelectedImage(from: newValue)
                selectedPhotoItem = nil
            }
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
        let isConversationActionDisabled = viewModel.isSending || viewModel.isClearing

        return HStack(spacing: 12) {
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
            .disabled(isConversationActionDisabled)
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
            .scrollDismissesKeyboard(.interactively)
            .onReceive(
                viewModel.$messages
                    .map(\.count)
                    .removeDuplicates()
            ) { _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onReceive(
                viewModel.$messages
                    .map { $0.last?.content ?? "" }
                    .removeDuplicates()
                    .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            ) { _ in
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var quickTopicStrip: some View {
        let isConversationActionDisabled = viewModel.isSending || viewModel.isClearing

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickTopics, id: \.self) { topic in
                    Button(topic) {
                        viewModel.useQuickTopic(topic)
                        isInputFocused = true
                    }
                    .disabled(isConversationActionDisabled)
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
        let isPreparingImage = viewModel.isPreparingImage
        let isSending = viewModel.isSending
        let isClearing = viewModel.isClearing
        let canSendMessage = viewModel.canSendMessage()

        return VStack(spacing: 10) {
            if let draftImage = viewModel.draftImage {
                draftImagePreviewCard(draftImage)
            }

            HStack(alignment: .bottom, spacing: 10) {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Circle()
                        .fill(.white.opacity(0.92))
                        .frame(width: 48, height: 48)
                        .overlay {
                            if isPreparingImage {
                                ProgressView()
                                    .tint(AppTheme.purple)
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppTheme.purple)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(isPreparingImage || isSending || isClearing)

                TextField("说点什么…", text: $viewModel.draftText, axis: .vertical)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .disabled(isClearing)
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
                            canSendMessage && !isPreparingImage
                            ? AnyShapeStyle(AppTheme.actionGradient)
                            : AnyShapeStyle(Color.gray.opacity(0.45))
                        )
                        .frame(width: 48, height: 48)
                        .overlay {
                            if isSending {
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
                .disabled(!canSendMessage || isPreparingImage || isClearing)
            }
        }
        .padding(.horizontal, pageHorizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private func draftImagePreviewCard(_ image: DraftChatImage) -> some View {
        HStack(spacing: 12) {
            if let uiImage = UIImage(data: image.previewImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                placeholderThumbnail
                    .frame(width: 72, height: 72)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("已添加图片")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(Int(image.pixelSize.width)) × \(Int(image.pixelSize.height)) · JPEG")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                viewModel.clearDraftImage()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func sendCurrentDraft() async {
        guard viewModel.canSendMessage(), viewModel.isClearing == false else { return }
        isInputFocused = false
        await viewModel.sendMessage(
            for: role,
            accessToken: sessionStore.accessToken,
            onUnauthorized: sessionStore.handleUnauthorized
        )
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                viewModel.setImageSelectionError("无法读取图片，请重新选择。")
                return
            }
            await viewModel.prepareDraftImage(from: imageData)
        } catch {
            viewModel.setImageSelectionError("图片选择失败，请重试。")
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastID = viewModel.messages.last?.id else { return }
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            } else {
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
                VStack(alignment: message.sender == .assistant ? .leading : .trailing, spacing: 8) {
                    if message.hasImage {
                        messageImageContent
                    }

                    if !message.content.isEmpty || !message.hasImage {
                        Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(message.sender == .user ? .white : AppTheme.textPrimary)
                            .multilineTextAlignment(message.sender == .user ? .trailing : .leading)
                    }
                }
                    .padding(.horizontal, message.hasImage ? 8 : 16)
                    .padding(.vertical, message.hasImage ? 8 : 12)
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
    private var messageImageContent: some View {
        if
            let imageData = message.imagePreviewData,
            let uiImage = UIImage(data: imageData)
        {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 220, maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            placeholderThumbnail
                .frame(width: 184, height: 140)
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

private var placeholderThumbnail: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color.white.opacity(0.22))
        .overlay {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .semibold))
                Text("图片消息")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.92))
        }
}
