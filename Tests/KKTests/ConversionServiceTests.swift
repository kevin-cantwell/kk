import Testing
@testable import KK

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

    @Test func outputFormatsByMediaType() {
        let imageFormats = OutputFormat.formats(for: .image)
        #expect(imageFormats.count == 3)
        #expect(imageFormats.contains(.jpg))
        #expect(imageFormats.contains(.png))
        #expect(imageFormats.contains(.heic))

        let audioFormats = OutputFormat.formats(for: .audio)
        #expect(audioFormats.count == 2)
        #expect(audioFormats.contains(.m4a))
        #expect(audioFormats.contains(.wav))

        let videoFormats = OutputFormat.formats(for: .video)
        #expect(videoFormats.count == 2)
        #expect(videoFormats.contains(.mp4))
        #expect(videoFormats.contains(.mov))
    }

    @Test func defaultFormats() {
        #expect(OutputFormat.defaultFormat(for: .image) == .jpg)
        #expect(OutputFormat.defaultFormat(for: .audio) == .m4a)
        #expect(OutputFormat.defaultFormat(for: .video) == .mp4)
    }

    @Test func conversionMethods() {
        #expect(OutputFormat.jpg.conversionMethod == .sips)
        #expect(OutputFormat.png.conversionMethod == .sips)
        #expect(OutputFormat.heic.conversionMethod == .sips)
        #expect(OutputFormat.m4a.conversionMethod == .afconvert)
        #expect(OutputFormat.wav.conversionMethod == .afconvert)
        #expect(OutputFormat.mp4.conversionMethod == .avfoundation)
        #expect(OutputFormat.mov.conversionMethod == .avfoundation)
    }

    @Test func afconvertArguments() {
        let args = OutputFormat.m4a.afconvertArguments(input: "/in.wav", output: "/out.m4a")
        #expect(args.contains("-f"))
        #expect(args.contains("m4af"))
        #expect(args.contains("-d"))
        #expect(args.contains("aac"))
        #expect(args.first == "-f")
        #expect(args.last == "/out.m4a")
    }
}
