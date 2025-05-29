import AVFoundation
import Foundation

public func applyBitrate(requestedBitrate: Int?, presetHint: String? = nil) -> String {
    if let bitrate = requestedBitrate {
        print("[\(Tags.render)] Requested Bitrate: \(bitrate) bps")
        print("[\(Tags.render)] ⚠️ AVAssetExportSession does not support custom bitrate directly.")
    }

    if let bitrate = requestedBitrate {
        if bitrate >= 50_000_000 {
            if #available(macOS 12.1, *) {
                return AVAssetExportPresetHEVC7680x4320 // 8K
            }
        } else if bitrate >= 40_000_000 {
            if #available(macOS 10.13, *) {
                return AVAssetExportPresetHEVC3840x2160 // 4K HEVC
            } else {
                return AVAssetExportPreset3840x2160 // 4K H264
            }
        } else if bitrate >= 30_000_000 {
            if #available(macOS 10.13, *) {
                return AVAssetExportPresetHEVC1920x1080 // 1080p HEVC
            } else {
                return AVAssetExportPreset1920x1080 // 1080p H264
            }
        } else if bitrate >= 20_000_000 {
            if #available(macOS 10.13, *) {
                return AVAssetExportPresetHEVCHighestQuality
            } else {
                return AVAssetExportPresetHighestQuality
            }
        } else if bitrate >= 10_000_000 {
            return AVAssetExportPresetHighestQuality
        } else if bitrate >= 7_000_000 {
            return AVAssetExportPreset1920x1080
        } else if bitrate >= 5_000_000 {
            return AVAssetExportPreset1280x720
        } else if bitrate >= 3_000_000 {
            return AVAssetExportPreset960x540
        } else if bitrate >= 2_000_000 {
            return AVAssetExportPreset640x480
        } else if bitrate >= 1_000_000 {
            return AVAssetExportPresetMediumQuality
        } else {
            return AVAssetExportPresetLowQuality
        }
    }

    return AVAssetExportPresetHighestQuality
}
