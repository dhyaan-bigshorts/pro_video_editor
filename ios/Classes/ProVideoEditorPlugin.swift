import Flutter
import UIKit

public class ProVideoEditorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "pro_video_editor", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "pro_video_editor_progress", binaryMessenger: registrar.messenger())
        
    let instance = ProVideoEditorPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "getVideoInformation":
      guard let args = call.arguments as? [String: Any],
            let videoData = args["videoBytes"] as? FlutterStandardTypedData,
            let ext = args["extension"] as? String else {
        result(["error": "Invalid arguments"])
        return
      }

      let output = VideoMetadata.processVideo(videoData: videoData.data, ext: ext)
      result(output)

    case "createVideoThumbnails":
      guard let args = call.arguments as? [String: Any],
            let videoData = args["videoBytes"] as? FlutterStandardTypedData,
            let rawTimestamps = args["timestamps"] as? [Double],
            let format = args["thumbnailFormat"] as? String,
            let ext = args["extension"] as? String,
            let width = args["imageWidth"] as? NSNumber else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
        return
      }

      ThumbnailGenerator.generateThumbnails(
        videoBytes: videoData.data,
        timestamps: rawTimestamps,
        thumbnailFormat: format,
        extension: ext,
        width: width
      ) { thumbnails in
        let flutterDataList = thumbnails.map { FlutterStandardTypedData(bytes: $0) }
        result(flutterDataList)
      }

     case "exportVideo":
        guard let args = call.arguments as? [String: Any],
              let videoData = args["videoBytes"] as? FlutterStandardTypedData,
              let imageData = args["imageBytes"] as? FlutterStandardTypedData,
              let videoDuration = args["videoDuration"] as? Int,
              let codecArgs = args["codecArgs"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing parameters", details: nil))
            return
        }

        let startTime = args["startTime"] as? Int
        let endTime = args["endTime"] as? Int
        let inputFormat = args["inputFormat"] as? String ?? "mp4"
        let outputFormat = args["outputFormat"] as? String ?? "mp4"
        let filters = args["filters"] as? String ?? ""
        let colorMatrices = args["colorMatrices"] as? [[Double]]

        ExportVideo.generate(
            videoBytes: videoData.data,
            imageBytes: imageData.data,
            codecArgs: codecArgs,
            inputFormat: inputFormat,
            outputFormat: outputFormat,
            startTime: startTime,
            endTime: endTime,
            videoDuration: videoDuration,
            filters: filters,
            colorMatrices: colorMatrices,
            onSuccess: { outputPath in
                if let fileData = try? Data(contentsOf: URL(fileURLWithPath: outputPath)) {
                    result(FlutterStandardTypedData(bytes: fileData))
                } else {
                    result(FlutterError(code: "FILE_ERROR", message: "Failed to read output file", details: nil))
                }
            },
            onError: { errorMessage in
                result(FlutterError(code: "FFMPEG_ERROR", message: errorMessage, details: nil))
            },
            onProgress: { progress in
                self.eventSink?(progress)
            }
        )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @objc public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    @objc public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}