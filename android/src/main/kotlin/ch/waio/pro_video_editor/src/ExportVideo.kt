package ch.waio.pro_video_editor.src

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.*

class ExportVideo(private val context: Context) {

    fun multiplyColorMatrices(m1: List<Double>, m2: List<Double>): List<Double> {
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
            result = multiplyColorMatrices(matrices[i], result) // Multiply subsequent matrices on the left
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
    
        // Loop order changed to B, G, R (outer to inner)
        for (b in 0 until size) {
            for (g in 0 until size) {
                for (r in 0 until size) {
                    val rf = r / (size - 1).toDouble()
                    val gf = g / (size - 1).toDouble()
                    val bf = b / (size - 1).toDouble()
    
                    // Include alpha terms (matrix[3], matrix[8], matrix[13])
                    val rr = (matrix[0] * rf + matrix[1] * gf + matrix[2] * bf + matrix[3] * 1.0) + (matrix[4] / 255.0)
                    val gg = (matrix[5] * rf + matrix[6] * gf + matrix[7] * bf + matrix[8] * 1.0) + (matrix[9] / 255.0)
                    val bb = (matrix[10] * rf + matrix[11] * gf + matrix[12] * bf + matrix[13] * 1.0) + (matrix[14] / 255.0)
    
                    builder.appendLine("${rr.coerceIn(0.0, 1.0)} ${gg.coerceIn(0.0, 1.0)} ${bb.coerceIn(0.0, 1.0)}")
                }
            }
        }
    
        file.writeText(builder.toString())
        return file
    }
    

    fun generate(
        videoBytes: ByteArray,
        imageBytes: ByteArray,
        codecArgs: List<String>,
        inputFormat: String,
        outputFormat: String,
        startTime: Int?,
        endTime: Int?,
        videoDuration: Int,
        filters: String,
        colorMatrices: List<List<Double>>?,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit,
        onProgress: ((Double) -> Unit)? = null
    ) {
        /* CoroutineScope(Dispatchers.IO).launch {
            try {
                val videoFile = File.createTempFile("input_video", ".$inputFormat", context.cacheDir)
                val imageFile = File.createTempFile("overlay_image", ".png", context.cacheDir)
                val outputFile =
                    File.createTempFile("output_video", ".$outputFormat", context.cacheDir)

                videoFile.writeBytes(videoBytes)
                imageFile.writeBytes(imageBytes)

                val lutFilter = if (!colorMatrices.isNullOrEmpty()) {
                    val combined = combineColorMatrices(colorMatrices)
                    val lutFile = writeCubeLutFile(combined, "flutter_matrix.cube")
                    "lut3d='${lutFile.absolutePath}'"
                } else null

                // Color filter logic
                val filterGraph = StringBuilder()

                // Start by converting to RGB24 to match Flutter's color processing
                filterGraph.append("[0:v]format=rgb24")
                
                // Apply filters and LUT if present
                if (lutFilter != null) {
                    filterGraph.append(",$lutFilter")
                }
                if (!filters.isNullOrBlank()) {
                    filterGraph.append(",$filters")
                }
                
                filterGraph.append("[vid];")
                
                // Overlay setup
                filterGraph.append("[1:v][vid]scale2ref=w=iw:h=ih[ovr][base];")
                filterGraph.append("[base][ovr]overlay=0:0")
                
                val fullFilter = filterGraph.toString()

                val ffmpegCommand = mutableListOf<String>()

                // Add start and end only if provided
                startTime?.let {
                    // Trim start time (in seconds or HH:MM:SS)
                    ffmpegCommand.addAll(listOf("-ss", it.toString()))
                }

                endTime?.let {
                    // Trim end time (in seconds or HH:MM:SS)
                    ffmpegCommand.addAll(listOf("-to", it.toString()))
                }

                ffmpegCommand.addAll(
                    listOf(
                        // Overwrite output file if it exists
                        "-y",
                        // Input 0: the main video
                        "-i", videoFile.absolutePath,
                        // Input 1: the overlay image (e.g. a transparent PNG)
                        "-i", imageFile.absolutePath,
                        // Apply filter chain
                        "-filter_complex", fullFilter,
                    ) + codecArgs + listOf(
                        outputFile.absolutePath
                    )
                )

                val commandString = ffmpegCommand.joinToString(" ")

                Log.d("ExportVideo", "Running FFmpeg command: $commandString")

                FFmpegKit.executeAsync(commandString, { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        Handler(Looper.getMainLooper()).post {
                            onSuccess(outputFile.absolutePath)
                        }
                    } else {
                        val failReason = session.failStackTrace ?: "Unknown error"
                        Handler(Looper.getMainLooper()).post {
                            onError("FFmpeg failed: $failReason")
                        }
                    }
                }, { log ->
                    Log.d("ExportVideo", log.message)
                }, { stat ->
                    val trimmedDuration = if (startTime != null && endTime != null) {
                        ((endTime - startTime) * 1000).coerceAtLeast(1)
                    } else if (startTime != null) {
                        videoDuration - startTime * 1000
                    } else if (endTime != null) {
                        endTime * 1000
                    } else {
                        videoDuration
                    }
                    
                    val time = stat.time
                    if (trimmedDuration > 0 && time > 0) {
                        val progress = time.toDouble() / trimmedDuration.toDouble()
                        Handler(Looper.getMainLooper()).post {
                            onProgress?.invoke(progress.coerceIn(0.0, 1.0))
                        }
                    }
                })
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    onError("Exception: ${e.message}")
                }
            }
        } */
    }
}
