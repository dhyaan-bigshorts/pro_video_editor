import AVFoundation
import CoreGraphics

func applyCrop(
    config: inout VideoCompositorConfig,
    naturalSize: CGSize,
    rotateTurns: Int?,
    cropX: Int?,
    cropY: Int?,
    cropWidth: Int?,
    cropHeight: Int?
) -> CGSize {
    let x = CGFloat(cropX ?? 0)
    let y = CGFloat(cropY ?? 0)
    let width = CGFloat(cropWidth ?? Int(naturalSize.width) - Int(x))
    let height = CGFloat(cropHeight ?? Int(naturalSize.height) - Int(y))

    config.cropX = x
    config.cropY = y
    config.cropWidth = width
    config.cropHeight = height

    if cropX != 0 || cropY != 0 || cropWidth != nil || cropHeight != nil {
        print(
            "[\(Tags.render)] Applying crop: x=\(Int(x)) y=\(Int(y)) width=\(Int(width)) height=\(Int(height))"
        )
    }

    let cropRect = CGRect(x: x, y: y, width: width, height: height)

    let turns = 4 - (rotateTurns ?? 0) % 4

    let isPortraitRotation = turns % 2 == 1
    return isPortraitRotation
        ? CGSize(width: cropRect.size.height, height: cropRect.size.width)
        : cropRect.size
}
