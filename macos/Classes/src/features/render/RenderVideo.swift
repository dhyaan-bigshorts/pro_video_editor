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
            Task {
                var inputURL: URL!
                var outputURL: URL!

                let finalize: () -> Void = {
                    try? cleanup([inputURL, outputURL])
                }

                let handleCompletion: (Result<Data, Error>) -> Void = { result in
                    switch result {
                    case .success(let data): onComplete(data)
                    case .failure(let error): onError(error)
                    }
                    finalize()
                }

                do {
                    inputURL = try writeInputVideo(videoData, format: inputFormat)
                    outputURL = temporaryURL(for: outputFormat)

                    let asset = AVURLAsset(url: inputURL)
                    let composition = AVMutableComposition()

                    let videoTrack = try await loadVideoTrack(from: asset)

                    let timeRange = await applyTrim(asset: asset, startUs: startUs, endUs: endUs)

                    let videoCompositionTrack = try insertVideoTrack(
                        into: composition,
                        from: videoTrack,
                        timeRange: timeRange
                    )

                    // Apply audio track
                    await applyAudio(
                        from: asset, to: composition, timeRange: timeRange, enableAudio: enableAudio
                    )

                    // Video composition setup
                    let videoComposition = try await createVideoComposition(
                        asset: asset,
                        track: videoCompositionTrack,
                        duration: composition.duration
                    )

                    let croppedSize = applyCrop(
                        naturalSize: videoTrack.naturalSize,
                        rotateTurns: rotateTurns,
                        cropX: cropX,
                        cropY: cropY,
                        cropWidth: cropWidth,
                        cropHeight: cropHeight,
                    )
                    applyRotation(rotateTurns: rotateTurns)
                    applyFlip(flipX: flipX, flipY: flipY)
                    applyScale(scaleX: scaleX, scaleY: scaleY)
                    applyPlaybackSpeed(composition: composition, speed: playbackSpeed)
                    applyColorMatrix(to: videoComposition, matrixList: colorMatrixList)
                    applyBlur(sigma: blur)
                    applyImageLayer(imageData: imageData)

                    videoComposition.renderSize = croppedSize
                    // TODO replace static video compositor
                    videoComposition.customVideoCompositorClass = VideoCompositor.self

                    let preset = applyBitrate(requestedBitrate: bitrate)

                    let export = try prepareExportSession(
                        composition: composition,
                        videoComposition: videoComposition,
                        outputURL: outputURL,
                        outputFormat: outputFormat,
                        preset: preset
                    )

                    try await monitorExportProgress(export, onProgress: onProgress)

                    let data = try Data(contentsOf: outputURL)
                    handleCompletion(.success(data))
                } catch {
                    handleCompletion(.failure(error))
                }
            }
        }
    }

    // MARK: - Helper Methods

    private static func writeInputVideo(_ data: Data, format: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("input.\(format)")
        try data.write(to: url)
        return url
    }

    private static func temporaryURL(for format: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("output.\(format)")
    }

    private static func loadVideoTrack(from asset: AVAsset) async throws -> AVAssetTrack {
        if #available(macOS 13.0, *) {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else {
                throw NSError(
                    domain: "RenderVideo", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No video track found"])
            }
            return track
        } else {
            guard let track = asset.tracks(withMediaType: .video).first else {
                throw NSError(
                    domain: "RenderVideo", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No video track found"])
            }
            return track
        }
    }

    private static func insertVideoTrack(
        into composition: AVMutableComposition,
        from videoTrack: AVAssetTrack,
        timeRange: CMTimeRange
    ) throws -> AVMutableCompositionTrack {
        guard
            let track = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            throw NSError(
                domain: "RenderVideo", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create video track"])
        }
        try track.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        return track
    }

    private static func createVideoComposition(
        asset: AVAsset,
        track: AVCompositionTrack,
        duration: CMTime
    ) async throws -> AVMutableVideoComposition {
        let composition: AVMutableVideoComposition
        if #available(macOS 15.0, *) {
            composition = try await AVMutableVideoComposition.videoComposition(
                withPropertiesOf: asset)
        } else {
            composition = AVMutableVideoComposition(propertiesOf: asset)
        }

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        return composition
    }

    private static func prepareExportSession(
        composition: AVAsset,
        videoComposition: AVVideoComposition,
        outputURL: URL,
        outputFormat: String,
        preset: String
    ) throws -> AVAssetExportSession {
        guard let export = AVAssetExportSession(asset: composition, presetName: preset) else {
            throw NSError(
                domain: "RenderVideo", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Export session creation failed"])
        }
        export.outputURL = outputURL
        export.outputFileType = mapFormatToMimeType(format: outputFormat)
        export.videoComposition = videoComposition
        return export
    }

    private static func monitorExportProgress(
        _ export: AVAssetExportSession,
        onProgress: @escaping (Double) -> Void
    ) async throws {
        let updateInterval: TimeInterval = 0.2
        /*  if #available(macOS 15.0, *) {
        
             for try await state in export.states(updateInterval: updateInterval) {
                 switch state {
                 case .waiting:
                     break
                 case .pending:
                     break
                 case .exporting(let progress):
                     onProgress(progress.fractionCompleted)
                 @unknown default:
                     throw NSError(
                         domain: "RenderVideo", code: 6,
                         userInfo: [NSLocalizedDescriptionKey: "Unknown export state encountered"]
                     )
                 }
             }
         } else { */
        let intervalNs = UInt64(updateInterval * 1_000_000_000)
        export.exportAsynchronously {}
        while export.status == .waiting || export.status == .exporting {
            if export.status == .exporting {
                let normalizedProgress = min(max(export.progress, 0), 1.0)
                onProgress(Double(normalizedProgress))
            }
            try await Task.sleep(nanoseconds: intervalNs)
        }

        guard export.status == .completed else {
            throw export.error
                ?? NSError(
                    domain: "RenderVideo", code: 4,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Export failed with status \(export.status.rawValue)"
                    ])
        }
        /*  } */
    }

    private static func cleanup(_ urls: [URL]) throws {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
