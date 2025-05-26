import AVFoundation

public func applyPlaybackSpeed(
    composition: AVMutableComposition,
    speed: Float?
) {
    guard let speed = speed, speed > 0, speed != 1 else { return }

    print("[\(Tags.render)] Applying playback speed: \(speed)x")

    let tracks = composition.tracks
    for track in tracks {
        let range = CMTimeRange(start: .zero, duration: track.timeRange.duration)
        let scaledDuration = CMTimeMultiplyByFloat64(range.duration, multiplier: 1 / Double(speed))
        track.scaleTimeRange(range, toDuration: scaledDuration)
    }
}
