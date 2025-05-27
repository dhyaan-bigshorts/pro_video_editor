import AVFoundation
import CoreImage
import AppKit

public func applyImageLayer(
    to composition: AVMutableVideoComposition,
    imageData: Data?,
    videoSize: CGSize,
    rotation: Int?,
    cropWidth: Int?,
    cropHeight: Int?,
    scaleX: Float?,
    scaleY: Float?
) {
    guard let imageData = imageData,
          let nsImage = NSImage(data: imageData),
          let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return
    }

    var width = Int(videoSize.width)
    var height = Int(videoSize.height)

    if let cropWidth = cropWidth {
        width = cropWidth
    }
    if let cropHeight = cropHeight {
        height = cropHeight
    }
    if let sx = scaleX {
        width = Int(Float(width) * sx)
    }
    if let sy = scaleY {
        height = Int(Float(height) * sy)
    }

    print("[\(Tags.render)] Applying image overlay: size \(width)x\(height)")

    let overlayLayer = CALayer()
    overlayLayer.contents = cgImage
    overlayLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
    overlayLayer.masksToBounds = true

    let videoLayer = CALayer()
    videoLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)

    let parentLayer = CALayer()
    parentLayer.frame = videoLayer.frame
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(overlayLayer)

    composition.animationTool = AVVideoCompositionCoreAnimationTool(
        postProcessingAsVideoLayer: videoLayer,
        in: parentLayer
    )
}
