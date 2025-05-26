import AVFoundation
import CoreImage

func applyBlur(
    to composition: AVMutableVideoComposition,
    sigma: Double?
) {
    guard let sigma = sigma, sigma > 0 else { return }

    print("[\(Tags.render)] Applying blur: sigma = \(sigma)")

    composition.customVideoCompositorClass = BlurCompositor.self
    BlurCompositor.blurRadius = sigma * 2.5
}

class BlurCompositor: NSObject, AVVideoCompositing {
    static var blurRadius: Double = 0.0

    private let context = CIContext()

    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    var sourcePixelBufferAttributes: [String: Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        guard let sourceBuffer = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value) else {
            request.finish(with: NSError(domain: "BlurCompositor", code: 0))
            return
        }

        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer)
        let blurred = sourceImage.applyingGaussianBlur(sigma: Self.blurRadius)

        let outputBuffer = request.renderContext.newPixelBuffer()!
        context.render(blurred, to: outputBuffer)
        request.finish(withComposedVideoFrame: outputBuffer)
    }
}
