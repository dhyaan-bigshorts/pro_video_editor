import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import ch.waio.pro_video_editor.src.features.render.utils.getRotatedVideoDimensions
import com.google.common.collect.ImmutableList
import java.io.File


@UnstableApi
fun applyImageLayer(
    videoEffects: MutableList<Effect>,
    inputFile: File,
    imageBytes: ByteArray?,
    rotationDegrees: Float,
    cropWidth: Int?,
    cropHeight: Int?,
    scaleX: Float?,
    scaleY: Float?,
) {
    if (imageBytes == null) return;

    var (videoWidth, videoHeight, videoRotation) = getRotatedVideoDimensions(
        inputFile,
        rotationDegrees
    )

    if (cropWidth != null) videoWidth = cropWidth;
    if (cropHeight != null) videoHeight = cropHeight;

    if (scaleX != null) videoWidth = (videoWidth * scaleX).toInt()
    if (scaleY != null) videoHeight = (videoHeight * scaleY).toInt()

    Log.d(RENDER_TAG, "Applying Image-Layer: Size $videoWidth x $videoHeight")

    val overlayBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    val scaledOverlay =
        Bitmap.createScaledBitmap(overlayBitmap, videoWidth, videoHeight, true)

    val bitmapOverlay = BitmapOverlay.createStaticBitmapOverlay(scaledOverlay)
    val overlayEffect = OverlayEffect(ImmutableList.of(bitmapOverlay))

    videoEffects += overlayEffect
}

