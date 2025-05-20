package ch.waio.pro_video_editor.src.features

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.SurfaceTexture
import android.media.*
import android.view.Surface
import androidx.media3.common.audio.SonicAudioProcessor
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.microedition.khronos.egl.EGL10
import javax.microedition.khronos.egl.EGLContext
import javax.microedition.khronos.egl.EGLDisplay
import javax.microedition.khronos.egl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLUtils
import javax.microedition.khronos.egl.*

import android.net.Uri
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.Crop
import androidx.media3.effect.RgbMatrix
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.ScaleAndRotateTransformation
import androidx.media3.effect.SpeedChangeEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.Effects
import com.google.common.collect.ImmutableList

@UnstableApi
class RenderVideo(private val context: Context) {
    fun render(
        videoBytes: ByteArray,
        imageBytes: ByteArray?,
        inputFormat: String,
        outputFormat: String,
        rotateTurns: Int?,
        flipX: Boolean = false,
        flipY: Boolean = false,
        cropWidth: Int?,
        cropHeight: Int?,
        cropX: Int?,
        cropY: Int?,
        scaleX: Float?,
        scaleY: Float?,
        enableAudio: Boolean = true,
        playbackSpeed: Float? = null,
        startUs: Long? = null,
        endUs: Long? = null,
        colorMatrixList: List<List<Double>>,
        onProgress: (Double) -> Unit,
        onComplete: (ByteArray?) -> Unit,
        onError: (Throwable) -> Unit
    ) {
        // Tag for logging
        val TAG = "RenderVideo"

        val inputFile =
            File(context.cacheDir, "video_input_${System.currentTimeMillis()}.$inputFormat").apply {
                writeBytes(videoBytes)
            }
        val outputFile =
            File(context.cacheDir, "video_output_${System.currentTimeMillis()}.$outputFormat")

        val rotationDegrees = (rotateTurns ?: 0) * 90f

        val videoEffects = mutableListOf<androidx.media3.common.Effect>()

        // Apply rotation
        if (rotationDegrees % 360f != 0f) {
            Log.d(TAG, "Applying rotation: $rotationDegrees degrees")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setRotationDegrees(rotationDegrees)
                .build()
        }

        // Apply flip
        if (flipX || flipY) {
            Log.d(TAG, "Applying flip - flipX: $flipX, flipY: $flipY")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setScale(if (flipX) -1f else 1f, if (flipY) -1f else 1f)
                .build()
        }

        // Apply crop
        if (cropX != null || cropY != null || cropWidth != null || cropHeight != null) {
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(inputFile.absolutePath)
                val videoWidth =
                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                        ?.toFloatOrNull()
                val videoHeight =
                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                        ?.toFloatOrNull()

                if (videoWidth != null && videoHeight != null && videoWidth > 0 && videoHeight > 0) {
                    // Default to full frame if values are not provided
                    val cropX = cropX ?: 0
                    val cropY = cropY ?: 0
                    val cropWidth = cropWidth ?: (videoWidth - cropX).toInt()
                    val cropHeight = cropHeight ?: (videoHeight - cropY).toInt()

                    // Convert to NDC
                    val leftNDC = (cropX / videoWidth) * 2f - 1f
                    val rightNDC = ((cropX + cropWidth) / videoWidth) * 2f - 1f
                    val topNDC = 1f - (cropY / videoHeight) * 2f
                    val bottomNDC = 1f - ((cropY + cropHeight) / videoHeight) * 2f

                    Log.d(
                        TAG,
                        "Applying crop - left=$leftNDC, right=$rightNDC, top=$topNDC, bottom=$bottomNDC"
                    )
                    videoEffects += Crop(leftNDC, rightNDC, bottomNDC, topNDC)
                } else {
                    Log.w(TAG, "Skipping crop: invalid video dimensions.")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to apply cropping: ${e.message}")
            } finally {
                retriever.release()
            }
        }

        // Apply scale
        if (scaleX != null || scaleY != null) {
            Log.d(TAG, "Applying scale - scaleX: $scaleX, scaleY: $scaleY")
            videoEffects += ScaleAndRotateTransformation.Builder()
                .setScale(scaleX ?: 1f, scaleY ?: 1f)
                .build()
        }

        // Build Clipping Configuration if trimming
        val mediaItemBuilder = MediaItem.Builder().setUri(Uri.fromFile(inputFile))
        if (startUs != null || endUs != null) {
            val startMs = (startUs ?: 0L) / 1000
            val endMs = endUs?.div(1000) ?: C.TIME_END_OF_SOURCE
            Log.d(TAG, "Applying trim: start=$startMs ms, end=$endMs ms")

            val clippingConfig = MediaItem.ClippingConfiguration.Builder()
                .setStartPositionMs(startMs)
                .setEndPositionMs(endMs)
                .build()

            mediaItemBuilder.setClippingConfiguration(clippingConfig)
        }

        /// Apply color matrix "Filters"
        for (matrix in colorMatrixList) {
            if (matrix.size == 16) {
                val matrixProvider = RgbMatrix { _: Long, _: Boolean ->
                    FloatArray(16) { i -> matrix[i].toFloat() }
                }
                videoEffects += matrixProvider
            } else {
                Log.w(TAG, "Skipped invalid color matrix: size=${matrix.size}")
            }
        }


        val mediaItem = mediaItemBuilder.build()

        val audioEffects = mutableListOf<AudioProcessor>()

        // Apply playback speed
        if (playbackSpeed != null && playbackSpeed > 0f) {
            Log.d(TAG, "Applying speed change: $playbackSpeed×")
            videoEffects += SpeedChangeEffect(playbackSpeed)

            val audio = SonicAudioProcessor()
            audio.setSpeed(playbackSpeed)

            audioEffects += audio
        }

        // Load and apply transparent image overlay
        if (imageBytes != null) {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(inputFile.absolutePath)
            val videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
            val videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
            retriever.release()

            val overlayBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val scaledOverlay = Bitmap.createScaledBitmap(overlayBitmap, videoWidth, videoHeight, true)

            val bitmapOverlay = BitmapOverlay.createStaticBitmapOverlay(scaledOverlay)
            val overlayEffect = OverlayEffect(ImmutableList.of(bitmapOverlay))

            videoEffects += overlayEffect
        }


        val effects = Effects(audioEffects, videoEffects)

        val editedMediaItemBuilder = EditedMediaItem.Builder(mediaItem)
            .setEffects(effects)

        // Remove Audio
        if (!enableAudio) {
            Log.d(TAG, "Removing audio from video")
            editedMediaItemBuilder.setRemoveAudio(true)
        }

        val editedMediaItem = editedMediaItemBuilder.build()

        val outputMimeType = mapFormatToMimeType(outputFormat)
        val transformer = Transformer.Builder(context)
            .setVideoMimeType(outputMimeType)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, result: ExportResult) {
                    try {
                        val resultBytes = outputFile.readBytes()
                        onComplete(resultBytes)
                    } catch (e: Exception) {
                        onError(e)
                    } finally {
                        inputFile.delete()
                        outputFile.delete()
                    }
                }

