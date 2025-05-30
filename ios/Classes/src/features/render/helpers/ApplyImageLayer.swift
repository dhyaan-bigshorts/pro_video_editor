import AVFoundation
import CoreImage

func applyImageLayer(
    config: inout VideoCompositorConfig,
    imageData: Data?
) {
    config.overlayImage = imageData
    guard imageData != nil else { return }

    print("[Render] Applying overlay image")
}
