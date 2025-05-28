import AVFoundation
import AppKit
import CoreImage

func applyImageLayer(imageData: Data?) {
    VideoCompositor.setOverlayImage(from: imageData)
    guard imageData != nil else { return }

    print("[\(Tags.render)] Applying overlay image")
}
