import AVFoundation
import AppKit
import CoreImage

class VideoCompositor: NSObject, AVVideoCompositing {
    var blurSigma: Double = 0.0
    var overlayImage: CIImage?

    var rotateRadians: Double = 0
    var rotateTurns: Int = 0
    var flipX: Bool = false
    var flipY: Bool = false
    var cropX: CGFloat = 0
    var cropY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var cropWidth: CGFloat?
    var cropHeight: CGFloat?

    private let lutQueue = DispatchQueue(label: "lut.queue")
    private var _lutData: Data?
    private var _lutSize: Int = 33

    static var config = VideoCompositorConfig()

    required override init() {
        super.init()
        apply(Self.config)
    }

    func apply(_ config: VideoCompositorConfig) {
        self.blurSigma = config.blurSigma
        self.rotateRadians = config.rotateRadians
        self.rotateTurns = config.rotateTurns
        self.flipX = config.flipX
        self.flipY = config.flipY
        self.cropX = config.cropX
        self.cropY = config.cropY
        self.cropWidth = config.cropWidth
        self.cropHeight = config.cropHeight
        self.scaleX = config.scaleX
        self.scaleY = config.scaleY
        self.setOverlayImage(from: config.overlayImage)
        self.setLUT(data: config.lutData, size: config.lutSize)
    }

    func setOverlayImage(from data: Data?) {
        guard let data,
            let nsImage = NSImage(data: data),
            let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            overlayImage = nil
            return
        }

        overlayImage = CIImage(cgImage: cgImage)
    }

    func clearLUT() {
        lutQueue.sync {
            _lutData = nil
        }
    }
    func setLUT(data: Data?, size: Int) {
        lutQueue.sync {
            _lutData = data
            _lutSize = size
        }
    }

    private func getLUT() -> (data: Data?, size: Int) {
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
        if cropX != 0 || cropY != 0 || cropWidth != nil || cropHeight != nil {
            let inputExtent = outputImage.extent
            let videoWidth = inputExtent.width
            let videoHeight = inputExtent.height

            let x = cropX
            var y = cropY
            let width = cropWidth ?? (videoWidth - x)
            let height = cropHeight ?? (videoHeight - y)

            y = videoHeight - height - y

            let cropRect = CGRect(x: x, y: y, width: width, height: height)

            outputImage = outputImage.cropped(to: cropRect)
            outputImage = outputImage.transformed(
                by: CGAffineTransform(
                    translationX: -cropRect.origin.x,
                    y: -cropRect.origin.y,

                ))
            center = CGPoint(x: outputImage.extent.midX, y: outputImage.extent.midY)
        }

        // Rotation
        if rotateRadians != 0 {
            // Rotate the image
            let rotation = CGAffineTransform(rotationAngle: rotateRadians)
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
        if flipX || flipY {
            let scaleX: CGFloat = flipX ? -1 : 1
            let scaleY: CGFloat = flipY ? -1 : 1

            let flipTransform = CGAffineTransform(translationX: center.x, y: center.y)
                .scaledBy(x: scaleX, y: scaleY)
                .translatedBy(x: -center.x, y: -center.y)

            transform = transform.concatenating(flipTransform)
        }

        // Apply Scale
        if scaleX != 1 || scaleY != 1 {
            transform = transform.scaledBy(x: scaleX, y: scaleY)
        }

        outputImage = outputImage.transformed(by: transform)

        // Apply LUT
        let (lutData, lutSize) = getLUT()
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
        if blurSigma > 0 {
            outputImage = outputImage.applyingGaussianBlur(sigma: blurSigma)
        }

        // Apply overlay image
        if let overlay = overlayImage {
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
