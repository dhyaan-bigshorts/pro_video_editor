import CoreGraphics

public func applyScale(
    _ transform: inout CGAffineTransform,
    scaleX: Float?,
    scaleY: Float?
) {
    let x = CGFloat(scaleX ?? 1.0)
    let y = CGFloat(scaleY ?? 1.0)

    if x != 1.0 || y != 1.0 {
        print("[\(Tags.render)] Applying scale: scaleX=\(x), scaleY=\(y)")
        transform = transform.scaledBy(x: x, y: y)
    }
}
