import AVFoundation
import AppKit
import CoreImage
import Foundation

class RenderVideo {
    static let queue = DispatchQueue(label: "RenderVideoQueue")

    static func render(
        videoData: Data,
        imageData: Data?,
        inputFormat: String,
        outputFormat: String,
        rotateTurns: Int?,
        flipX: Bool,
        flipY: Bool,
        cropWidth: Int?,
        cropHeight: Int?,
        cropX: Int?,
        cropY: Int?,
        scaleX: Float?,
        scaleY: Float?,
        bitrate: Int?,
        enableAudio: Bool,
        playbackSpeed: Float?,
        startUs: Int64?,
        endUs: Int64?,
        colorMatrixList: [[Double]],
        blur: Double?,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (Data?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        queue.async {
            let inputURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "input.\(inputFormat)")
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "output.\(outputFormat)")

            do {
                try videoData.write(to: inputURL)
            } catch {
                onError(error)
                return
            }

            let asset = AVURLAsset(url: inputURL)
            let composition = AVMutableComposition()

            Task {
                do {
                    let videoTracks: [AVAssetTrack]
                    if #available(macOS 13.0, *) {
                        videoTracks = try await asset.loadTracks(withMediaType: .video)
                    } else {
                        videoTracks = asset.tracks(withMediaType: .video)
                    }

                    guard let videoTrack = videoTracks.first else {
                        throw NSError(
                            domain: "RenderVideo", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "No video track found"])
                    }

                    let timeRange = await applyTrim(asset: asset, startUs: startUs, endUs: endUs)

                    guard
                        let videoCompositionTrack = composition.addMutableTrack(
                            withMediaType: .video,
                            preferredTrackID: kCMPersistentTrackID_Invalid
                        )
                    else {
                        throw NSError(
                            domain: "RenderVideo", code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create video track"])
                    }

                    try videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)


                    // Apply audio track
                    await applyAudio(
                        from: asset, to: composition, timeRange: timeRange, enableAudio: enableAudio
                    )

                    // Video composition setup
                    let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(
                        start: .zero, duration: composition.duration)

                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(
                        assetTrack: videoCompositionTrack)

                    var transform = videoTrack.preferredTransform
                    let rotatedSize = applyRotation(
                        &transform, rotateTurns: rotateTurns, size: videoTrack.naturalSize)
                    applyFlip(&transform, flipX: flipX, flipY: flipY, size: rotatedSize)

                    // Apply crop and get final render size
                    let croppedSize = applyCrop(
                        &transform,
                        rotatedSize: rotatedSize,
                        cropX: cropX,
                        cropY: cropY,
                        cropWidth: cropWidth,
                        cropHeight: cropHeight,
                        rotateTurns: rotateTurns ?? 0,
                        flipX: flipX,
                        flipY: flipY,
                    )

                    // Update render size after crop
                    videoComposition.renderSize = croppedSize
                    layerInstruction.setTransform(transform, at: .zero)
                    instruction.layerInstructions = [layerInstruction]
                    videoComposition.instructions = [instruction]


                    applyScale(&transform, scaleX: scaleX, scaleY: scaleY)
                    applyPlaybackSpeed(composition: composition, speed: playbackSpeed)
                    applyColorMatrix(to: videoComposition, matrixList: colorMatrixList)
                    applyBlur(to: videoComposition, sigma: blur)
                    applyImageLayer(
                        to: videoComposition,
                        imageData: imageData,
                        croppedSize: croppedSize,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        transform: transform,
                    )
                    videoComposition.customVideoCompositorClass = VideoCompositor.self


                    let preset = applyBitrate(requestedBitrate: bitrate, fileType: .mp4)

                    guard let export = AVAssetExportSession(asset: composition, presetName: preset)
                    else {
                        throw NSError(
                            domain: "RenderVideo", code: 3,
                            userInfo: [NSLocalizedDescriptionKey: "Export session creation failed"])
                    }

                    export.outputURL = outputURL
                    export.outputFileType =  .mp4 // TODO: set output type
                    export.videoComposition = videoComposition

                    let checkInterval: TimeInterval = 0.1
                    let nanoseconds = UInt64(checkInterval * 1_000_000_000)

                    // Start export
                    export.exportAsynchronously {}

                    while export.status == .waiting || export.status == .exporting {
                        if export.status == .exporting {
                            let normalizedProgress = min(max(export.progress, 0), 1.0)
                            onProgress(Double(normalizedProgress))
                        }

                        // Sleep using async-safe method in Swift 6
                        try await Task.sleep(nanoseconds: nanoseconds)
                    }

                    let finalize: () -> Void = {
                        try? FileManager.default.removeItem(at: inputURL)
                        try? FileManager.default.removeItem(at: outputURL)
                    }

                    let handleCompletion: (Result<Data, Error>) -> Void = { result in
                        switch result {
                        case .success(let data): onComplete(data)
                        case .failure(let error): onError(error)
                        }
                        finalize()
                    }

                    // Final result
                    do {
                        guard export.status == .completed else {
                            throw export.error
                                ?? NSError(
                                    domain: "RenderVideo", code: 4,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Export failed with status: \(export.status.rawValue)"
                                    ])
                        }
                        let data = try Data(contentsOf: outputURL)
                        handleCompletion(.success(data))
                    } catch {
                        handleCompletion(.failure(error))
                    }
                } catch {
                    onError(error)
                }
            }
        }
    }
}
