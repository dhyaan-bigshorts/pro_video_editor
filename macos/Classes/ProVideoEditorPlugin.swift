import FlutterMacOS
import Foundation

public class ProVideoEditorPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "pro_video_editor", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "pro_video_editor_progress", binaryMessenger: registrar.messenger)

        let instance = ProVideoEditorPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    let metadata = VideoMetadata()
    let renderQueue = DispatchQueue(label: "RenderQueue")
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")

        case "getMetadata":
            guard let args = call.arguments as? [String: Any],
                  let videoBytes = args["videoBytes"] as? FlutterStandardTypedData,
                  let extensionStr = args["extension"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected arguments missing", details: nil))
                return
            }

            Task {
                do {
                    let meta = try await VideoMetadata.processVideo(videoData: videoBytes.data, ext: extensionStr)
                    result(meta)
                } catch {
                    result(FlutterError(code: "METADATA_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "getThumbnails":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String,
                  let videoBytes = (args["videoBytes"] as? FlutterStandardTypedData)?.data,
                  let extensionStr = args["extension"] as? String,
                  let boxFit = args["boxFit"] as? String,
                  let outputFormat = args["outputFormat"] as? String,
                  let outputWidth = args["outputWidth"] as? Int,
                  let outputHeight = args["outputHeight"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing parameters", details: nil))
                return
            }

            let timestampsUs = (args["timestamps"] as? [NSNumber])?.map { $0.int64Value } ?? []
            let maxOutputFrames = args["maxOutputFrames"] as? Int

            postProgress(id: id, progress: 0.0)

            Task {
                let thumbnails = await ThumbnailGenerator.getThumbnails(
                    videoData: videoBytes,
                    extension: extensionStr,
                    outputFormat: outputFormat,
                    boxFit: boxFit,
                    outputWidth: outputWidth,
                    outputHeight: outputHeight,
                    timestampsUs: timestampsUs,
                    maxOutputFrames: maxOutputFrames,
                    onProgress: { progress in
                        self.postProgress(id: id, progress: progress)
                    }
                )
                self.postProgress(id: id, progress: 1.0)
                result(thumbnails)
            }

        case "renderVideo":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String,
                  let videoBytes = (args["videoBytes"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing parameters", details: nil))
                return
            }

            let inputFormat = args["inputFormat"] as? String ?? "mp4"
            let outputFormat = args["outputFormat"] as? String ?? "mp4"
            let imageBytes = (args["imageBytes"] as? FlutterStandardTypedData)?.data
            let rotateTurns = args["rotateTurns"] as? Int
            let cropWidth = args["cropWidth"] as? Int
            let cropHeight = args["cropHeight"] as? Int
            let cropX = args["cropX"] as? Int
            let cropY = args["cropY"] as? Int
            let scaleX = (args["scaleX"] as? NSNumber)?.floatValue
            let scaleY = (args["scaleY"] as? NSNumber)?.floatValue
            let flipX = args["flipX"] as? Bool ?? false
            let flipY = args["flipY"] as? Bool ?? false
            let blur = args["blur"] as? Double
            let bitrate = args["bitrate"] as? Int
            let enableAudio = args["enableAudio"] as? Bool ?? true
            let playbackSpeed = (args["playbackSpeed"] as? NSNumber)?.floatValue
            let startUs = args["startTime"] as? Int64
            let endUs = args["endTime"] as? Int64
            let colorMatrixList = args["colorMatrixList"] as? [[Double]] ?? []

            postProgress(id: id, progress: 0.0)

            RenderVideo.render(
                videoData: videoBytes,
                imageData: imageBytes,
                inputFormat: inputFormat,
                outputFormat: outputFormat,
                rotateTurns: rotateTurns,
                flipX: flipX,
                flipY: flipY,
                cropWidth: cropWidth,
                cropHeight: cropHeight,
                cropX: cropX,
                cropY: cropY,
                scaleX: scaleX,
                scaleY: scaleY,
                bitrate: bitrate,
                enableAudio: enableAudio,
                playbackSpeed: playbackSpeed,
                startUs: startUs,
                endUs: endUs,
                colorMatrixList: colorMatrixList,
                blur: blur,
                onProgress: { progress in
                    self.postProgress(id: id, progress: progress)
                },
                onComplete: { outputData in
                    self.postProgress(id: id, progress: 1.0)
                    result(outputData)
                },
                onError: { error in
                    result(FlutterError(code: "RENDER_ERROR", message: error.localizedDescription, details: nil))
                }
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func postProgress(id: String, progress: Double) {
        DispatchQueue.main.async {
            self.eventSink?([
                "id": id,
                "progress": progress
            ])
        }
    }
}

extension ProVideoEditorPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
