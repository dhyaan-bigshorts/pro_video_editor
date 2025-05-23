import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.ScaleAndRotateTransformation

@UnstableApi
fun applyScale(
    videoEffects: MutableList<Effect>, scaleX: Float?, scaleY: Float?,
) {
    if (scaleX == null && scaleY == null) return;

    Log.d(RENDER_TAG, "Applying scale: scaleX: $scaleX, scaleY: $scaleY")
    videoEffects += ScaleAndRotateTransformation.Builder()
        .setScale(scaleX ?: 1f, scaleY ?: 1f)
        .build()
}