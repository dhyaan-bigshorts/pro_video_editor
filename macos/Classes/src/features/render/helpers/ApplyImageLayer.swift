import AVFoundation
import AppKit
import CoreImage

func applyImageLayer(
    to composition: AVMutableVideoComposition,
    imageData: Data?,
    croppedSize: CGSize,
    scaleX: Float?,
    scaleY: Float?,
    transform: CGAffineTransform
) {
    if let data = imageData {
        VideoCompositor.setOverlayImage(from: data)
        print("[\(Tags.render)] Applying image overlay")
    }
}
