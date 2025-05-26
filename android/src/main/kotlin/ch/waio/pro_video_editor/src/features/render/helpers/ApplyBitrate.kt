import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.VideoEncoderSettings


@UnstableApi
fun applyBitrate(
    encoderFactoryBuilder: DefaultEncoderFactory.Builder,
    mimeType: String?,
    bitrate: Int?
) {
    if (bitrate == null) return
    Log.d(RENDER_TAG, "Requested Bitrate: $bitrate")

    val codecInfo = MediaCodecList(MediaCodecList.ALL_CODECS)
        .codecInfos
        .firstOrNull { it.isEncoder && it.supportedTypes.contains(mimeType) }

    if (codecInfo == null) {
        Log.e(RENDER_TAG, "No encoder found for $mimeType")
        return
    }

    val capabilities = codecInfo.getCapabilitiesForType(mimeType)
    val bitrateRange = capabilities.videoCapabilities.bitrateRange
    val supportsCBR = capabilities.encoderCapabilities
        .isBitrateModeSupported(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR)

    if (!bitrateRange.contains(bitrate)) {
        Log.e(RENDER_TAG, "Bitrate $bitrate not in supported range: $bitrateRange")
        return
    }

    val bitrateMode = if (supportsCBR) {
        Log.d(RENDER_TAG, "CBR supported, applying CBR mode")
        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR
    } else {
        Log.w(RENDER_TAG, "CBR not supported, falling back to VBR")
        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR
    }

    val builder = VideoEncoderSettings.Builder()
        .setBitrateMode(bitrateMode)
        .setBitrate(bitrate)

    encoderFactoryBuilder.setRequestedVideoEncoderSettings(builder.build())
}
