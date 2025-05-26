import AVFoundation
import CoreGraphics

public func applyCrop(
    _ transform: inout CGAffineTransform,
    videoTrack: AVAssetTrack,
    cropX: Int?,
    cropY: Int?,
    cropWidth: Int?,
    cropHeight: Int?
) async {
    guard cropX != nil || cropY != nil || cropWidth != nil || cropHeight != nil else {
        return
    }

    let originalSize: CGSize
    if #available(macOS 13.0, *) {
        do {
            originalSize = try await videoTrack.load(.naturalSize)
        } catch {
            print("[\(Tags.render)] Failed to load naturalSize: \(error.localizedDescription)")
            return
        }
    } else {
        originalSize = videoTrack.naturalSize
    }

    let cropXFloat = CGFloat(cropX ?? 0)
    let cropYFloat = CGFloat(cropY ?? 0)

    let cropWidthFloat: CGFloat
    if let cropWidth = cropWidth {
        cropWidthFloat = CGFloat(cropWidth)
    } else {
        cropWidthFloat = originalSize.width - cropXFloat
    }

    let cropHeightFloat: CGFloat
    if let cropHeight = cropHeight {
        cropHeightFloat = CGFloat(cropHeight)
    } else {
        cropHeightFloat = originalSize.height - cropYFloat
    }

    guard cropWidthFloat > 0, cropHeightFloat > 0 else {
        print("[\(Tags.render)] Skipping crop: invalid crop dimensions.")
        return
    }

    let tx = -cropXFloat
    let ty = -cropYFloat

    print("[\(Tags.render)] Applying crop: x=\(cropXFloat), y=\(cropYFloat), width=\(cropWidthFloat), height=\(cropHeightFloat)")

    transform = transform.translatedBy(x: tx, y: ty)
}
