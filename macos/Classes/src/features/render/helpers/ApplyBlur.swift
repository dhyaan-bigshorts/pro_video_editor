import AVFoundation

func applyBlur(
    config: inout VideoCompositorConfig,
    sigma: Double?
) {
    config.blurSigma = (sigma ?? 0) * 2.5

    if sigma == nil { return }

    print("[\(Tags.render)] Applying blur: sigma=\(sigma!)")
}
