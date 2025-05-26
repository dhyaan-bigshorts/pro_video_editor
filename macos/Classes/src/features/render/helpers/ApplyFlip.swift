import CoreGraphics

func applyFlip(
    _ transform: inout CGAffineTransform,
    flipX: Bool,
    flipY: Bool
) {
    if !flipX && !flipY { return }

    let scaleX: CGFloat = flipX ? -1 : 1
    let scaleY: CGFloat = flipY ? -1 : 1

    print("[\(Tags.render)] Applying flip: flipX=\(flipX), flipY=\(flipY)")

    transform = transform.scaledBy(x: scaleX, y: scaleY)
}
