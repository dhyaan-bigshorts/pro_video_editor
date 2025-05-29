import AVFoundation
import CoreGraphics

public func applyCrop(
    naturalSize: CGSize,
    rotateTurns: Int?,
    cropX: Int?,
    cropY: Int?,
    cropWidth: Int?,
    cropHeight: Int?,
) -> CGSize {
    let x = CGFloat(cropX ?? 0)
    let y = CGFloat(cropY ?? 0)
    let width = CGFloat(cropWidth ?? Int(naturalSize.width) - Int(x))
    let height = CGFloat(cropHeight ?? Int(naturalSize.height) - Int(y))

    VideoCompositor.cropX = x
    VideoCompositor.cropY = y
    VideoCompositor.cropWidth = width
    VideoCompositor.cropHeight = height

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

    /*
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
    */
}
