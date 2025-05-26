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

                    var transform = CGAffineTransform.identity
                    applyRotation(&transform, rotateTurns: rotateTurns)
                    applyFlip(&transform, flipX: flipX, flipY: flipY)
                    await applyCrop(
                        &transform, videoTrack: videoTrack, cropX: cropX, cropY: cropY,
                        cropWidth: cropWidth, cropHeight: cropHeight)
                    applyScale(&transform, scaleX: scaleX, scaleY: scaleY)
                    applyPlaybackSpeed(composition: composition, speed: playbackSpeed)
                    applyColorMatrix(to: videoComposition, matrixList: colorMatrixList)
                    applyBlur(to: videoComposition, sigma: blur)
                    applyImageLayer(
                        to: videoComposition,
                        imageData: imageData,
                        videoSize: videoTrack.naturalSize,
                        rotation: rotateTurns,
                        cropWidth: cropWidth,
                        cropHeight: cropHeight,
                        scaleX: scaleX,
                        scaleY: scaleY
                    )

                    layerInstruction.setTransform(transform, at: .zero)
                    instruction.layerInstructions = [layerInstruction]
                    videoComposition.instructions = [instruction]
                    videoComposition.renderSize =
                        CGRect(origin: .zero, size: videoTrack.naturalSize).applying(transform)
                        .standardized.size

                    let preset = applyBitrate(requestedBitrate: bitrate, fileType: .mp4)

                    guard let export = AVAssetExportSession(asset: composition, presetName: preset)
                    else {
                        throw NSError(
                            domain: "RenderVideo", code: 3,
                            userInfo: [NSLocalizedDescriptionKey: "Export session creation failed"])
                    }

                    export.outputURL = outputURL
                    export.outputFileType = .mp4
                    export.videoComposition = videoComposition

                    let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        let progress = export.progress
                        DispatchQueue.global().async {
                            onProgress(Double(progress))
                        }
                    }

                    let finalize: () -> Void = {
                        try? FileManager.default.removeItem(at: inputURL)
                        try? FileManager.default.removeItem(at: outputURL)
                    }

                    let handleCompletion: (Result<Data, Error>) -> Void = { result in
                        timer.invalidate()
                        switch result {
                        case .success(let data): onComplete(data)
                        case .failure(let error): onError(error)
                        }
                        finalize()
                    }

                    if #available(macOS 15.0, *) {
                        do {
                            try await export.export(to: outputURL, as: .mp4)
                            let data = try Data(contentsOf: outputURL)
                            handleCompletion(.success(data))
                        } catch {
                            handleCompletion(.failure(error))
                        }
                    } else {
                        export.exportAsynchronously {
                            do {
                                guard export.status == .completed else {
                                    throw export.error
                                        ?? NSError(
                                            domain: "RenderVideo", code: 4,
                                            userInfo: [NSLocalizedDescriptionKey: "Export failed"])
                                }
                                let data = try Data(contentsOf: outputURL)
                                handleCompletion(.success(data))
                            } catch {
                                handleCompletion(.failure(error))
                            }
                        }
                    }
                } catch {
                    onError(error)
                }
            }
        }
    }
}
