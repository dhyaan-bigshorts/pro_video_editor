import AVFoundation

public func applyTrim(
    asset: AVAsset,
    startUs: Int64?,
    endUs: Int64?
) async -> CMTimeRange {
    let duration: CMTime
    if #available(macOS 13.0, *) {
        do {
            duration = try await asset.load(.duration)
        } catch {
            return CMTimeRange(start: .zero, duration: .positiveInfinity)
        }
    } else {
        duration = asset.duration
    }

    if let startUs = startUs, let endUs = endUs {
        let start = CMTime(value: startUs, timescale: 1_000_000)
        let end = CMTime(value: endUs, timescale: 1_000_000)
        return CMTimeRange(start: start, end: end)
    } else {
        return CMTimeRange(start: .zero, duration: duration)
    }
}
