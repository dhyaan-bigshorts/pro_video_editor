import AVFoundation

func applyBlur(
    to composition: AVMutableVideoComposition,
    sigma: Double?
) {
    guard let sigma = sigma, sigma > 0 else { return }

    print("[\(Tags.render)] Applying blur: sigma = \(sigma)")

    VideoCompositor.blurSigma = sigma * 2.5
}


