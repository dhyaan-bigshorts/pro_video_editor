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

    // Rotation-aware crop origin
     if rotation == 90 || rotation == 270 {
         swap(&x, &y)
     }
     if rotation == 90 || rotation == 180 {
         y = videoHeight - height - y
     }
     if rotation == 270 || rotation == 180 {
         x = videoWidth - width - x
     }

    // Flip-aware crop origin
    if flipX {
        x = videoWidth - width - x
    }
    if flipY {
        y = videoHeight - height - y
    }
    /*
    WORKING
    Applying rotatedSize: width=720.0 height=1280.0
    Applying crop: x=0.0 y=0.0 width=720.0 height=1280.0
    Applying cropTranslate: x=-0.0 y=-0.0
    
    BROKEN
    Applying rotatedSize: width=720.0 height=1280.0
    Applying crop: x=0.0 y=0.0 width=1280.0 height=720.0
    Applying cropTranslate: x=-0.0 y=-0.0
     */
    let cropRect = CGRect(x: x, y: y, width: width, height: height)

    print("[\(Tags.render)] Applying rotatedSize: width=\(videoWidth) height=\(videoHeight)")
    print("[\(Tags.render)] Applying crop: x=\(x) y=\(y) width=\(width) height=\(height)")
    print(
        "[\(Tags.render)] Applying cropTranslate: x=\(cropRect.origin.x * (flipX ? 1 : -1)) y=\(cropRect.origin.y * (flipY ? 1 : -1))"
    )
    // Crop by translating the transform
    transform = transform.translatedBy(
        x: -cropRect.origin.x,// * (flipX ? 1 : -1),
        y: -cropRect.origin.y,// * (flipY ? 1 : -1),
    )

    return cropRect.size
}
