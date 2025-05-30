import AVFoundation

func applyBlur(
    config: inout VideoCompositorConfig,
    sigma: Double?
) {
    config.blurSigma = (sigma ?? 0) * 2.5

    if sigma == nil || sigma == 0 { return }

    print("[\(Tags.render)] Applying blur: sigma=\(sigma!)")
}
