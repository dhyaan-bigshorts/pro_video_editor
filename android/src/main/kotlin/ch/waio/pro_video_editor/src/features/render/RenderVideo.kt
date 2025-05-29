package ch.waio.pro_video_editor.src.features.render

import PACKAGE_TAG
import RENDER_TAG
import android.content.Context
import android.media.MediaCodecInfo
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import applyAudio
import applyBitrate
import applyBlur
import applyColorMatrix
import applyCrop
import applyFlip
import applyImageLayer
import applyPlaybackSpeed
import applyRotation
import applyScale
import applyTrim
import mapFormatToMimeType
import java.io.File

@UnstableApi
class RenderVideo(private val context: Context) {
    fun render(
        videoBytes: ByteArray,
        imageBytes: ByteArray?,
        inputFormat: String,
        outputFormat: String,
        rotateTurns: Int?,
        flipX: Boolean = false,
        flipY: Boolean = false,
        cropWidth: Int?,
        cropHeight: Int?,
        cropX: Int?,
        cropY: Int?,
        scaleX: Float?,
        scaleY: Float?,
        bitrate: Int?,
        enableAudio: Boolean = true,
        playbackSpeed: Float? = null,
        startUs: Long? = null,
        endUs: Long? = null,
        colorMatrixList: List<List<Double>>,
        blur: Double?,
        onProgress: (Double) -> Unit,
        onComplete: (ByteArray?) -> Unit,
        onError: (Throwable) -> Unit
    ) {
        val inputFile =
            File(context.cacheDir, "video_input_${System.currentTimeMillis()}.$inputFormat").apply {
                writeBytes(videoBytes)
            }
        val outputFile =
            File(context.cacheDir, "video_output_${System.currentTimeMillis()}.$outputFormat")

        val videoEffects = mutableListOf<Effect>()
        val audioEffects = mutableListOf<AudioProcessor>()
        val mediaItemBuilder = MediaItem.Builder().setUri(Uri.fromFile(inputFile))

        val rotationDegrees = (4 - (rotateTurns ?: 0)) * 90f

        applyRotation(videoEffects, rotationDegrees)
        applyFlip(videoEffects, flipX, flipY)
        applyCrop(
            videoEffects, inputFile, rotationDegrees,
            flipX, flipY, cropWidth, cropHeight, cropX, cropY,
        )
        applyScale(videoEffects, scaleX, scaleY)
        applyTrim(mediaItemBuilder, startUs, endUs)
        applyColorMatrix(videoEffects, colorMatrixList)
        applyBlur(videoEffects, blur)
        applyImageLayer(
            videoEffects, inputFile, imageBytes, rotationDegrees,
            cropWidth, cropHeight, scaleX, scaleY
        )
        applyPlaybackSpeed(videoEffects, audioEffects, playbackSpeed)

        val mediaItem = mediaItemBuilder.build()
        val effects = Effects(audioEffects, videoEffects)

        val editedMediaItemBuilder = EditedMediaItem.Builder(mediaItem).setEffects(effects)

        applyAudio(editedMediaItemBuilder, enableAudio)

        var shouldStopPolling = false
        val outputMimeType = mapFormatToMimeType(outputFormat)
        var editedMediaItem = editedMediaItemBuilder.build()
        val encoderFactoryBuilder = DefaultEncoderFactory.Builder(context)

        applyBitrate(encoderFactoryBuilder, outputMimeType, bitrate)


        val transformer = Transformer.Builder(context)
            .setEncoderFactory(encoderFactoryBuilder.build())
            .setVideoMimeType(outputMimeType)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, result: ExportResult) {
                    shouldStopPolling = true;
                    try {
                        val resultBytes = outputFile.readBytes()
                        onComplete(resultBytes)
                    } catch (e: Exception) {
                        onError(e)
                    } finally {
                        inputFile.delete()
                        outputFile.delete()
                    }
                }

                override fun onError(
                    composition: Composition,
                    result: ExportResult,
                    exception: ExportException
                ) {
                    shouldStopPolling = true;
                    onError(exception)
                    inputFile.delete()
                    outputFile.delete()
                }
            })
            .build()

        // Start transformation
        transformer.start(editedMediaItem, outputFile.absolutePath)

        // Progress tracking setup
        val progressHolder = ProgressHolder()
        val mainHandler = Handler(Looper.getMainLooper())

        mainHandler.post(object : Runnable {
            override fun run() {
                if (shouldStopPolling) return

                val progressState = transformer.getProgress(progressHolder)
                if (progressHolder.progress >= 0) {
                    onProgress(progressHolder.progress / 100.0)
                }

                // Continue polling if transformer started
                if (!shouldStopPolling && progressState != Transformer.PROGRESS_STATE_NOT_STARTED) {
                    mainHandler.postDelayed(this, 200)
                }
            }
        })
    }
}