                override fun onError(
                    composition: Composition,
                    result: ExportResult,
                    exception: ExportException
                ) {
                    onError(exception)
                    inputFile.delete()
                    outputFile.delete()
                }
            })
            .build()

        // Start transformation
        transformer.start(editedMediaItem, outputFile.absolutePath)


        // Progress tracking setup
        val progressHolder = androidx.media3.transformer.ProgressHolder()
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

        mainHandler.post(object : Runnable {
            override fun run() {
                val progressState = transformer.getProgress(progressHolder)
                if (progressHolder.progress >= 0) {
                    onProgress(progressHolder.progress / 100.0)
                }

                // Continue polling if transformer started
                if (progressState != Transformer.PROGRESS_STATE_NOT_STARTED) {
                    mainHandler.postDelayed(this, 200)
                }
            }
        })
    }

    private fun mapFormatToMimeType(format: String): String {
        return when (format.lowercase()) {
            "mp4" -> MimeTypes.VIDEO_H264 // Codec for MP4
            "webm" -> MimeTypes.VIDEO_VP9 // Codec for WebM
            "h264" -> MimeTypes.VIDEO_H264
            "h265", "hevc" -> MimeTypes.VIDEO_H265
            "av1" -> MimeTypes.VIDEO_AV1
            else -> MimeTypes.VIDEO_MP4 // fallback default
        }
    }


    /* fun multiplyColorMatrices(m1: List<Double>, m2: List<Double>): List<Double> {
        val result = MutableList(20) { 0.0 }
        for (i in 0..3) {
            for (j in 0..4) {
                result[i * 5 + j] =
                    m1[i * 5 + 0] * m2[0 + j] +
                            m1[i * 5 + 1] * m2[5 + j] +
                            m1[i * 5 + 2] * m2[10 + j] +
                            m1[i * 5 + 3] * m2[15 + j] +
                            if (j == 4) m1[i * 5 + 4] else 0.0
            }
        }
        return result
    }

    fun combineColorMatrices(matrices: List<List<Double>>): List<Double> {
        if (matrices.isEmpty()) return listOf()
        var result = matrices[0]
        for (i in 1 until matrices.size) {
            result = multiplyColorMatrices(matrices[i], result)
        }
        return result
    }

    fun writeCubeLutFile(matrix: List<Double>, fileName: String): File {
        require(matrix.size == 20) { "Matrix must be 4x5 (20 elements)" }
        val file = File(context.filesDir, fileName)
        val builder = StringBuilder()
        val size = 33
        builder.appendLine("TITLE \"Flutter Matrix LUT\"")
        builder.appendLine("LUT_3D_SIZE $size")
        builder.appendLine("DOMAIN_MIN 0.0 0.0 0.0")
        builder.appendLine("DOMAIN_MAX 1.0 1.0 1.0")
        for (b in 0 until size) {
            for (g in 0 until size) {
                for (r in 0 until size) {
                    val rf = r / (size - 1).toDouble()
                    val gf = g / (size - 1).toDouble()
                    val bf = b / (size - 1).toDouble()
                    val rr =
                        (matrix[0] * rf + matrix[1] * gf + matrix[2] * bf + matrix[3] * 1.0) + (matrix[4] / 255.0)
                    val gg =
                        (matrix[5] * rf + matrix[6] * gf + matrix[7] * bf + matrix[8] * 1.0) + (matrix[9] / 255.0)
                    val bb =
                        (matrix[10] * rf + matrix[11] * gf + matrix[12] * bf + matrix[13] * 1.0) + (matrix[14] / 255.0)
                    builder.appendLine(
                        "${rr.coerceIn(0.0, 1.0)} ${
                            gg.coerceIn(
                                0.0,
                                1.0
                            )
                        } ${bb.coerceIn(0.0, 1.0)}"
                    )
                }
            }
        }
        file.writeText(builder.toString())
        return file
    } */


    /// TODO: remove fun
    /* fun generate(
        videoBytes: ByteArray,
        imageBytes: ByteArray,
        codecArgs: List<String>,
        inputFormat: String,
        outputFormat: String,
        startTime: Int?,
        endTime: Int?,
        videoDuration: Int,
        filters: String?,
        colorMatrices: List<List<Double>>?,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit,
        onProgress: ((Double) -> Unit)? = null
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val cache = context.cacheDir
                val inVideoF = File.createTempFile("inVid", ".${inputFormat}", cache)
                    .apply { writeBytes(videoBytes) }
                val inImageF =
                    File.createTempFile("inImg", ".png", cache).apply { writeBytes(imageBytes) }
                val outF = File.createTempFile("outVid", ".mp4", cache)

                val extractor = MediaExtractor().apply { setDataSource(inVideoF.absolutePath) }
                val videoTrack = (0 until extractor.trackCount)
                    .first {
                        extractor.getTrackFormat(it).getString(KEY_MIME)!!.startsWith("video/")
                    }
                val inputFmt = extractor.getTrackFormat(videoTrack)
                extractor.selectTrack(videoTrack)

                val decoder = MediaCodec.createDecoderByType(inputFmt.getString(KEY_MIME)!!)
                val renderSurfaceWrapper = CodecSurfaceWrapper()
                decoder.configure(inputFmt, renderSurfaceWrapper.surface, null, 0)
                decoder.start()

                val width = inputFmt.getInteger(KEY_WIDTH) and 0xFFFFFFFE.toInt()
                val height = inputFmt.getInteger(KEY_HEIGHT) and 0xFFFFFFFE.toInt()

                val encFormat = MediaFormat.createVideoFormat("video/avc", width, height).apply {
                    setInteger(KEY_BIT_RATE, 2_000_000)
                    setInteger(KEY_FRAME_RATE, 30)
                    setInteger(KEY_I_FRAME_INTERVAL, 1)
                    setInteger(KEY_COLOR_FORMAT, COLOR_FormatSurface)
                }
                val encoder = MediaCodec.createEncoderByType("video/avc")
                encoder.configure(encFormat, null, null, CONFIGURE_FLAG_ENCODE)
                val encoderInputSurface = encoder.createInputSurface()
                encoder.start()

                val muxer =
                    MediaMuxer(outF.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                var muxerTrackIndex = -1
                var muxerStarted = false

                val overlayBitmap = BitmapFactory.decodeFile(inImageF.absolutePath)
                val colorMatrix = colorMatrices?.let {
                    combineColorMatrices(it).map(Double::toFloat).toFloatArray()
                }
                val glRunnable = FrameFilterRunnable(
                    srcSurface = renderSurfaceWrapper.surface,
                    dstSurface = encoderInputSurface,
                    width = width,
                    height = height,
                    colorMatrix = colorMatrix,
                    extraFilterGLSL = filters,
                    overlayBitmap = overlayBitmap
                )

                // ✅ Delay before starting GL rendering to avoid Exynos encoder crash
                Thread.sleep(200)

                val glThread = Thread(glRunnable, "VideoFilterThread")
                glThread.start()

                val bufferInfo = BufferInfo()
                var sawEOS = false
                val startUs = (startTime?.times(1_000_000))?.toLong() ?: 0L
                val endUs = (endTime?.times(1_000_000))?.toLong() ?: Long.MAX_VALUE

                if (startUs > 0) extractor.seekTo(startUs, SEEK_TO_CLOSEST_SYNC)

                while (true) {
                    if (!sawEOS) {
                        val inBufIdx = decoder.dequeueInputBuffer(10_000)
                        if (inBufIdx >= 0) {
                            val inputBuf = decoder.getInputBuffer(inBufIdx)!!
                            val sampleSize = extractor.readSampleData(inputBuf, 0)
                            val videoTimeUs = extractor.sampleTime
                            if (sampleSize < 0 || videoTimeUs > endUs) {
                                decoder.queueInputBuffer(
                                    inBufIdx,
                                    0,
                                    0,
                                    0L,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                sawEOS = true
                            } else {
                                decoder.queueInputBuffer(
                                    inBufIdx,
                                    0,
                                    sampleSize,
                                    videoTimeUs,
                                    extractor.sampleFlags
                                )
                                extractor.advance()
                            }
                        }
                    }

                    val decOutIdx = decoder.dequeueOutputBuffer(bufferInfo, 10_000)
                    if (decOutIdx >= 0) {
                        renderSurfaceWrapper.signalFrameAvailable()
                        decoder.releaseOutputBuffer(decOutIdx, true)
                    }

                    val encOutIdx = encoder.dequeueOutputBuffer(bufferInfo, 10_000)
                    if (encOutIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        muxerTrackIndex = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    } else if (encOutIdx >= 0) {
                        val encoded = encoder.getOutputBuffer(encOutIdx)!!
                        if (bufferInfo.size > 0 && muxerStarted) {
                            encoded.position(bufferInfo.offset)
                            encoded.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(muxerTrackIndex, encoded, bufferInfo)
                        }
                        encoder.releaseOutputBuffer(encOutIdx, false)
                    }

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }

                    val currentTimeMs = bufferInfo.presentationTimeUs / 1000.0
                    val startOffsetMs = (startTime?.times(1000)?.toDouble() ?: 0.0)
                    val trimmedDurMs =
                        ((endTime ?: (videoDuration / 1000)) - (startTime ?: 0)) * 1000.0
                    val progress = (currentTimeMs - startOffsetMs) / trimmedDurMs
                    onProgress?.invoke(progress.coerceIn(0.0, 1.0))
                }

                glRunnable.stop()
                glThread.join()
                decoder.stop(); decoder.release()
                encoder.stop(); encoder.release()
                extractor.release()
                muxer.stop(); muxer.release()
                onSuccess(outF.absolutePath)
            } catch (e: Exception) {
                onError(e.message ?: "Unknown error in native pipeline")
            }
        }
    } */
}

