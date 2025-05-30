import AVFoundation
import AppKit
import CoreImage

func applyImageLayer(
    config: inout VideoCompositorConfig,
    imageData: Data?
) {
    config.overlayImage = imageData
    guard imageData != nil else { return }

    print("[\(Tags.render)] Applying overlay image")
}
