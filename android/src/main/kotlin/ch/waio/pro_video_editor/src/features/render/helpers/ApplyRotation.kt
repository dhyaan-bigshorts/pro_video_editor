import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.ScaleAndRotateTransformation

@UnstableApi
fun applyRotation(videoEffects: MutableList<Effect>, rotationDegrees: Float) {
    if (rotationDegrees % 360f == 0f) return;

    Log.d(RENDER_TAG, "Applying rotation: $rotationDegrees degrees")
    videoEffects += ScaleAndRotateTransformation.Builder()
        .setRotationDegrees(rotationDegrees)
        .build()
}
