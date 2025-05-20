package ch.waio.pro_video_editor

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import ch.waio.pro_video_editor.src.ExportVideo
import ch.waio.pro_video_editor.src.VideoInformation
import ch.waio.pro_video_editor.src.ThumbnailGenerator
import kotlinx.coroutines.*
import java.io.File

/** ProVideoEditorPlugin */
class ProVideoEditorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private lateinit var exportVideo: ExportVideo
    private lateinit var videoInformation: VideoInformation
    private lateinit var thumbnailGenerator: ThumbnailGenerator

    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "pro_video_editor")
        eventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "pro_video_editor_progress")

        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        exportVideo = ExportVideo(flutterPluginBinding.applicationContext);
        videoInformation = VideoInformation(flutterPluginBinding.applicationContext)
        thumbnailGenerator = ThumbnailGenerator(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "getVideoInformation" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")

                if (videoBytes != null && extension != null) {
                    val info = videoInformation.processVideo(videoBytes, extension)
                    result.success(info)
                } else {
                    result.error(
                        "InvalidArgument", "Expected raw Uint8List (ByteArray/List<Int>)", null
                    )
                }
            }

            "getThumbnails" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")
                val boxFit = call.argument<String>("boxFit")
                val outputFormat = call.argument<String>("outputFormat")
                val outputWidth = call.argument<Number>("outputWidth")?.toInt()
                val outputHeight = call.argument<Number>("outputHeight")?.toInt()
                val rawTimestamps = call.argument<List<Number>>("timestamps") ?: emptyList()
                val timestampsUs = rawTimestamps.map { it.toLong() }

 
                if (videoBytes == null ||
                 extension == null || 
                 boxFit == null || 
                 outputFormat == null || 
                 outputWidth == null || 
                 outputHeight == null || 
                 timestampsUs == null) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
                    return
                }

                coroutineScope.launch {
                    try {
                        val thumbnails = thumbnailGenerator.getThumbnails(
                            videoBytes = videoBytes,
                            extension = extension,
                            outputFormat = outputFormat,
                            boxFit = boxFit,
                            outputWidth = outputWidth,
                            outputHeight = outputHeight,
                            timestampsUs = timestampsUs
                        )

                        withContext(Dispatchers.Main) {
                            result.success(thumbnails)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("THUMBNAIL_ERROR", e.message, null)
                        }
                    }
                }
            }
            "getKeyFrames" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")
                val boxFit = call.argument<String>("boxFit")
                val outputFormat = call.argument<String>("outputFormat")
                val outputWidth = call.argument<Number>("outputWidth")?.toInt()
                val outputHeight = call.argument<Number>("outputHeight")?.toInt()
                val maxOutputFrames = call.argument<Number>("maxOutputFrames")?.toInt()

 
                if (videoBytes == null ||
                 extension == null || 
                 boxFit == null || 
                 outputFormat == null || 
                 outputWidth == null || 
                 outputHeight == null || 
                 maxOutputFrames == null) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
                    return
                }

                coroutineScope.launch {
                    try {
                        val thumbnails = thumbnailGenerator.getKeyFrames(
                            videoBytes = videoBytes,
                            extension = extension,
                            outputFormat = outputFormat,
                            boxFit = boxFit,
                            outputWidth = outputWidth,
                            outputHeight = outputHeight,
                            maxOutputFrames = maxOutputFrames
                        )

                        withContext(Dispatchers.Main) {
                            result.success(thumbnails)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("THUMBNAIL_ERROR", e.message, null)
                        }
                    }
                }
            }

            "exportVideo" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val imageBytes = call.argument<ByteArray>("imageBytes")
                val videoDuration = call.argument<Int>("videoDuration")
                val startTime = call.argument<Int>("startTime")
                val endTime = call.argument<Int>("endTime")
                val filters = call.argument<String>("filters") ?: ""
                val colorMatrices = call.argument<List<List<Double>>>("colorMatrices")
                val inputFormat = call.argument<String>("inputFormat") ?: "mp4"
                val outputFormat = call.argument<String>("outputFormat") ?: "mp4"
                val codecArgs = call.argument<List<String>>("codecArgs")
                
                if (videoBytes == null || imageBytes == null || videoDuration == null || codecArgs == null) {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "Missing parameters",
                        null
                    )
                    return
                }

                exportVideo.generate(videoBytes = videoBytes,
                    imageBytes = imageBytes,
                    codecArgs = codecArgs,
                    inputFormat = inputFormat,
                    outputFormat = outputFormat,
                    startTime = startTime,
                    endTime = endTime,
                    videoDuration = videoDuration,
                    filters = filters,
                    colorMatrices = colorMatrices,
                    onSuccess = { outputPath ->
                        val outputFile = File(outputPath)
                        val outputBytes = outputFile.readBytes()
                        Handler(Looper.getMainLooper()).post {
                            result.success(outputBytes)
                        }
                    },
                    onError = { errorMsg ->
                        Handler(Looper.getMainLooper()).post {
                            result.error("ERROR", errorMsg, null)
                        }
                    },
                    onProgress = { progress ->
                        Handler(Looper.getMainLooper()).post {
                            eventSink?.success(progress)
                        }
                    })
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        coroutineScope.cancel()
    }
}