class CodecSurfaceWrapper {
    private val textureId = IntArray(1)
    val surfaceTexture: SurfaceTexture
    val surface: Surface

    init {
        android.opengl.GLES20.glGenTextures(1, textureId, 0)
        surfaceTexture = SurfaceTexture(textureId[0])
        surface = Surface(surfaceTexture)
    }

    fun signalFrameAvailable() {
        surfaceTexture.updateTexImage()
    }

    fun release() {
        surface.release()
        surfaceTexture.release()
    }
}

class FrameFilterRunnable(
    val srcSurface: Surface,
    val dstSurface: Surface,
    val width: Int,
    val height: Int,
    val colorMatrix: FloatArray?,
    val extraFilterGLSL: String?,
    val overlayBitmap: Bitmap
) : Runnable {
    private var running = true

    override fun run() {
        val egl = EGLContextHelper()
        egl.initEGL(dstSurface)

        val shader = GLVideoShader(colorMatrix, extraFilterGLSL)
        shader.init(width, height)

        val textureId = shader.createOESTexture()
        val surfaceTexture = SurfaceTexture(textureId)
        surfaceTexture.setDefaultBufferSize(width, height)

        val overlayTextureId = shader.loadTexture(overlayBitmap)

        // Delay to ensure encoder is fully ready
        Thread.sleep(200)

        while (running) {
            // ✅ Ensure EGL is current
            egl.makeCurrent()

            surfaceTexture.updateTexImage()

            GLES20.glViewport(0, 0, width, height)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
            shader.drawFrame(textureId, overlayTextureId)

            egl.swapBuffers()
            Thread.sleep(16)
        }

        surfaceTexture.release()
        egl.release()
    }

    fun stop() {
        running = false
    }
}

