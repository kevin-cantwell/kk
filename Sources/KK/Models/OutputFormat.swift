import Foundation

enum ConversionMethod: Sendable {
    case sips
    case afconvert
    case lame
    case avfoundation
}

enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    // Image (sips — built into macOS)
    case jpg, png, heic
    // Audio (afconvert — built into macOS)
    case mp3, aac, m4a, wav
    // Video (AVFoundation)
    case mp4, mov

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jpg:  "JPG"
        case .png:  "PNG"
        case .heic: "HEIC"
        case .mp3:  "MP3"
        case .aac:  "AAC"
        case .m4a:  "M4A"
        case .wav:  "WAV"
        case .mp4:  "MP4"
        case .mov:  "MOV"
        }
    }

    var fileExtension: String { rawValue }

    var mediaType: MediaType {
        switch self {
        case .jpg, .png, .heic: .image
        case .mp3, .aac, .m4a, .wav: .audio
        case .mp4, .mov:        .video
        }
    }

    var conversionMethod: ConversionMethod {
        switch self {
        case .jpg, .png, .heic: .sips
        case .mp3:              .lame
        case .aac, .m4a, .wav:  .afconvert
        case .mp4, .mov:        .avfoundation
        }
    }

    /// sips format identifier for image conversions
    var sipsFormat: String {
        switch self {
        case .jpg:  "jpeg"
        case .png:  "png"
        case .heic: "heic"
        default:    ""
        }
    }

    /// lame arguments for MP3 encoding
    func lameArguments(input: String, output: String) -> [String] {
        return ["-V", "2", input, output]
    }

    /// afconvert arguments for audio conversions
    func afconvertArguments(input: String, output: String) -> [String] {
        switch self {
        case .aac:
            return ["-f", "adts", "-d", "aac", "-b", "192000", input, output]
        case .m4a:
            return ["-f", "m4af", "-d", "aac", "-b", "192000", input, output]
        case .wav:
            return ["-f", "WAVE", "-d", "LEI16", input, output]
        default:
            return []
        }
    }

    static func formats(for mediaType: MediaType) -> [OutputFormat] {
        allCases.filter { $0.mediaType == mediaType }
    }

    static func defaultFormat(for mediaType: MediaType) -> OutputFormat {
        switch mediaType {
        case .image:   .jpg
        case .audio:   .mp3
        case .video:   .mp4
        case .unknown: .mp4
        }
    }
}
