import CoreGraphics

func applyFlip(
    _ transform: inout CGAffineTransform,
    flipX: Bool,
    flipY: Bool,
    size: CGSize
) {
    if !flipX && !flipY { return }

    let scaleX: CGFloat = flipX ? -1 : 1
    let scaleY: CGFloat = flipY ? -1 : 1

    print("[\(Tags.render)] Applying flip: flipX=\(flipX), flipY=\(flipY)")

    // Translate to center → scale (flip) → translate back
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    let flipTransform = CGAffineTransform(translationX: center.x, y: center.y)
        .scaledBy(x: scaleX, y: scaleY)
        .translatedBy(x: -center.x, y: -center.y)

    transform = transform.concatenating(flipTransform)
}