class EGLContextHelper {
    private lateinit var egl: EGL10
    private lateinit var display: EGLDisplay
    private lateinit var context: EGLContext
    private lateinit var surface: EGLSurface

    fun makeCurrent() {
        egl.eglMakeCurrent(display, surface, surface, context)
    }

    fun initEGL(targetSurface: Surface) {
        egl = EGLContext.getEGL() as EGL10
        display = egl.eglGetDisplay(EGL10.EGL_DEFAULT_DISPLAY)
        egl.eglInitialize(display, null)

        val attribList = intArrayOf(
            EGL10.EGL_RED_SIZE, 8,
            EGL10.EGL_GREEN_SIZE, 8,
            EGL10.EGL_BLUE_SIZE, 8,
            EGL10.EGL_RENDERABLE_TYPE, 4,
            EGL10.EGL_NONE
        )

        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfig = IntArray(1)
        egl.eglChooseConfig(display, attribList, configs, 1, numConfig)

        context = egl.eglCreateContext(
            display,
            configs[0],
            EGL10.EGL_NO_CONTEXT,
            intArrayOf(0x3098, 2, EGL10.EGL_NONE)
        )
        surface = egl.eglCreateWindowSurface(display, configs[0], targetSurface, null)

        egl.eglMakeCurrent(display, surface, surface, context)
    }

