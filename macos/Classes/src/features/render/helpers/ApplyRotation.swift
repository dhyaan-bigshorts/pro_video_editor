import CoreGraphics

public func applyRotation(_ transform: inout CGAffineTransform, rotateTurns: Int?) {
    let degrees = (rotateTurns ?? 0) * 90
    let radians = CGFloat(Double(degrees) * .pi / 180)

    if degrees % 360 != 0 {
        print("[\(Tags.render)] Applying rotation: \(degrees) degrees")
        transform = transform.rotated(by: radians)
    }
}
