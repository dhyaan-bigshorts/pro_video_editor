import AVFoundation
import AppKit
import Foundation

class ThumbnailGenerator {

    func getThumbnails(
        videoData: Data,
        fileExtension: String,
        outputFormat: String,
        boxFit: String,
        outputWidth: Int,
        outputHeight: Int,
        timestampsUs: [Int64]
    ) async throws -> [Data] {
        let tempUrl = try writeToTempFile(data: videoData, fileExtension: fileExtension)
        defer { try? FileManager.default.removeItem(at: tempUrl) }

        var results = [Data?](repeating: nil, count: timestampsUs.count)

        try await withThrowingTaskGroup(of: (Int, Data?).self) { group in
            for (index, timeUs) in timestampsUs.enumerated() {
                group.addTask {
                    let data = await self.frameFromVideo(
                        url: tempUrl,
                        timeUs: timeUs,
                        outputWidth: outputWidth,
                        outputHeight: outputHeight,
                        boxFit: boxFit,
                        outputFormat: outputFormat
                    )
                    return (index, data)
                }
            }

            for try await (index, data) in group {
                results[index] = data
            }
        }

        return results.compactMap { $0 }
    }

    func getKeyFramesAsync(
        videoBytes: Data,
        ext: String,
        outputFormat: String,
        boxFit: String,
        outputWidth: Int,
        outputHeight: Int,
        maxOutputFrames: Int
    ) async -> [Data] {
        let outputSize = CGSize(width: outputWidth, height: outputHeight)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "temp_video.\(ext)")

        do {
            try videoBytes.write(to: tempURL)
        } catch {
            print("❌ Failed to write video to temp file: \(error)")
            return []
        }

        let asset = AVURLAsset(url: tempURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("❌ No video track found")
            return []
        }

        var keyframeTimes: [CMTime] = []

        do {
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ])
            reader.add(output)
            reader.startReading()

            while let buffer = output.copyNextSampleBuffer() {
                let attachments = CMSampleBufferGetSampleAttachmentsArray(
                    buffer, createIfNecessary: false)
                let isKeyframe =
                    (attachments as? [[CFString: Any]])?.first?[kCMSampleAttachmentKey_NotSync]
                    as? Bool != true
                if isKeyframe {
                    let time = CMSampleBufferGetPresentationTimeStamp(buffer)
                    // Skip very close timestamps (< 50ms)
                    if keyframeTimes.last == nil
                        || abs(time.seconds - keyframeTimes.last!.seconds) > 0.05
                    {
                        keyframeTimes.append(time)
                    }
                }
            }

            reader.cancelReading()
        } catch {
            print("❌ AVAssetReader error: \(error)")
        }

        let selectedTimes: [CMTime] = {
            if keyframeTimes.count <= maxOutputFrames { return keyframeTimes }
            let step = Double(keyframeTimes.count) / Double(maxOutputFrames)
            return (0..<maxOutputFrames).map { keyframeTimes[Int(Double($0) * step)] }
        }()

        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = outputSize
        generator.appliesPreferredTrackTransform = true

        var results = [Data?](repeating: nil, count: selectedTimes.count)

        await withTaskGroup(of: (Int, Data?).self) { group in
            for (index, time) in selectedTimes.enumerated() {
                group.addTask {
                    do {
                        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                        let nsImage = NSImage(cgImage: cgImage, size: .zero)
                        let resized = self.resizeImage(
                            image: nsImage,
                            targetWidth: outputWidth,
                            targetHeight: outputHeight,
                            boxFit: boxFit
                        )
                        let data = self.compressImage(image: resized, format: outputFormat)
                        return (index, data)
                    } catch {
                        print("❌ Error generating keyframe at \(time.seconds): \(error)")
                        return (index, nil)
                    }
                }
            }

            for await (index, data) in group {
                results[index] = data
            }
        }

        try? FileManager.default.removeItem(at: tempURL)
        return results.compactMap { $0 }
    }

    private func compressBitmap(_ image: NSImage, format: String) -> Data? {
        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else { return nil }

        switch format.lowercased() {
        case "png":
            return bitmap.representation(using: .png, properties: [:])
        case "webp":
            // macOS doesn't support WebP natively; you'd need a third-party library
            return nil
        default:
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
    }

    private func resizeBitmapKeepingAspect(
        _ original: NSImage,
        targetWidth: Int,
        targetHeight: Int,
        scaleType: String = "contain"
    ) -> NSImage {
        let originalSize = original.size
        let widthRatio = CGFloat(targetWidth) / originalSize.width
        let heightRatio = CGFloat(targetHeight) / originalSize.height
        let scale =
            scaleType.lowercased() == "cover"
            ? max(widthRatio, heightRatio)
            : min(widthRatio, heightRatio)

        let newSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        original.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0)
        resized.unlockFocus()
        return resized
    }

    private func frameFromVideo(
        url: URL,
        timeUs: Int64,
        outputWidth: Int,
        outputHeight: Int,
        boxFit: String,
        outputFormat: String
    ) async -> Data? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        let time = CMTime(value: timeUs, timescale: 1_000_000)

        if #available(macOS 15.0, *) {
            do {
                let cgImage = try await generateImageAsync(generator: generator, time: time)
                return processImage(cgImage, outputWidth, outputHeight, boxFit, outputFormat)
            } catch {
                print("❌ async image generation failed: \(error)")
                return nil
            }
        } else {
            do {
                var actualTime = CMTime.zero
                let cgImage = try generator.copyCGImage(at: time, actualTime: &actualTime)
                return processImage(cgImage, outputWidth, outputHeight, boxFit, outputFormat)
            } catch {
                print("❌ legacy image generation failed: \(error)")
                return nil
            }
        }
    }

    @available(macOS 15.0, *)
    private func generateImageAsync(generator: AVAssetImageGenerator, time: CMTime) async throws
        -> CGImage
    {
        return try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
                _, image, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image, result == .succeeded {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "ThumbnailGen",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Image generation failed"]
                        ))
                }
            }
        }
    }

    private func processImage(
        _ cgImage: CGImage,
        _ outputWidth: Int,
        _ outputHeight: Int,
        _ boxFit: String,
        _ format: String
    ) -> Data? {
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        let resized = resizeImage(
            image: nsImage, targetWidth: outputWidth, targetHeight: outputHeight, boxFit: boxFit
        )
        return compressImage(image: resized, format: format)
    }

    private func resizeImage(image: NSImage, targetWidth: Int, targetHeight: Int, boxFit: String)
        -> NSImage
    {
        let originalSize = image.size
        let widthRatio = CGFloat(targetWidth) / originalSize.width
        let heightRatio = CGFloat(targetHeight) / originalSize.height

        let scale: CGFloat =
            (boxFit.lowercased() == "cover")
            ? max(widthRatio, heightRatio)
            : min(widthRatio, heightRatio)

        let newSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    private func compressImage(image: NSImage, format: String) -> Data? {
        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else { return nil }

        let imageFormat: NSBitmapImageRep.FileType = {
            switch format.lowercased() {
            case "png": return .png
            case "jpg", "jpeg": return .jpeg
            case "tiff": return .tiff
            case "bmp": return .bmp
            case "gif": return .gif
            default: return .jpeg
            }
        }()

        return bitmap.representation(using: imageFormat, properties: [.compressionFactor: 0.9])
    }

    private func writeToTempFile(data: Data, fileExtension: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
        try data.write(to: fileUrl)
        return fileUrl
    }
}
