import AVFoundation

func mapFormatToMimeType(format: String) -> AVFileType {
    switch format {
    case "mp4":
        return .mp4
    case "mov":
        return .mov
    default:
        return .mp4
    }
}
