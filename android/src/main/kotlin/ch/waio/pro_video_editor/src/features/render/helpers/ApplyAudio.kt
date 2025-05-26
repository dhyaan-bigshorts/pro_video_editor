import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.EditedMediaItem


@UnstableApi
fun applyAudio(
    editedMediaItemBuilder: EditedMediaItem.Builder,
    enableAudio: Boolean?
) {
    // Remove Audio
    if (enableAudio == false) {
        Log.d(RENDER_TAG, "Removing audio from video")
        editedMediaItemBuilder.setRemoveAudio(true)
    }
}
