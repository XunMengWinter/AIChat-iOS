//
//  ChatImageProcessor.swift
//  AIChat-iOS
//

import CoreGraphics
import Foundation
import UIKit

enum ChatImageProcessor {
    nonisolated private static let maxLongEdge: CGFloat = 1440

    nonisolated static func processImageData(_ data: Data) throws -> DraftChatImage {
        guard let image = UIImage(data: data) else {
            throw APIError.imageProcessingFailed("图片读取失败，请重新选择。")
        }

        let originalPixelSize = pixelSize(for: image)
        let resizedImage = resizeIfNeeded(image, pixelSize: originalPixelSize)

        guard let uploadImageData = resizedImage.jpegData(compressionQuality: 0.82) else {
            throw APIError.imageProcessingFailed("图片压缩失败，请重新选择。")
        }
        guard let previewImageData = resizedImage.jpegData(compressionQuality: 0.68) else {
            throw APIError.imageProcessingFailed("图片预览生成失败，请重新选择。")
        }

        let finalPixelSize = pixelSize(for: resizedImage)

        return DraftChatImage(
            previewImageData: previewImageData,
            uploadImageData: uploadImageData,
            imageBase64: uploadImageData.base64EncodedString(),
            mimeType: "image/jpeg",
            pixelSize: finalPixelSize
        )
    }

    nonisolated private static func pixelSize(for image: UIImage) -> CGSize {
        if let cgImage = image.cgImage {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }
        return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }

    nonisolated private static func resizeIfNeeded(_ image: UIImage, pixelSize: CGSize) -> UIImage {
        let longEdge = max(pixelSize.width, pixelSize.height)
        guard longEdge > maxLongEdge, longEdge > 0 else {
            return image
        }

        let scaleRatio = maxLongEdge / longEdge
        let targetSize = CGSize(
            width: floor(pixelSize.width * scaleRatio),
            height: floor(pixelSize.height * scaleRatio)
        )

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        rendererFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
