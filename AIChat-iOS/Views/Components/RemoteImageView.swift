//
//  RemoteImageView.swift
//  AIChat-iOS
//

import NukeUI
import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
                    .overlay {
                        if state.error == nil {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [
                AppTheme.purple.opacity(0.7),
                AppTheme.pink.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
