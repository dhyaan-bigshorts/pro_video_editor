import AVFoundation
import Foundation

class VideoMetadata {

    static func processVideo(videoData: Data, ext: String) async throws -> [String: Any] {
        guard let tempFileURL = createTempFile(videoData: videoData, ext: ext) else {
            return ["error": "Failed to create temp file"]
        }

        let asset = AVURLAsset(url: tempFileURL)

        // File size
        let fileSize: Int64
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: tempFileURL.path)
            fileSize = attr[.size] as? Int64 ?? 0
        } catch {
            return ["error": "Failed to get file size: \(error.localizedDescription)"]
        }

        // Duration
        let duration: CMTime
        if #available(iOS 15.0, *) {
            duration = try await asset.load(.duration)
        } else {
            duration = asset.duration
        }
        let durationMs = CMTimeGetSeconds(duration) * 1000.0

        // Video track info
        var width = 0
        var height = 0
        var rotation = 0
        var bitrate = 0

        if durationMs > 0 {
            let fileSizeBits = fileSize * 8
            bitrate = Int(Double(fileSizeBits) * 1000 / durationMs)
        }

        if #available(iOS 15.0, *) {
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            if let track = videoTracks.first {
                let size = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)
                let transformedSize = size.applying(transform)
                width = Int(abs(transformedSize.width))
                height = Int(abs(transformedSize.height))

                let angle = atan2(transform.b, transform.a)
                rotation = (Int(round(angle * 180 / .pi)) + 360) % 360
            }
        } else {
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                width = Int(abs(size.width))
                height = Int(abs(size.height))

                let angle = atan2(track.preferredTransform.b, track.preferredTransform.a)
                rotation = (Int(round(angle * 180 / .pi)) + 360) % 360
            }
        }

        // Metadata
        let title: String
        let artist: String
        let author: String
        let album: String
        let albumArtist: String

        if #available(iOS 15.0, *) {
            let metadata = try await asset.load(.commonMetadata)
            title = try await loadMetadataString(from: metadata, key: "title")
            artist = try await loadMetadataString(from: metadata, key: "artist")
            author = try await loadMetadataString(from: metadata, key: "author")
            album = try await loadMetadataString(from: metadata, key: "albumName")
            albumArtist = try await loadMetadataString(from: metadata, key: "albumArtist")
        } else {
            let metadata = asset.commonMetadata
            title = metadata.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue ?? ""
            artist =
                metadata.first(where: { $0.commonKey?.rawValue == "artist" })?.stringValue ?? ""
            author =
                metadata.first(where: { $0.commonKey?.rawValue == "author" })?.stringValue ?? ""
            album =
                metadata.first(where: { $0.commonKey?.rawValue == "albumName" })?.stringValue ?? ""
            albumArtist =
                metadata.first(where: { $0.commonKey?.rawValue == "albumArtist" })?.stringValue
                ?? ""
        }

        // Creation date
        var dateStr = ""
        if #available(iOS 15.0, *) {
            if let creationItem = try await asset.load(.creationDate) {
                if let creationDate = try? await creationItem.load(.dateValue) {
                    dateStr = ISO8601DateFormatter().string(from: creationDate)
                }
            }
        }
        if dateStr.isEmpty {
            if let attr = try? FileManager.default.attributesOfItem(atPath: tempFileURL.path),
                let fileCreationDate = attr[.creationDate] as? Date
            {
                dateStr = ISO8601DateFormatter().string(from: fileCreationDate)
            }
        }

        return [
            "fileSize": fileSize,
            "duration": durationMs,
            "width": width,
            "height": height,
            "rotation": rotation,
            "bitrate": bitrate,
            "title": title,
            "artist": artist,
            "author": author,
            "album": album,
            "albumArtist": albumArtist,
            "date": dateStr,
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

    @available(iOS 15.0, *)
    private static func loadMetadataString(from metadata: [AVMetadataItem], key: String)
        async throws -> String
    {
        if let item = metadata.first(where: { $0.commonKey?.rawValue == key }) {
            return try await item.load(.stringValue) ?? ""
        }
        return ""
    }
}
