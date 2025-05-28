import AVFoundation
import AppKit
import CoreImage

class VideoCompositor: NSObject, AVVideoCompositing {
    static var blurSigma: Double = 0.0
    static var overlayImage: CIImage?

    static var rotateTurns: Int = 0
    static var flipX: Bool = false
    static var flipY: Bool = false
    static var cropX: CGFloat = 0
    static var cropY: CGFloat = 0
    static var cropWidth: CGFloat?
    static var cropHeight: CGFloat?

    private static let lutQueue = DispatchQueue(label: "lut.queue")
    private static var _lutData: Data?
    private static var _lutSize: Int = 33

    static func setOverlayImage(from data: Data) {
        if let nsImage = NSImage(data: data),
            let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        {
            overlayImage = CIImage(cgImage: cgImage)
        }
    }

    static func setLUT(data: Data, size: Int) {
        lutQueue.sync {
            _lutData = data
            _lutSize = size
        }
    }

    private static func getLUT() -> (data: Data?, size: Int) {
        lutQueue.sync {
            (_lutData, _lutSize)
        }
    }

    private let context = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    ])

    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    var sourcePixelBufferAttributes: [String: Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        guard
            let sourceBuffer = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)
        else {
            request.finish(with: NSError(domain: "VideoCompositor", code: 0))
            return
        }
        var outputImage = CIImage(cvPixelBuffer: sourceBuffer)
        let extent = outputImage.extent
        let center = CGPoint(x: extent.midX, y: extent.midY)

        // Build transformation
        var transform = CGAffineTransform(translationX: -center.x, y: -center.y)

        // Rotation
        if Self.rotateTurns != 0 {
            transform = transform.rotated(by: CGFloat(Double.pi / 2 * Double(Self.rotateTurns)))
        }

        // Flipping
        var flipTransform = CGAffineTransform.identity
        if Self.flipX { flipTransform = flipTransform.scaledBy(x: -1, y: 1) }
        if Self.flipY { flipTransform = flipTransform.scaledBy(x: 1, y: -1) }
        transform = transform.concatenating(flipTransform)

        transform = transform.translatedBy(x: center.x, y: center.y)
        outputImage = outputImage.transformed(by: transform)

        // Apply LUT if set
        let (lutData, lutSize) = Self.getLUT()
        if let lutData,
            let lutFilter = CIFilter(name: "CIColorCube")
        {
            lutFilter.setValue(lutSize, forKey: "inputCubeDimension")
            lutFilter.setValue(lutData, forKey: "inputCubeData")
            lutFilter.setValue(outputImage, forKey: kCIInputImageKey)
            if let filteredImage = lutFilter.outputImage {
                outputImage = filteredImage
            }
        }

        // Apply blur if needed
        if Self.blurSigma > 0 {
            outputImage = outputImage.applyingGaussianBlur(sigma: Self.blurSigma)
        }

        // Apply overlay image if present
        if let overlay = Self.overlayImage {
            let imageRect = outputImage.extent
            let scaledOverlay = overlay.transformed(
                by: CGAffineTransform(
                    scaleX: imageRect.width / overlay.extent.width,
                    y: imageRect.height / overlay.extent.height))
            outputImage = scaledOverlay.composited(over: outputImage)
        }

        guard let outputBuffer = request.renderContext.newPixelBuffer() else {
            request.finish(with: NSError(domain: "VideoCompositor", code: -2, userInfo: nil))
            return
        }

        context.render(outputImage, to: outputBuffer)
        request.finish(withComposedVideoFrame: outputBuffer)
    }
}
