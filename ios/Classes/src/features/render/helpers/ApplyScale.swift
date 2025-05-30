import CoreGraphics

func applyScale(
    config: inout VideoCompositorConfig,
    scaleX: Float?,
    scaleY: Float?
) {
    let x = CGFloat(scaleX ?? 1.0)
    let y = CGFloat(scaleY ?? 1.0)

    config.scaleX = x
    config.scaleY = y

    if x != 1.0 || y != 1.0 {
        print("[\(Tags.render)] Applying scale: scaleX=\(x), scaleY=\(y)")
    }
}
