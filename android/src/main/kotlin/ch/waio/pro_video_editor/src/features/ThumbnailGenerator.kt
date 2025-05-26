package ch.waio.pro_video_editor.src.features

import PACKAGE_TAG
import THUMBNAIL_TAG
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicInteger

class ThumbnailGenerator(private val context: Context) {

    suspend fun getThumbnails(
        videoBytes: ByteArray,
        extension: String,
        outputFormat: String,
        boxFit: String,
        outputWidth: Int,
        outputHeight: Int,
        timestampsUs: List<Long> = emptyList(),
        maxOutputFrames: Int? = 10,
        onProgress: (Double) -> Unit,
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        when {
            timestampsUs.isNotEmpty() -> {
                getThumbnailsFromTimestamps(
                    videoBytes, extension, outputFormat, boxFit,
                    outputWidth, outputHeight, timestampsUs, onProgress
                )
            }

            maxOutputFrames != null -> {
                getKeyFrames(
                    videoBytes, extension, outputFormat, boxFit,
                    outputWidth, outputHeight, maxOutputFrames, onProgress
                )
            }

            else -> emptyList() // fallback in case both are missing
        }
    }

    private suspend fun getThumbnailsFromTimestamps(
        videoBytes: ByteArray,
        extension: String,
        outputFormat: String,
        boxFit: String,
        outputWidth: Int,
        outputHeight: Int,
        timestampsUs: List<Long>,
        onProgress: (Double) -> Unit,
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        val tempVideoFile = writeBytesToTempFile(videoBytes, extension)
        val thumbnails = MutableList<ByteArray?>(timestampsUs.size) { null }
        val completed = AtomicInteger(0)

        val jobs = timestampsUs.mapIndexed { index, timeUs ->
            async {
                val startTime = System.currentTimeMillis()
                var retriever: MediaMetadataRetriever? = null
                try {
                    retriever = MediaMetadataRetriever().apply {
                        setDataSource(tempVideoFile.absolutePath)
                    }

                    val bitmap =
                        retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                    if (bitmap != null) {
                        val resized =
                            resizeBitmapKeepingAspect(bitmap, outputWidth, outputHeight, boxFit)
                        val bytes = compressBitmap(resized, outputFormat)
                        thumbnails[index] = bytes
                        val duration = System.currentTimeMillis() - startTime
                        Log.d(
                            THUMBNAIL_TAG,
                            "✅ [$index]  Generated in $duration ms (${bytes.size} bytes)"
                        )
                    } else {
                        Log.w(THUMBNAIL_TAG, "[$index] ❌ Null frame at ${timeUs / 1000} ms")
                    }
                } catch (e: Exception) {
                    Log.e(THUMBNAIL_TAG, "[$index] ❌ Exception at ${timeUs / 1000} ms: ${e.message}")
                } finally {
                    retriever?.release()
                    val progress = completed.incrementAndGet().toDouble() / timestampsUs.size
                    onProgress(progress)
                }
            }
        }

        jobs.awaitAll()
        tempVideoFile.delete()
        thumbnails.filterNotNull()
    }

