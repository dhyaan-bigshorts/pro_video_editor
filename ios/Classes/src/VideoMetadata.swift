import Foundation
import AVFoundation

class VideoMetadata {

    static func processVideo(videoData: Data, ext: String) -> [String: Any] {
        guard let tempFileURL = createTempFile(videoData: videoData, ext: ext) else {
            return ["error": "Failed to create temp file"]
        }

        let asset = AVAsset(url: tempFileURL)

        // Get file size
        let fileSize: Int64
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: tempFileURL.path)
            fileSize = attr[.size] as? Int64 ?? 0
        } catch {
            return ["error": "Failed to get file size: \(error.localizedDescription)"]
        }

        // Get duration
        let duration = asset.duration
        let durationMs = CMTimeGetSeconds(duration) * 1000.0

        // Get dimensions
        var width = 0
        var height = 0
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            width = Int(abs(size.width))
            height = Int(abs(size.height))
        }

        return [
            "fileSize": fileSize,
            "duration": durationMs,
            "width": width,
            "height": height
        ]
    }

    private static func createTempFile(videoData: Data, ext: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("vid.\(ext)")
        do {
            try videoData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
