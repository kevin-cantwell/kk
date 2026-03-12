import Testing
@testable import TapeDesk

@Suite("NamingService")
struct NamingServiceTests {
    @Test func outputNameExtension() {
        let source = URL(fileURLWithPath: "/tmp/my recording.m4a")
        let name = NamingService.outputName(source: source, preset: PresetStore.makeMP3)
        #expect(name == "my recording.mp3")
    }

    @Test func outputNameSanitized() {
        let source = URL(fileURLWithPath: "/tmp/weird:file*name.wav")
        let name = NamingService.outputName(source: source, preset: PresetStore.makeMP3)
        #expect(!name.contains(":"))
        #expect(!name.contains("*"))
        #expect(name.hasSuffix(".mp3"))
    }

    @Test func auditionFolderName() {
        var project = AuditionProject()
        project.actorName = "Jane Doe"
        project.projectName = "Big Movie"
        project.roleName = "Lead"
        let name = NamingService.auditionFolderName(project: project)
        #expect(name.contains("Jane Doe"))
        #expect(name.contains("Big Movie"))
        #expect(name.contains("Lead"))
    }
}
