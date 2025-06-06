import CoreImage

struct VideoCompositorConfig {
    var blurSigma: Double = 0.0
    var overlayImage: Data? = nil

    var rotateRadians: Double = 0.0
    var rotateTurns: Int = 0
    var flipX: Bool = false
    var flipY: Bool = false

    var cropX: CGFloat = 0.0
    var cropY: CGFloat = 0.0
    var cropWidth: CGFloat? = nil
    var cropHeight: CGFloat? = nil

    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0

    var lutData: Data? = nil
    var lutSize: Int = 33

    var videoRotationDegrees: Double = 0.0
    var shouldApplyOrientationCorrection: Bool = false

    var preferredTransform: CGAffineTransform = .identity
    var originalNaturalSize: CGSize = .zero
}
