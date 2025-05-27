import CoreGraphics

public func applyRotation(
    _ transform: inout CGAffineTransform,
    rotateTurns: Int?,
    size: CGSize
) -> CGSize {
    let turns = (rotateTurns ?? 0) % 4
    guard turns != 0 else { return size }

    let degrees = turns * 90
    let radians = CGFloat(Double(degrees) * .pi / 180)

    print("[\(Tags.render)] Applying rotation: \(degrees) degrees")

    // Apply rotation
    var rotated = transform.rotated(by: radians)

    // Calculate the bounding box of the rotated video
    let originalRect = CGRect(origin: .zero, size: size)
    let rotatedRect = originalRect.applying(rotated)

    let translateX = -rotatedRect.origin.x.rounded(.toNearestOrEven)
    let translateY = -rotatedRect.origin.y.rounded(.toNearestOrEven)

    rotated = rotated.concatenating(CGAffineTransform(translationX: translateX, y: translateY))
    transform = rotated

    // Return the new size (absolute, positive values)
    let newWidth = Int(abs(rotatedRect.width).rounded())
    let newHeight = Int(abs(rotatedRect.height).rounded())

    return CGSize(width: newWidth, height: newHeight)
}
