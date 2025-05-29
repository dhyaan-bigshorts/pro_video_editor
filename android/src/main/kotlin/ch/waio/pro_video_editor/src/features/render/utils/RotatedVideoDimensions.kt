package ch.waio.pro_video_editor.src.features.render.utils

import android.media.MediaMetadataRetriever
import java.io.File

fun getRotatedVideoDimensions(
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

        Triple(width, height, normalizedRotation)
    } catch (e: Exception) {
        Triple(0, 0, 0)
    } finally {
        retriever.release()
    }
}
