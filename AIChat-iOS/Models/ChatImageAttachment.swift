//
//  ChatImageAttachment.swift
//  AIChat-iOS
//

import CoreGraphics
import Foundation

struct DraftChatImage: Sendable {
    let previewImageData: Data
    let uploadImageData: Data
    let imageBase64: String
    let mimeType: String
    let pixelSize: CGSize
}
