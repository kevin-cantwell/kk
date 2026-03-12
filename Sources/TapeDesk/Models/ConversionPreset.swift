import Foundation

struct ConversionPreset: Sendable, Identifiable {
    var id: String { name }
    let name: String
    let displayName: String
    let description: String
    let mediaType: MediaType
    let outputExtension: String
    let ffmpegArguments: @Sendable (_ inputPath: String, _ outputPath: String) -> [String]
}
