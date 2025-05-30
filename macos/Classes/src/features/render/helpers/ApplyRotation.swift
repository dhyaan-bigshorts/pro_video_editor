import CoreGraphics

func applyRotation(
    config: inout VideoCompositorConfig,
    rotateTurns: Int?
) {
    let turns = 4 - (rotateTurns ?? 0) % 4
    let degrees = turns * 90
    let radians = CGFloat(Double(degrees) * .pi / 180)

    config.rotateRadians = radians
    config.rotateTurns = turns

    if turns == 0 { return }
    print("[\(Tags.render)] Applying rotation: \(degrees) degrees")
}
