import AVFoundation

public func applyTrim(
    asset: AVAsset,
    startUs: Int64?,
    endUs: Int64?
) async -> CMTimeRange {
    // Load duration
    let duration: CMTime
    if #available(iOS 15.0, *) {
        do {
            duration = try await asset.load(.duration)
        } catch {
            return CMTimeRange(start: .zero, duration: .positiveInfinity)
        }
    } else {
        duration = asset.duration
    }

    // Prepare start and end CMTime
    let start = startUs != nil
        ? CMTime(value: startUs!, timescale: 1_000_000)
        : .zero

    let end = endUs != nil
        ? CMTime(value: endUs!, timescale: 1_000_000)
        : duration

    // Logging in ms for easier debugging
    let startMs = Int64(start.seconds * 1000)
    let endMs = Int64(end.seconds * 1000)
    print("[\(Tags.render)] Applying trim: start=\(startMs) ms, end=\(endMs) ms")

    return CMTimeRange(start: start, end: end)
}
