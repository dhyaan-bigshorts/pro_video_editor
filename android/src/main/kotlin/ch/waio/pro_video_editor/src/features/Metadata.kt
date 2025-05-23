package ch.waio.pro_video_editor.src.features

import android.content.Context
import android.media.MediaMetadataRetriever
import android.os.Environment
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class Metadata(private val context: Context) {

    fun processVideo(videoData: ByteArray, extension: String): Map<String, Any> {
        val tempFile = createTempFile(videoData, extension)
            ?: return mapOf("error" to "Failed to create temp file")

        val fileSize = tempFile.length()
        val metadataRetriever = MediaMetadataRetriever()

        var durationMs = 0.0
        var width = 0
        var height = 0
        var rotation = 0
        var mimeType = "unknown"

        try {
            metadataRetriever.setDataSource(tempFile.absolutePath)

            mimeType = metadataRetriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_MIMETYPE
            ) ?: "unknown"

            val durationStr = metadataRetriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )
            val widthStr = metadataRetriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
            )
            val heightStr = metadataRetriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
            )
            val rotationStr = metadataRetriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
            )

            durationMs = durationStr?.toDoubleOrNull() ?: 0.0
            width = widthStr?.toIntOrNull() ?: 0
            height = heightStr?.toIntOrNull() ?: 0
            rotation = rotationStr?.toIntOrNull() ?: 0

        } catch (e: Exception) {
            return mapOf("error" to "Failed to retrieve metadata: ${e.message}")
        } finally {
            metadataRetriever.release()
        }

        return mapOf(
            "fileSize" to fileSize,
            "duration" to durationMs,
            "width" to width,
            "height" to height,
            "rotation" to rotation
        )
    }

    private fun createTempFile(videoData: ByteArray, extension: String): File? {
        return try {
            val tempDir = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)
            val tempFile = File.createTempFile("vid", ".$extension", tempDir)
            FileOutputStream(tempFile).use { it.write(videoData) }
            tempFile
        } catch (e: IOException) {
            null
        }
    }
}