    fun swapBuffers() {
        egl.eglSwapBuffers(display, surface)
    }

    fun release() {
        egl.eglMakeCurrent(
            display,
            EGL10.EGL_NO_SURFACE,
            EGL10.EGL_NO_SURFACE,
            EGL10.EGL_NO_CONTEXT
        )
        egl.eglDestroySurface(display, surface)
        egl.eglDestroyContext(display, context)
        egl.eglTerminate(display)
    }
}

class GLVideoShader(
    private val colorMatrix: FloatArray?,
    private val extraFilterGLSL: String?
) {
    private var program = 0
    private var positionHandle = 0
    private var texCoordHandle = 0
    private var textureHandle = 0

    fun init(width: Int, height: Int) {
        val vertexShader = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTexCoord;
            }
        """

        val fragmentShader = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            uniform samplerExternalOES uTexture;
            varying vec2 vTexCoord;
            void main() {
                vec4 color = texture2D(uTexture, vTexCoord);
                gl_FragColor = color;
            }
        """

        program = createProgram(vertexShader, fragmentShader)
        GLES20.glUseProgram(program)

        positionHandle = GLES20.glGetAttribLocation(program, "aPosition")
        texCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord")
        textureHandle = GLES20.glGetUniformLocation(program, "uTexture")
    }

    fun drawFrame(textureId: Int, overlayTexId: Int) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        GLES20.glUseProgram(program)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(textureHandle, 0)

        drawQuad()
    }

    fun createOESTexture(): Int {
        val tex = IntArray(1)
        GLES20.glGenTextures(1, tex, 0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, tex[0])
        GLES20.glTexParameterf(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_NEAREST.toFloat()
        )
        GLES20.glTexParameterf(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR.toFloat()
        )
        return tex[0]
    }

    fun loadTexture(bitmap: Bitmap): Int {
        val tex = IntArray(1)
        GLES20.glGenTextures(1, tex, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex[0])
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        return tex[0]
    }

    private fun drawQuad() {
        val triangleVertices = floatArrayOf(
            -1f, -1f, 0f, 1f,
            1f, -1f, 1f, 1f,
            -1f, 1f, 0f, 0f,
            1f, 1f, 1f, 0f
        )

        val buffer = ByteBuffer.allocateDirect(triangleVertices.size * 4)
            .order(ByteOrder.nativeOrder()).asFloatBuffer()
        buffer.put(triangleVertices).position(0)

        buffer.position(0)
        GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 16, buffer)
        GLES20.glEnableVertexAttribArray(positionHandle)

        buffer.position(2)
        GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 16, buffer)
        GLES20.glEnableVertexAttribArray(texCoordHandle)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
    }

    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        return program
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        return shader
    }
}
