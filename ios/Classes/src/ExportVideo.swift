import Foundation

class ExportVideo {

    static func multiplyColorMatrices(_ m1: [Double], _ m2: [Double]) -> [Double] {
        var result = [Double](repeating: 0.0, count: 20)
        for i in 0...3 {
            for j in 0...4 {
                result[i * 5 + j] =
                    m1[i * 5 + 0] * m2[0 + j] +
                    m1[i * 5 + 1] * m2[5 + j] +
                    m1[i * 5 + 2] * m2[10 + j] +
                    m1[i * 5 + 3] * m2[15 + j] +
                    (j == 4 ? m1[i * 5 + 4] : 0.0)
            }
        }
        return result
    }

    static func combineColorMatrices(_ matrices: [[Double]]) -> [Double] {
        guard !matrices.isEmpty else { return [] }
        return matrices.dropFirst().reduce(matrices[0]) { acc, next in
            multiplyColorMatrices(next, acc)
        }
    }

    static func writeCubeLutFile(matrix: [Double], fileName: String) throws -> URL {
        precondition(matrix.count == 20, "Matrix must be 4x5")

        let size = 33
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        var content = """
        TITLE "Flutter Matrix LUT"
        LUT_3D_SIZE \(size)
        DOMAIN_MIN 0.0 0.0 0.0
        DOMAIN_MAX 1.0 1.0 1.0

        """

        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rf = Double(r) / Double(size - 1)
                    let gf = Double(g) / Double(size - 1)
                    let bf = Double(b) / Double(size - 1)

                    let rr = (matrix[0]*rf + matrix[1]*gf + matrix[2]*bf + matrix[3]*1.0) + matrix[4]/255.0
                    let gg = (matrix[5]*rf + matrix[6]*gf + matrix[7]*bf + matrix[8]*1.0) + matrix[9]/255.0
                    let bb = (matrix[10]*rf + matrix[11]*gf + matrix[12]*bf + matrix[13]*1.0) + matrix[14]/255.0

                    content += "\(min(max(rr, 0.0), 1.0)) \(min(max(gg, 0.0), 1.0)) \(min(max(bb, 0.0), 1.0))\n"
                }
            }
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func generate(
        videoBytes: Data,
        imageBytes: Data,
        codecArgs: [String],
        inputFormat: String,
        outputFormat: String,
        startTime: Int?,
        endTime: Int?,
        videoDuration: Int,
        filters: String,
        colorMatrices: [[Double]]?,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onProgress: ((Double) -> Void)? = nil
    ) {
        /* DispatchQueue.global(qos: .userInitiated).async {
            do {
                let tempDir = FileManager.default.temporaryDirectory

                let videoURL = tempDir.appendingPathComponent("input_video.\(inputFormat)")
                let imageURL = tempDir.appendingPathComponent("overlay_image.png")
                let outputURL = tempDir.appendingPathComponent("output_video.\(outputFormat)")

                try videoBytes.write(to: videoURL)
                try imageBytes.write(to: imageURL)

                // LUT file generation if needed
                var lutFilter: String? = nil
                if let matrices = colorMatrices, !matrices.isEmpty {
                    let combined = combineColorMatrices(matrices)
                    let lutURL = try writeCubeLutFile(matrix: combined, fileName: "flutter_matrix.cube")
                    lutFilter = "lut3d='\(lutURL.path)'"
                }

                // Build filter string
                var filterGraph = "[0:v]format=rgb24"
                if let lut = lutFilter {
                    filterGraph += ",\(lut)"
                }
                if !filters.isEmpty {
                    filterGraph += ",\(filters)"
                }
                filterGraph += "[vid];"
                filterGraph += "[1:v][vid]scale2ref=w=iw:h=ih[ovr][base];"
                filterGraph += "[base][ovr]overlay=0:0"

                var ffmpegCommand: [String] = []

                if let start = startTime {
                    ffmpegCommand += ["-ss", "\(start)"]
                }

                if let end = endTime {
                    ffmpegCommand += ["-to", "\(end)"]
                }

                ffmpegCommand += [
                    "-y",
                    "-i", videoURL.path,
                    "-i", imageURL.path,
                    "-filter_complex", filterGraph,
                ]

                // Append codec arguments from Dart or predefined
                ffmpegCommand += codecArgs
                
                // Append output file path
                ffmpegCommand.append(outputURL.path)

                let command = ffmpegCommand.joined(separator: " ")
                print("FFmpeg command: \(command)")

                FFmpegKit.executeAsync(command, withCompleteCallback: { session in
                    let returnCode = session?.getReturnCode()
                    if ReturnCode.isSuccess(returnCode) {
                        DispatchQueue.main.async {
                            onSuccess(outputURL.path)
                        }
                    } else {
                        let failMessage = session?.getFailStackTrace() ?? "Unknown error"
                        DispatchQueue.main.async {
                            onError("FFmpeg failed: \(failMessage)")
                        }
                    }
                }, withLogCallback: { log in
                    if let logMessage = log?.getMessage() {
                        print(logMessage)
                    }
                }, withStatisticsCallback: { stat in
                    guard let time = stat?.getTime() else { return }
                    let trimmedDuration: Int = {
                        if let start = startTime, let end = endTime {
                            return max((end - start) * 1000, 1)
                        } else if let start = startTime {
                            return videoDuration - start * 1000
                        } else if let end = endTime {
                            return end * 1000
                        } else {
                            return videoDuration
                        }
                    }()

                    if trimmedDuration > 0 && time > 0 {
                        let progress = Double(time) / Double(trimmedDuration)
                        DispatchQueue.main.async {
                            onProgress?(min(max(progress, 0.0), 1.0))
                        }
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    onError("Exception: \(error.localizedDescription)")
                }
            }
        } */
    }
}
