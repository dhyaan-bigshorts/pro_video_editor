package ch.waio.pro_video_editor.src.features

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.*
import androidx.media3.common.audio.SonicAudioProcessor
import java.io.File
import android.net.Uri
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.Crop
import androidx.media3.effect.GaussianBlur
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.ScaleAndRotateTransformation
import androidx.media3.effect.SpeedChangeEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.Effects
import androidx.media3.effect.SingleColorLut
import com.google.common.collect.ImmutableList

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
        // Tag for logging
        val TAG = "RenderVideo"

        val inputFile =
            File(context.cacheDir, "video_input_${System.currentTimeMillis()}.$inputFormat").apply {
                writeBytes(videoBytes)
            }
        val outputFile =
            File(context.cacheDir, "video_output_${System.currentTimeMillis()}.$outputFormat")

        val rotationDegrees = (rotateTurns ?: 0) * 90f

        val videoEffects = mutableListOf<androidx.media3.common.Effect>()

        // Apply rotation
        if (rotationDegrees % 360f != 0f) {
            Log.d(TAG, "Applying rotation: $rotationDegrees degrees")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setRotationDegrees(rotationDegrees)
                .build()
        }

        // Apply flip
        if (flipX || flipY) {
            Log.d(TAG, "Applying flip - flipX: $flipX, flipY: $flipY")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setScale(if (flipX) -1f else 1f, if (flipY) -1f else 1f)
                .build()
        }

        // Apply crop
        if (cropX != null || cropY != null || cropWidth != null || cropHeight != null) {
            try {
                val (rawVideoWidth, rawVideoHeight, videoRotation) = getRotatedVideoDimensions(
                    inputFile,
                    rotationDegrees
                )

                val videoWidth = rawVideoWidth.toFloat();
                val videoHeight = rawVideoHeight.toFloat();

                if (videoWidth > 0 && videoHeight > 0) {
                    // Default to full frame if values are not provided
                    val cropX = cropX ?: 0
                    val cropY = cropY ?: 0
                    val cropWidth = cropWidth ?: (videoWidth - cropX).toInt()
                    val cropHeight = cropHeight ?: (videoHeight - cropY).toInt()

                    // Convert to NDC
                    val leftNDC = (cropX / videoWidth) * 2f - 1f
                    val rightNDC = ((cropX + cropWidth) / videoWidth) * 2f - 1f
                    val topNDC = 1f - (cropY / videoHeight) * 2f
                    val bottomNDC = 1f - ((cropY + cropHeight) / videoHeight) * 2f

                    Log.d(
                        TAG,
                        "Applying crop - left=$leftNDC, right=$rightNDC, top=$topNDC, bottom=$bottomNDC"
                    )
                    videoEffects += Crop(leftNDC, rightNDC, bottomNDC, topNDC)
                } else {
                    Log.w(TAG, "Skipping crop: invalid video dimensions.")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to apply cropping: ${e.message}")
            }
        }

        // Apply scale
        if (scaleX != null || scaleY != null) {
            Log.d(TAG, "Applying scale - scaleX: $scaleX, scaleY: $scaleY")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setScale(scaleX ?: 1f, scaleY ?: 1f)
                .build()
        }

        // Build Clipping Configuration if trimming
        val mediaItemBuilder = MediaItem.Builder().setUri(Uri.fromFile(inputFile))
        if (startUs != null || endUs != null) {
            val startMs = (startUs ?: 0L) / 1000
            val endMs = endUs?.div(1000) ?: C.TIME_END_OF_SOURCE
            Log.d(TAG, "Applying trim: start=$startMs ms, end=$endMs ms")

            val clippingConfig = MediaItem.ClippingConfiguration.Builder()
                .setStartPositionMs(startMs)
                .setEndPositionMs(endMs)
                .build()

            mediaItemBuilder.setClippingConfiguration(clippingConfig)
        }

        /// Apply color matrix "Filters"
        if (colorMatrixList.isNotEmpty()) {
            val combinedMatrix = combineColorMatrices(colorMatrixList)
            if (combinedMatrix.size == 20) {
                // Should be the best lutSize for that case.
                val lutSize = 33
                val lutData = generateLutFromColorMatrix(combinedMatrix, lutSize)
                val singleColorLut = SingleColorLut.createFromCube(lutData)
                videoEffects += singleColorLut
            } else {
                Log.w(TAG, "Color matrix must be 4x5 (20 elements), skipping LUT.")
            }
        }

        /// Apply blur
        if (blur != null && blur > 0.0) {
            Log.d(TAG, "Applying Gaussian blur with sigma: $blur")

            // Create a GaussianBlur effect with the specified sigma
            val blurEffect = GaussianBlur(blur.toFloat() * 2.5f)

            // Add the blur effect to the list of video effects
            videoEffects += blurEffect
        }


        val mediaItem = mediaItemBuilder.build()

        val audioEffects = mutableListOf<AudioProcessor>()

        // Apply playback speed
        if (playbackSpeed != null && playbackSpeed > 0f) {
            Log.d(TAG, "Applying speed change: $playbackSpeed×")
            videoEffects += SpeedChangeEffect(playbackSpeed)

            val audio = SonicAudioProcessor()
            audio.setSpeed(playbackSpeed)

            audioEffects += audio
        }

        // Load and apply transparent image overlay
        if (imageBytes != null) {
            val (videoWidth, videoHeight, videoRotation) = getRotatedVideoDimensions(
                inputFile,
                rotationDegrees
            )
            Log.d(TAG, "Applying layer image with the size $videoWidth x $videoHeight")

            val overlayBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val scaledOverlay =
                Bitmap.createScaledBitmap(overlayBitmap, videoWidth, videoHeight, true)

            val bitmapOverlay = BitmapOverlay.createStaticBitmapOverlay(scaledOverlay)
            val overlayEffect = OverlayEffect(ImmutableList.of(bitmapOverlay))

            videoEffects += overlayEffect
        }


        val effects = Effects(audioEffects, videoEffects)

        val editedMediaItemBuilder = EditedMediaItem.Builder(mediaItem)
            .setEffects(effects)

        // Remove Audio
        if (!enableAudio) {
            Log.d(TAG, "Removing audio from video")
            editedMediaItemBuilder.setRemoveAudio(true)
        }

        val editedMediaItem = editedMediaItemBuilder.build()

        val outputMimeType = mapFormatToMimeType(outputFormat)
        val transformer = Transformer.Builder(context)
            .setVideoMimeType(outputMimeType)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, result: ExportResult) {
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
                    onError(exception)
                    inputFile.delete()
                    outputFile.delete()
                }
            })
            .build()

        // Start transformation
        transformer.start(editedMediaItem, outputFile.absolutePath)


        // Progress tracking setup
        val progressHolder = androidx.media3.transformer.ProgressHolder()
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

        mainHandler.post(object : Runnable {
            override fun run() {
                val progressState = transformer.getProgress(progressHolder)
                if (progressHolder.progress >= 0) {
                    onProgress(progressHolder.progress / 100.0)
                }

                // Continue polling if transformer started
                if (progressState != Transformer.PROGRESS_STATE_NOT_STARTED) {
                    mainHandler.postDelayed(this, 200)
                }
            }
        })
    }

    private fun mapFormatToMimeType(format: String): String {
        return when (format.lowercase()) {
            "mp4" -> MimeTypes.VIDEO_H264 // Codec for MP4
            "webm" -> MimeTypes.VIDEO_VP9 // Codec for WebM
            "h264" -> MimeTypes.VIDEO_H264
            "h265", "hevc" -> MimeTypes.VIDEO_H265
            "av1" -> MimeTypes.VIDEO_AV1
            else -> MimeTypes.VIDEO_MP4 // fallback default
        }
    }

    private fun getRotatedVideoDimensions(
        videoFile: File,
        rotationDegrees: Float
    ): Triple<Int, Int, Int> {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoFile.absolutePath)
            val widthRaw =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                    ?.toIntOrNull() ?: 0
            val heightRaw =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                    ?.toIntOrNull() ?: 0
            val rotation =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                    ?.toIntOrNull() ?: 0

            val normalizedRotation = (rotation + rotationDegrees.toInt()) % 360
            val (width, height) = if (normalizedRotation == 90 || normalizedRotation == 270) {
                heightRaw to widthRaw
            } else {
                widthRaw to heightRaw
            }

            Triple(width, height, rotation)
        } catch (e: Exception) {
            Triple(0, 0, 0)
        } finally {
            retriever.release()
        }
    }

    // Function to generate 3D LUT data from a 4x5 color matrix
    fun generateLutFromColorMatrix(matrix: List<Double>, size: Int): Array<Array<IntArray>> {
        val lut = Array(size) { Array(size) { IntArray(size) } }
        for (r in 0 until size) {
            for (g in 0 until size) {
                for (b in 0 until size) {
                    val rf = r.toDouble() / (size - 1)
                    val gf = g.toDouble() / (size - 1)
                    val bf = b.toDouble() / (size - 1)

                    val rr =
                        (matrix[0] * rf + matrix[1] * gf + matrix[2] * bf + matrix[3]) + (matrix[4] / 255.0)
                    val gg =
                        (matrix[5] * rf + matrix[6] * gf + matrix[7] * bf + matrix[8]) + (matrix[9] / 255.0)
                    val bb =
                        (matrix[10] * rf + matrix[11] * gf + matrix[12] * bf + matrix[13]) + (matrix[14] / 255.0)

                    val rInt = (rr.coerceIn(0.0, 1.0) * 255).toInt()
                    val gInt = (gg.coerceIn(0.0, 1.0) * 255).toInt()
                    val bInt = (bb.coerceIn(0.0, 1.0) * 255).toInt()

                    // Combine RGB into a single ARGB integer
                    lut[r][g][b] = (0xFF shl 24) or (rInt shl 16) or (gInt shl 8) or bInt
                }
            }
        }
        return lut
    }

    fun multiplyColorMatrices(m1: List<Double>, m2: List<Double>): List<Double> {
        val result = MutableList(20) { 0.0 }
        for (i in 0..3) {
            for (j in 0..4) {
                result[i * 5 + j] =
                    m1[i * 5 + 0] * m2[0 + j] +
                            m1[i * 5 + 1] * m2[5 + j] +
                            m1[i * 5 + 2] * m2[10 + j] +
                            m1[i * 5 + 3] * m2[15 + j] +
                            if (j == 4) m1[i * 5 + 4] else 0.0
            }
        }
        return result
    }

    fun combineColorMatrices(matrices: List<List<Double>>): List<Double> {
        if (matrices.isEmpty()) return listOf()
        var result = matrices[0]
        for (i in 1 until matrices.size) {
            result = multiplyColorMatrices(matrices[i], result)
        }
        return result
    }
}
