import Foundation

class ThumbnailGenerator {

    static func generateThumbnails(
        videoBytes: Data,
        timestamps: [Double],
        thumbnailFormat: String,
        extension ext: String,
        width: NSNumber,
        completion: @escaping ([Data]) -> Void
    ) {
        /* DispatchQueue.global(qos: .userInitiated).async {
            let tempVideoURL = writeBytesToTempFile(videoBytes, ext: ext)
            var thumbnails: [Data?] = Array(repeating: nil, count: timestamps.count)
            let group = DispatchGroup()

            for (index, time) in timestamps.enumerated() {
                group.enter()
                let timestampStr = String(format: "%.3f", time / 1000.0)
                let imageFileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("thumb_\(index).\(thumbnailFormat)")

                let command =
                    "-y -ss \(timestampStr) -i \(tempVideoURL.path) -vframes 1 -vf scale=\(width):-2 \(imageFileURL.path)"

                let startTime = Date().timeIntervalSince1970

                FFmpegKit.executeAsync(command) { session in
                    let duration = Int((Date().timeIntervalSince1970 - startTime) * 1000)
                    if let returnCode = session?.getReturnCode(), ReturnCode.isSuccess(returnCode) {
                        if let imageData = try? Data(contentsOf: imageFileURL) {
                            thumbnails[index] = imageData
                            print("[\(index)] ✅ \(timestampStr)s in \(duration)ms (\(imageData.count) bytes)")
                        }
                    } else {
                        print("[\(index)] ❌ Failed at \(timestampStr)s in \(duration)ms")
                    }

                    try? FileManager.default.removeItem(at: imageFileURL)
                    group.leave()
                }
            }

            group.wait()
            try? FileManager.default.removeItem(at: tempVideoURL)

            DispatchQueue.main.async {
                completion(thumbnails.compactMap { $0 })
            }
        } */
    }

    private static func writeBytesToTempFile(_ bytes: Data, ext: String) -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("video_temp.\(ext)")
        try? bytes.write(to: fileURL)
        return fileURL
    }
}
