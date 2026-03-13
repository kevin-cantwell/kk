import Foundation

enum PresetStore {
    // MARK: - Audio Presets

    static let makeMP3 = ConversionPreset(
        name: "make_mp3",
        displayName: "Make MP3",
        description: "Convert to MP3 at 192 kbps",
        mediaType: .audio,
        outputExtension: "mp3",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:a", "libmp3lame", "-b:a", "192k", "-y", output]
        }
    )

    static let makeSmallerAudio = ConversionPreset(
        name: "make_smaller_audio",
        displayName: "Make Smaller",
        description: "Compress to MP3 at 128 kbps",
        mediaType: .audio,
        outputExtension: "mp3",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:a", "libmp3lame", "-b:a", "128k", "-y", output]
        }
    )

    static let prepareForSharing = ConversionPreset(
        name: "prepare_for_sharing_audio",
        displayName: "Prepare for Sharing",
        description: "MP3 at 160 kbps, good balance of quality and size",
        mediaType: .audio,
        outputExtension: "mp3",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:a", "libmp3lame", "-b:a", "160k", "-y", output]
        }
    )

    // MARK: - Video Presets

    static let makeMP4 = ConversionPreset(
        name: "make_mp4",
        displayName: "Make MP4",
        description: "Convert to H.264/AAC MP4 with fast start",
        mediaType: .video,
        outputExtension: "mp4",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:v", "libx264", "-preset", "medium", "-crf", "23",
             "-codec:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-y", output]
        }
    )

    static let makeSmallerVideo = ConversionPreset(
        name: "make_smaller_video",
        displayName: "Make Smaller",
        description: "H.264 MP4, 1080p max, lower bitrate",
        mediaType: .video,
        outputExtension: "mp4",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:v", "libx264", "-preset", "medium", "-crf", "28",
             "-vf", "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease",
             "-codec:a", "aac", "-b:a", "128k", "-movflags", "+faststart", "-y", output]
        }
    )

    static let prepareForAudition = ConversionPreset(
        name: "prepare_for_audition",
        displayName: "Prepare for Audition",
        description: "H.264 1080p, balanced quality",
        mediaType: .video,
        outputExtension: "mp4",
        ffmpegArguments: { input, output in
            ["-i", input, "-codec:v", "libx264", "-preset", "medium", "-crf", "20",
             "-vf", "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease",
             "-codec:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-y", output]
        }
    )

    // MARK: - Image Presets

    static let makeJPG = ConversionPreset(
        name: "make_jpg",
        displayName: "Make JPG",
        description: "Convert to JPEG, quality 90",
        mediaType: .image,
        outputExtension: "jpg",
        ffmpegArguments: { input, output in
            ["-i", input, "-q:v", "2", "-frames:v", "1", "-update", "1", "-y", output]
        }
    )

    static let makeSmallerImage = ConversionPreset(
        name: "make_smaller_image",
        displayName: "Make Smaller",
        description: "JPEG quality 82, downscale large images",
        mediaType: .image,
        outputExtension: "jpg",
        ffmpegArguments: { input, output in
            ["-i", input, "-vf", "scale='min(2048,iw)':'min(2048,ih)':force_original_aspect_ratio=decrease",
             "-q:v", "5", "-frames:v", "1", "-update", "1", "-y", output]
        }
    )

    // MARK: - Lookup

    static let allPresets: [ConversionPreset] = [
        makeMP3, makeSmallerAudio, prepareForSharing,
        makeMP4, makeSmallerVideo, prepareForAudition,
        makeJPG, makeSmallerImage
    ]

    static func presets(for mediaType: MediaType) -> [ConversionPreset] {
        allPresets.filter { $0.mediaType == mediaType }
    }

    static func preset(named name: String) -> ConversionPreset? {
        allPresets.first { $0.name == name }
    }

    /// Pick appropriate presets for a delivery intent
    static func preset(for intent: DeliveryIntent, mediaType: MediaType) -> ConversionPreset? {
        switch (intent, mediaType) {
        case (.email, .audio): return makeSmallerAudio
        case (.email, .video): return makeSmallerVideo
        case (.email, .image): return makeSmallerImage
        case (.message, .audio): return makeSmallerAudio
        case (.message, .video): return makeSmallerVideo
        case (.message, .image): return makeSmallerImage
        case (.socialMedia, .video): return makeMP4
        case (.socialMedia, .image): return makeJPG
        case (.socialMedia, .audio): return makeMP3
        case (.cloudUpload, .video): return makeMP4
        case (.cloudUpload, .audio): return makeMP3
        case (.cloudUpload, .image): return makeJPG
        case (.general, .video): return makeMP4
        case (.general, .audio): return makeMP3
        case (.general, .image): return makeJPG
        case (_, .unknown): return nil
        }
    }
}
