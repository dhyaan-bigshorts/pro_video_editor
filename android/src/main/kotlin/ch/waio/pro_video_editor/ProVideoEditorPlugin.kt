package ch.waio.pro_video_editor

import android.os.Handler
import android.os.Looper
import android.util.Log
import ch.waio.pro_video_editor.src.features.Metadata
import ch.waio.pro_video_editor.src.features.render.RenderVideo
import ch.waio.pro_video_editor.src.features.ThumbnailGenerator
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*

/** ProVideoEditorPlugin */
class ProVideoEditorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private lateinit var renderVideo: RenderVideo
    private lateinit var metadata: Metadata
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

        renderVideo = RenderVideo(flutterPluginBinding.applicationContext);
        metadata = Metadata(flutterPluginBinding.applicationContext)
        thumbnailGenerator = ThumbnailGenerator(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "getMetadata" -> {
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")

                if (videoBytes != null && extension != null) {
                    val meta = metadata.processVideo(videoBytes, extension)
                    result.success(meta)
                } else {
                    result.error(
                        "InvalidArgument", "Expected raw Uint8List (ByteArray/List<Int>)", null
                    )
                }
            }

            "getThumbnails" -> {
                val id = call.argument<String>("id") ?: ""
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val extension = call.argument<String>("extension")
                val boxFit = call.argument<String>("boxFit")
                val outputFormat = call.argument<String>("outputFormat")
                val outputWidth = call.argument<Number>("outputWidth")?.toInt()
                val outputHeight = call.argument<Number>("outputHeight")?.toInt()
                val rawTimestamps = call.argument<List<Number>>("timestamps") ?: emptyList()
                val timestampsUs = rawTimestamps.map { it.toLong() }
                val maxOutputFrames = call.argument<Number>("maxOutputFrames")?.toInt()


                if (videoBytes == null ||
                    extension == null ||
                    boxFit == null ||
                    outputFormat == null ||
                    outputWidth == null ||
                    outputHeight == null ||
                    (timestampsUs == null && maxOutputFrames == null)
                ) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid arguments", null)
                    return
                }
                postProgress(id, 0.0)

                coroutineScope.launch {
                    try {
                        val thumbnails = thumbnailGenerator.getThumbnails(
                            videoBytes = videoBytes,
                            extension = extension,
                            outputFormat = outputFormat,
                            boxFit = boxFit,
                            outputWidth = outputWidth,
                            outputHeight = outputHeight,
                            timestampsUs = timestampsUs,
                            maxOutputFrames = maxOutputFrames,
                            onProgress = { progress -> postProgress(id, progress) },
                        )

                        withContext(Dispatchers.Main) {
                            postProgress(id, 1.0)
                            result.success(thumbnails)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("THUMBNAIL_ERROR", e.message, null)
                        }
                    }
                }
            }

            "renderVideo" -> {
                val id = call.argument<String>("id") ?: ""
                val videoBytes = call.argument<ByteArray>("videoBytes")
                val imageBytes = call.argument<ByteArray?>("imageBytes")
                val rotateTurns = call.argument<Number>("rotateTurns")?.toInt()
                val cropWidth = call.argument<Number>("cropWidth")?.toInt()
                val cropHeight = call.argument<Number>("cropHeight")?.toInt()
                val cropX = call.argument<Number>("cropX")?.toInt()
                val cropY = call.argument<Number>("cropY")?.toInt()
                val bitrate = call.argument<Number>("bitrate")?.toInt()
                val scaleX = call.argument<Number>("scaleX")?.toFloat()
                val scaleY = call.argument<Number>("scaleY")?.toFloat()
                val blur = call.argument<Number>("blur")?.toDouble()
                val flipX = call.argument<Boolean>("flipX") ?: false
                val flipY = call.argument<Boolean>("flipY") ?: false
                val enableAudio = call.argument<Boolean>("enableAudio") ?: true
                val playbackSpeed = call.argument<Number>("playbackSpeed")?.toFloat()
                val startUs = call.argument<Number>("startTime")?.toLong()
                val endUs = call.argument<Number>("endTime")?.toLong()
                val inputFormat = call.argument<String>("inputFormat") ?: "mp4"
                val outputFormat = call.argument<String>("outputFormat") ?: "mp4"
                val colorMatrixList = call.argument<List<List<Double>>>("colorMatrixList")
                    ?: emptyList<List<Double>>()

                if (videoBytes == null) {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "Missing parameters",
                        null
                    )
                    return
                }
                postProgress(id, 0.0)

                renderVideo.render(
                    videoBytes = videoBytes,
                    imageBytes = imageBytes,
                    inputFormat = inputFormat,
                    outputFormat = outputFormat,
                    rotateTurns = rotateTurns,
                    flipX = flipX,
                    flipY = flipY,
                    scaleX = scaleX,
                    scaleY = scaleY,
                    cropWidth = cropWidth,
                    cropHeight = cropHeight,
                    cropX = cropX,
                    cropY = cropY,
                    enableAudio = enableAudio,
                    playbackSpeed = playbackSpeed,
                    startUs = startUs,
                    endUs = endUs,
                    colorMatrixList = colorMatrixList,
                    blur = blur,
                    bitrate = bitrate,
                    onProgress = { progress -> postProgress(id, progress) },
                    onComplete = { resultBytes ->
                        postProgress(id, 1.0)
                        Handler(Looper.getMainLooper()).post {
                            result.success(resultBytes)
                        }
                    },
                    onError = { error ->
                        Log.e("RenderVideo", "Error rendering video: ${error.message}")
                    }
                )
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

    private fun postProgress(id: String, progress: Double) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(
                mapOf(
                    "id" to id,
                    "progress" to progress
                )
            )
        }
    }
}
