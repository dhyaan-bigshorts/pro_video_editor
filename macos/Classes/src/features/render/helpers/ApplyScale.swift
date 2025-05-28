import CoreGraphics

public func applyScale(scaleX: Float?, scaleY: Float?) {
    let x = CGFloat(scaleX ?? 1.0)
    let y = CGFloat(scaleY ?? 1.0)

    VideoCompositor.scaleX = x
    VideoCompositor.scaleY = y

    if x != 1.0 || y != 1.0 {
        print("[\(Tags.render)] Applying scale: scaleX=\(x), scaleY=\(y)")
    }
}
