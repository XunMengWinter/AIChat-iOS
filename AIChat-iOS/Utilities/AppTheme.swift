//
//  AppTheme.swift
//  AIChat-iOS
//

import SwiftUI

enum AppTheme {
    static let screenGradient = LinearGradient(
        colors: [
            Color(hex: 0xF8F1FF),
            Color(hex: 0xFFF3F8),
            Color(hex: 0xF3F7FF)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let actionGradient = LinearGradient(
        colors: [
            Color(hex: 0x9A67FF),
            Color(hex: 0xFF7BB5)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let purple = Color(hex: 0x8C5CFF)
    static let pink = Color(hex: 0xF78DBA)
    static let textPrimary = Color(hex: 0x1F2430)
    static let textSecondary = Color(hex: 0x6D7485)
    static let cardShadow = Color.black.opacity(0.08)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
