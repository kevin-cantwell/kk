import Testing
@testable import TapeDesk

@Suite("PresetStore")
struct PresetStoreTests {
    @Test func audioPresets() {
        let presets = PresetStore.presets(for: .audio)
        #expect(presets.count == 3)
        #expect(presets.allSatisfy { $0.mediaType == .audio })
    }

    @Test func videoPresets() {
        let presets = PresetStore.presets(for: .video)
        #expect(presets.count == 3)
        #expect(presets.allSatisfy { $0.mediaType == .video })
    }

    @Test func imagePresets() {
        let presets = PresetStore.presets(for: .image)
        #expect(presets.count == 2)
        #expect(presets.allSatisfy { $0.mediaType == .image })
    }

    @Test func presetByName() {
        let preset = PresetStore.preset(named: "make_mp3")
        #expect(preset != nil)
        #expect(preset?.displayName == "Make MP3")
    }

    @Test func unknownPresets() {
        let presets = PresetStore.presets(for: .unknown)
        #expect(presets.isEmpty)
    }

    @Test func deliveryIntentMapping() {
        let preset = PresetStore.preset(for: .email, mediaType: .video)
        #expect(preset != nil)
        #expect(preset?.name == "make_smaller_video")
    }

    @Test func ffmpegArgs() {
        let args = PresetStore.makeMP3.ffmpegArguments("/input.m4a", "/output.mp3")
        #expect(args.contains("-i"))
        #expect(args.contains("/input.m4a"))
        #expect(args.contains("/output.mp3"))
        #expect(args.contains("192k"))
    }
}
