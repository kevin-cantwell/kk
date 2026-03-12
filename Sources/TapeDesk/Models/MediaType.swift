import Foundation

enum MediaType: String, Codable, Sendable {
    case audio
    case video
    case image
    case unknown

    static func detect(from url: URL) -> MediaType {
        switch url.pathExtension.lowercased() {
        case "mp3", "m4a", "aac", "wav", "aiff", "flac", "ogg", "wma":
            return .audio
        case "mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg":
            return .video
        case "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "bmp", "gif", "webp":
            return .image
        default:
            return .unknown
        }
    }

    var displayName: String {
        switch self {
        case .audio: "Audio"
        case .video: "Video"
        case .image: "Image"
        case .unknown: "Unknown"
        }
    }
}
