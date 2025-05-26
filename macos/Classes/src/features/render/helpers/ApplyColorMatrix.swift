import AVFoundation
import CoreImage

public func applyColorMatrix(
    to composition: AVMutableVideoComposition,
    matrixList: [[Double]]
) {
    guard !matrixList.isEmpty else { return }

    let combined = combineColorMatrices(matrixList)
    guard combined.count == 20 else {
        print("[\(Tags.render)] Color matrix must be 4x5 (20 elements), skipping.")
        return
    }

    print("[\(Tags.render)] Applying color matrix")

    composition.customVideoCompositorClass = ColorMatrixCompositor.self
    ColorMatrixCompositor.colorMatrix = combined
}

// MARK: - Matrix Combination Logic

private func multiplyColorMatrices(_ m1: [Double], _ m2: [Double]) -> [Double] {
    var result = [Double](repeating: 0.0, count: 20)
    for i in 0...3 {
        for j in 0...4 {
            result[i * 5 + j] =
                m1[i * 5 + 0] * m2[0 + j] + m1[i * 5 + 1] * m2[5 + j] + m1[i * 5 + 2] * m2[10 + j]
                + m1[i * 5 + 3] * m2[15 + j] + (j == 4 ? m1[i * 5 + 4] : 0.0)
        }
    }
    return result
}

private func combineColorMatrices(_ matrices: [[Double]]) -> [Double] {
    guard !matrices.isEmpty else { return [] }
    return matrices.dropFirst().reduce(matrices.first!) { acc, next in
        multiplyColorMatrices(next, acc)
    }
}

class ColorMatrixCompositor: NSObject, AVVideoCompositing {
    static var colorMatrix: [Double] = []

    private let context = CIContext()

    // TODO:
    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    var sourcePixelBufferAttributes: [String: Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard
            let srcBuffer = asyncVideoCompositionRequest.sourceFrame(
                byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
            let image = CIImage(cvPixelBuffer: srcBuffer).applyingColorMatrix(
                from: Self.colorMatrix)
        else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "ColorMatrix", code: 0))
            return
        }

        let dstBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer()!
        context.render(image, to: dstBuffer)
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: dstBuffer)
    }
}

// MARK: - Helper

extension CIImage {
    func applyingColorMatrix(from matrix: [Double]) -> CIImage? {
        guard matrix.count == 20 else { return nil }

        let filter = CIFilter(name: "CIColorMatrix")!
        filter.setValue(self, forKey: kCIInputImageKey)

        func v(_ i: Int) -> CGFloat { CGFloat(matrix[i]) }

        filter.setValue(CIVector(x: v(0), y: v(1), z: v(2), w: v(3)), forKey: "inputRVector")
        filter.setValue(CIVector(x: v(5), y: v(6), z: v(7), w: v(8)), forKey: "inputGVector")
        filter.setValue(CIVector(x: v(10), y: v(11), z: v(12), w: v(13)), forKey: "inputBVector")
        filter.setValue(CIVector(x: v(15), y: v(16), z: v(17), w: v(18)), forKey: "inputAVector")
        filter.setValue(CIVector(x: v(4), y: v(9), z: v(14), w: v(19)), forKey: "inputBiasVector")

        return filter.outputImage
    }
}