    private suspend fun getKeyFrames(
        videoBytes: ByteArray,
        extension: String,
        outputFormat: String,
        boxFit: String,
        outputWidth: Int,
        outputHeight: Int,
        maxOutputFrames: Int = 10,
        onProgress: (Double) -> Unit,
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        val tempVideoFile = writeBytesToTempFile(videoBytes, extension)
        val keyframeTimestamps =
            extractKeyframeTimestamps(tempVideoFile.absolutePath, maxOutputFrames)
        val thumbnails = MutableList<ByteArray?>(keyframeTimestamps.size) { null }
        val completed = AtomicInteger(0)

        val jobs = keyframeTimestamps.mapIndexed { index, timeUs ->
            async {
                val startTime = System.currentTimeMillis()
                var retriever: MediaMetadataRetriever? = null
                try {
                    retriever = MediaMetadataRetriever().apply {
                        setDataSource(tempVideoFile.absolutePath)
                    }

                    val bitmap =
                        retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    if (bitmap != null) {
                        val resized =
                            resizeBitmapKeepingAspect(bitmap, outputWidth, outputHeight, boxFit)
                        val bytes = compressBitmap(resized, outputFormat)
                        thumbnails[index] = bytes
                        val duration = System.currentTimeMillis() - startTime
                        Log.d(
                            THUMBNAIL_TAG,
                            "[$index] ✅ ${timeUs / 1000} ms in $duration ms (${bytes.size} bytes)"
                        )
                    } else {
                        Log.w(THUMBNAIL_TAG, "[$index] ❌ Null frame at ${timeUs / 1000} ms")
                    }
                } catch (e: Exception) {
                    Log.e(THUMBNAIL_TAG, "[$index] ❌ Exception at ${timeUs / 1000} ms: ${e.message}")
                } finally {
                    retriever?.release()
                    val progress = completed.incrementAndGet().toDouble() / keyframeTimestamps.size
                    onProgress(progress)
                }
            }
        }

        jobs.awaitAll()
        tempVideoFile.delete()
        thumbnails.filterNotNull()
    }


    private fun extractKeyframeTimestamps(videoPath: String, maxOutputFrames: Int): List<Long> {
        val extractor = MediaExtractor()
        val allKeyframes = mutableListOf<Long>()

        try {
            extractor.setDataSource(videoPath)
            val videoTrackIndex = (0 until extractor.trackCount).first {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)
                    ?.startsWith("video/") == true
            }
            extractor.selectTrack(videoTrackIndex)

            // Collect all sync (keyframe) sample times
            while (true) {
                val flags = extractor.sampleFlags
                if (flags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                    allKeyframes.add(extractor.sampleTime)
                }
                if (!extractor.advance()) break
            }
        } catch (e: Exception) {
            Log.e("KeyframeExtractor", "Error extracting keyframes: ${e.message}")
        } finally {
            extractor.release()
        }

        // If fewer keyframes than max, return them all
        if (allKeyframes.size <= maxOutputFrames) return allKeyframes

        // Sample evenly spaced keyframes
        val step = allKeyframes.size.toFloat() / maxOutputFrames
        return List(maxOutputFrames) { i ->
            allKeyframes[(i * step).toInt()]
        }
    }

    private fun resizeBitmapKeepingAspect(
        original: Bitmap,
        targetWidth: Int,
        targetHeight: Int,
        scaleType: String = "contain" // can be "contain" or "cover"
    ): Bitmap {
        val originalWidth = original.width
        val originalHeight = original.height
        val widthRatio = targetWidth.toFloat() / originalWidth
        val heightRatio = targetHeight.toFloat() / originalHeight

        val scale = when (scaleType.lowercase()) {
            "cover" -> maxOf(widthRatio, heightRatio)
            "contain" -> minOf(widthRatio, heightRatio)
            else -> throw IllegalArgumentException("scaleType must be 'cover' or 'contain'")
        }

        val resizedWidth = (originalWidth * scale).toInt()
        val resizedHeight = (originalHeight * scale).toInt()

        return Bitmap.createScaledBitmap(original, resizedWidth, resizedHeight, true)
    }

    private fun compressBitmap(bitmap: Bitmap, format: String): ByteArray {
        val stream = ByteArrayOutputStream()
        val compressFormat = when (format.lowercase()) {
            "png" -> Bitmap.CompressFormat.PNG
            "webp" -> Bitmap.CompressFormat.WEBP
            else -> Bitmap.CompressFormat.JPEG
        }
        bitmap.compress(compressFormat, 90, stream)
        return stream.toByteArray()
    }

    private fun writeBytesToTempFile(bytes: ByteArray, extension: String): File {
        val tempFile = File.createTempFile("video_temp", ".$extension", context.cacheDir)
        FileOutputStream(tempFile).use {
            it.write(bytes)
        }
        return tempFile
    }
}
