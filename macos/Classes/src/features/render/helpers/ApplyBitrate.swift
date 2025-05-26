import AVFoundation
import Foundation


public func applyBitrate(requestedBitrate: Int?, fileType: AVFileType) -> String {
    if let bitrate = requestedBitrate {
        print("[\(Tags.render)] Requested Bitrate: \(bitrate) bps")
        print("[\(Tags.render)] ⚠️ AVAssetExportSession does not support custom bitrate directly.")
     }

    // You might use bitrate to choose a preset
    // Example logic (very approximate):
    if let bitrate = requestedBitrate {
        if bitrate >= 20_000_000 {
            return AVAssetExportPresetHEVCHighestQuality
        } else if bitrate >= 10_000_000 {
            return AVAssetExportPresetHighestQuality
        } else if bitrate >= 5_000_000 {
            return AVAssetExportPreset1280x720
        } else {
            return AVAssetExportPreset640x480
        }
    }

    return AVAssetExportPresetHighestQuality
}
