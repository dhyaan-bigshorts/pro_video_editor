import AVFoundation
import AppKit
import CoreImage

class VideoCompositor: NSObject, AVVideoCompositing {
    static var blurSigma: Double = 0.0
    static var overlayImage: CIImage?

    static var rotateRadians: Double = 0
    static var rotateTurns: Int = 0
    static var flipX: Bool = false
    static var flipY: Bool = false
    static var cropX: CGFloat = 0
    static var cropY: CGFloat = 0
    static var scaleX: CGFloat = 1
    static var scaleY: CGFloat = 1
    static var cropWidth: CGFloat?
    static var cropHeight: CGFloat?

    private static let lutQueue = DispatchQueue(label: "lut.queue")
    private static var _lutData: Data?
    private static var _lutSize: Int = 33

    static func setOverlayImage(from data: Data?) {
        guard let data,
            let nsImage = NSImage(data: data),
            let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            overlayImage = nil
            return
        }

        overlayImage = CIImage(cgImage: cgImage)
    }

    static func clearLUT() {
        lutQueue.sync {
            _lutData = nil
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

    var sourcePixelBufferAttributes: [String: any Sendable]? = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    var requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = [
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
        var center = CGPoint(x: outputImage.extent.midX, y: outputImage.extent.midY)

        // Transformations
        var transform = CGAffineTransform.identity

        // Cropping
        if Self.cropX != 0 || Self.cropY != 0 || Self.cropWidth != nil || Self.cropHeight != nil {
            let inputExtent = outputImage.extent
            let videoWidth = inputExtent.width
            let videoHeight = inputExtent.height

            let x = Self.cropX
            var y = Self.cropY
            let width = Self.cropWidth ?? (videoWidth - x)
            let height = Self.cropHeight ?? (videoHeight - y)


            y = videoHeight - height - y

            let cropRect = CGRect(x: x, y: y, width: width, height: height)
           
            outputImage = outputImage.cropped(to: cropRect)
            outputImage = outputImage.transformed(
                by: CGAffineTransform(
                    translationX: -cropRect.origin.x ,
                    y: -cropRect.origin.y ,

                ))
            center = CGPoint(x: outputImage.extent.midX, y: outputImage.extent.midY)
        }

        // Rotation
        if Self.rotateRadians != 0 {
            // Rotate the image
            let rotation = CGAffineTransform(rotationAngle: Self.rotateRadians)
            let rotatedImage = outputImage.transformed(by: rotation)

            // Get the new bounding box after rotation
            let rotatedExtent = rotatedImage.extent

            // Translate to (0, 0)
            let translation = CGAffineTransform(
                translationX: -rotatedExtent.origin.x, y: -rotatedExtent.origin.y)
            outputImage = rotatedImage.transformed(by: translation)
            center = CGPoint(x: outputImage.extent.midX, y: outputImage.extent.midY)
        }

        // Flipping
        if Self.flipX || Self.flipY {
            let scaleX: CGFloat = Self.flipX ? -1 : 1
            let scaleY: CGFloat = Self.flipY ? -1 : 1

            let flipTransform = CGAffineTransform(translationX: center.x, y: center.y)
                .scaledBy(x: scaleX, y: scaleY)
                .translatedBy(x: -center.x, y: -center.y)

            transform = transform.concatenating(flipTransform)
        }

        // Apply Scale
        if Self.scaleX != 1 || Self.scaleY != 1 {
            transform = transform.scaledBy(x: Self.scaleX, y: Self.scaleY)
        }

        outputImage = outputImage.transformed(by: transform)

        // Apply LUT
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

        // Apply blur
        if Self.blurSigma > 0 {
            outputImage = outputImage.applyingGaussianBlur(sigma: Self.blurSigma)
        }

        // Apply overlay image
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
