import AVFoundation
import CoreGraphics

public func applyCrop(
    _ transform: inout CGAffineTransform,
    rotatedSize: CGSize,
    cropX: Int?,
    cropY: Int?,
    cropWidth: Int?,
    cropHeight: Int?,
    rotateTurns: Int,
    flipX: Bool,
    flipY: Bool
) -> CGSize {
    let rotation = ((rotateTurns * 90) % 360 + 360) % 360
    let videoWidth = rotatedSize.width
    let videoHeight = rotatedSize.height

    var cropW = cropWidth
    var cropH = cropHeight

    if rotation == 90 || rotation == 270 {
        swap(&cropW, &cropH)
    }

    var x: CGFloat = CGFloat(cropX ?? 0)
    var y: CGFloat = CGFloat(cropY ?? 0)
    var width: CGFloat = CGFloat(cropW ?? Int(videoWidth - x))
    var height: CGFloat = CGFloat(cropH ?? Int(videoHeight - y))

    var flipOutputX = false
    var flipOutputY = false

    switch rotation {
    case 90:
        y = videoWidth - width - y
        flipOutputY.toggle()
    case 180:
        x = videoWidth - width - x
        y = videoHeight - height - y

        flipOutputX.toggle()
        flipOutputY.toggle()
    case 270:
        x = videoHeight - height - x
        flipOutputX.toggle()
    default:
        break
    }

    // Flip-aware crop origin
    if flipX {
        if rotation == 90 || rotation == 270 {
            y = videoWidth - width - y
            flipOutputY.toggle()
        } else {
            x = videoWidth - width - x
            flipOutputX.toggle()
        }
    }
    if flipY {
        if rotation == 90 || rotation == 270 {
            x = videoHeight - height - x
            flipOutputX.toggle()
        } else {
            y = videoHeight - height - y
            flipOutputY.toggle()
        }
    }

    let cropRect = CGRect(x: x, y: y, width: width, height: height)

    print(
        "[\(Tags.render)] Applying crop: x=\(x) y=\(y) width=\(width) height=\(height) rotation=\(rotation)"
    )

    // Crop by translating the transform
    transform = transform.translatedBy(
        x: cropRect.origin.x * (flipOutputX ? 1 : -1),
        y: cropRect.origin.y * (flipOutputY ? 1 : -1),
    )

    return cropRect.size
}
