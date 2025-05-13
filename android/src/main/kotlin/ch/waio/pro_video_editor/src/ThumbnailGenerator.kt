package ch.waio.pro_video_editor.src

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.util.Log
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class ThumbnailGenerator(private val context: Context) {

    suspend fun generateThumbnails(
        videoBytes: ByteArray,
        thumbnailFormat: String,
        extension: String,
        width: Int,
        maxThumbnails: Int = 10
    ): List<ByteArray> = withContext(Dispatchers.IO) {
        val TAG = "KeyframeThumbnailGen"
        val tempVideoFile = writeBytesToTempFile(videoBytes, extension)
        val keyframeTimestamps = extractKeyframeTimestamps(tempVideoFile.absolutePath, maxThumbnails)
        val thumbnails = MutableList<ByteArray?>(keyframeTimestamps.size) { null }

        val jobs = keyframeTimestamps.mapIndexed { index, timeUs ->
            async {
                val startTime = System.currentTimeMillis()
                var retriever: MediaMetadataRetriever? = null
                try {
                    retriever = MediaMetadataRetriever().apply {
                        setDataSource(tempVideoFile.absolutePath)
                    }

                    val bitmap = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    if (bitmap != null) {
                        val resized = resizeBitmapKeepingAspect(bitmap, width)
                        val bytes = compressBitmap(resized, thumbnailFormat)
                        thumbnails[index] = bytes
                        val duration = System.currentTimeMillis() - startTime
                        Log.d(TAG, "[$index] ✅ ${timeUs / 1000} ms in $duration ms (${bytes.size} bytes)")
                    } else {
                        Log.w(TAG, "[$index] ❌ Null frame at ${timeUs / 1000} ms")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "[$index] ❌ Exception at ${timeUs / 1000} ms: ${e.message}")
                } finally {
                    retriever?.release()
                }
            }
        }

        jobs.awaitAll()
        tempVideoFile.delete()
        return@withContext thumbnails.filterNotNull()
    }

    private fun extractKeyframeTimestamps(videoPath: String, maxThumbnails: Int): List<Long> {
        val extractor = MediaExtractor()
        val keyframes = mutableListOf<Long>()

        try {
            extractor.setDataSource(videoPath)
            val videoTrackIndex = (0 until extractor.trackCount).first {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true
            }
            extractor.selectTrack(videoTrackIndex)

            while (keyframes.size < maxThumbnails) {
                val flags = extractor.sampleFlags
                if (flags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                    keyframes.add(extractor.sampleTime)
                }
                if (!extractor.advance()) break
            }
        } catch (e: Exception) {
            Log.e("KeyframeExtractor", "Error extracting keyframes: ${e.message}")
        } finally {
            extractor.release()
        }

        return keyframes
    }

    private fun resizeBitmapKeepingAspect(original: Bitmap, targetWidth: Int): Bitmap {
        val aspectRatio = original.height.toFloat() / original.width
        val targetHeight = (targetWidth * aspectRatio).toInt()
        return Bitmap.createScaledBitmap(original, targetWidth, targetHeight, true)
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
