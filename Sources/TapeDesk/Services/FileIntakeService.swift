import Foundation

enum FileIntakeService {
    struct FileInfo: Sendable {
        let url: URL
        let displayName: String
        let mediaType: MediaType
        let fileSize: Int64
        let modifiedAt: Date
    }

    static func analyze(url: URL) -> FileInfo {
        FileInfo(
            url: url,
            displayName: url.lastPathComponent,
            mediaType: MediaType.detect(from: url),
            fileSize: FileHelpers.fileSize(at: url),
            modifiedAt: FileHelpers.modificationDate(at: url)
        )
    }

    static func validate(url: URL) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return false }
        guard fm.isReadableFile(atPath: url.path) else { return false }
        let mediaType = MediaType.detect(from: url)
        return mediaType != .unknown
    }

    static func supportedExtensions() -> Set<String> {
        Set(["mp3", "m4a", "aac", "wav", "aiff", "flac", "ogg", "wma",
             "mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg",
             "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "bmp", "gif", "webp"])
    }
}
