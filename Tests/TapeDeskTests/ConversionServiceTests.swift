import Testing
@testable import TapeDesk

@Suite("ConversionService")
struct ConversionServiceTests {
    @Test func mediaTypeDetection() {
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.mp3")) == .audio)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.m4a")) == .audio)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.wav")) == .audio)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.mp4")) == .video)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.mov")) == .video)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.jpg")) == .image)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.png")) == .image)
        #expect(MediaType.detect(from: URL(fileURLWithPath: "/tmp/test.xyz")) == .unknown)
    }

    @Test func supportedExtensions() {
        let supported = FileIntakeService.supportedExtensions()
        #expect(supported.contains("mp3"))
        #expect(supported.contains("mp4"))
        #expect(supported.contains("jpg"))
        #expect(!supported.contains("xyz"))
        #expect(!supported.contains("pdf"))
    }
}
