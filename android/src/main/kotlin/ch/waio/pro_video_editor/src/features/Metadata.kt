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
        val retriever = MediaMetadataRetriever()

        var durationMs = 0.0
        var width = 0
        var height = 0
        var rotation = 0
        var bitrate = 0
        var title = ""
        var artist = ""
        var author = ""
        var album = ""
        var albumArtist = ""
        var date = ""

        try {
            retriever.setDataSource(tempFile.absolutePath)

            val durationStr =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val widthStr =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            val heightStr =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            val rotationStr =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
            val bitrateStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)

            durationMs = durationStr?.toDoubleOrNull() ?: 0.0
            width = widthStr?.toIntOrNull() ?: 0
            height = heightStr?.toIntOrNull() ?: 0
            rotation = rotationStr?.toIntOrNull() ?: 0
            bitrate = bitrateStr?.toIntOrNull() ?: 0

            title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE) ?: ""
            artist =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: ""
            author = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_AUTHOR) ?: ""
            album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM) ?: ""
            albumArtist =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST) ?: ""
            date = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE) ?: ""


        } catch (e: Exception) {
            return mapOf("error" to "Failed to retrieve metadata: ${e.message}")
        } finally {
            retriever.release()
        }

        return mapOf(
            "fileSize" to fileSize,
            "duration" to durationMs,
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "bitrate" to bitrate,
            "title" to title,
            "artist" to artist,
            "author" to author,
            "album" to album,
            "albumArtist" to albumArtist,
            "date" to date,
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
