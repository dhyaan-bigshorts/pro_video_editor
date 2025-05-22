import Cocoa
import FlutterMacOS

public class ProVideoEditorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  var eventSink: FlutterEventSink?
  private let thumbnailGenerator = ThumbnailGenerator()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "pro_video_editor", binaryMessenger: registrar.messenger)
    let eventChannel = FlutterEventChannel(
      name: "pro_video_editor_progress", binaryMessenger: registrar.messenger)

    let instance = ProVideoEditorPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "getMetadata":
      guard let args = call.arguments as? [String: Any],
        let videoData = args["videoBytes"] as? FlutterStandardTypedData,
        let ext = args["extension"] as? String
      else {
        result(["error": "Invalid arguments"])
        return
      }

      Task {
        do {
          let output = try await VideoProcessor.processVideo(videoData: videoData.data, ext: ext)
          result(output)
        } catch {
          result(
            FlutterError(
              code: "VIDEO_INFO_ERROR", message: error.localizedDescription, details: nil)
          )
        }
      }

    case "getThumbnails":
      guard
        let args = call.arguments as? [String: Any],
        let videoBytes = args["videoBytes"] as? FlutterStandardTypedData,
        let extensionStr = args["extension"] as? String,
        let boxFit = args["boxFit"] as? String,
        let outputFormat = args["outputFormat"] as? String,
        let outputWidth = args["outputWidth"] as? Int,
        let outputHeight = args["outputHeight"] as? Int,
        let rawTimestamps = args["timestamps"] as? [NSNumber]
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
        return
      }

      let timestampsUs: [Int64] = rawTimestamps.map { $0.int64Value }

      Task {
        do {
          let thumbnails = try await thumbnailGenerator.getThumbnails(
            videoData: videoBytes.data,
            fileExtension: extensionStr,
            outputFormat: outputFormat,
            boxFit: boxFit,
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            timestampsUs: timestampsUs
          )

          let flutterDataList = thumbnails.map { FlutterStandardTypedData(bytes: $0) }
          result(flutterDataList)
        } catch {
          result(
            FlutterError(code: "THUMBNAIL_ERROR", message: error.localizedDescription, details: nil)
          )
        }
      }
    case "getKeyFrames":
      guard
        let args = call.arguments as? [String: Any],
        let videoBytes = args["videoBytes"] as? FlutterStandardTypedData,
        let extensionStr = args["extension"] as? String,
        let boxFit = args["boxFit"] as? String,
        let outputFormat = args["outputFormat"] as? String,
        let outputWidth = args["outputWidth"] as? Int,
        let outputHeight = args["outputHeight"] as? Int,
        let maxOutputFrames = args["maxOutputFrames"] as? Int
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
        return
      }

      Task {
        do {
          // Make sure this method is updated in ThumbnailGenerator to return resized images
          let thumbnails = await thumbnailGenerator.getKeyFramesAsync(
            videoBytes: videoBytes.data,
            ext: extensionStr,
            outputFormat: outputFormat,
            boxFit: boxFit,
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            maxOutputFrames: maxOutputFrames
          )

          let flutterDataList = thumbnails.map { FlutterStandardTypedData(bytes: $0) }
          result(flutterDataList)
        } catch {
          result(
            FlutterError(code: "KEYFRAME_ERROR", message: error.localizedDescription, details: nil)
          )
        }
      }
    case "exportVideo":
      guard let args = call.arguments as? [String: Any],
        let videoData = args["videoBytes"] as? FlutterStandardTypedData,
        let imageData = args["imageBytes"] as? FlutterStandardTypedData,
        let videoDuration = args["videoDuration"] as? Int,
        let codecArgs = args["codecArgs"] as? [String]
      else {
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
            result(
              FlutterError(code: "FILE_ERROR", message: "Failed to read output file", details: nil))
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

  @objc public func onListen(
    withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  @objc public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
