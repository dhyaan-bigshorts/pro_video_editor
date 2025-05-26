import AVFoundation
import Foundation

public func applyAudio(
    from asset: AVAsset,
    to composition: AVMutableComposition,
    timeRange: CMTimeRange,
    enableAudio: Bool
) async {
    guard enableAudio else {
        print("[\(Tags.render)] 🔇 Removing audio from export")
        return
    }

    do {
        let audioTracks: [AVAssetTrack]
        if #available(macOS 13.0, *) {
            audioTracks = try await asset.loadTracks(withMediaType: .audio)
        } else {
            audioTracks = asset.tracks(withMediaType: .audio)
        }

        if let audioTrack = audioTracks.first {
            if let audioCompositionTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try? audioCompositionTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
        }
    } catch {
        print("[\(Tags.render)] ⚠️ Failed to load audio tracks: \(error.localizedDescription)")
    }
}
