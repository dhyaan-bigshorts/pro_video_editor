import AVFoundation

func applyBlur(
    sigma: Double?
) {
    VideoCompositor.blurSigma = (sigma ?? 0) * 2.5

    if sigma == nil { return }

    print("[\(Tags.render)] Applying blur: sigma=\(sigma!)")
}
