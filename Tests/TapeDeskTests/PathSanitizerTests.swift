import Testing
@testable import TapeDesk

@Suite("PathSanitizer")
struct PathSanitizerTests {
    @Test func replacesIllegalChars() {
        let result = PathSanitizer.sanitize("my/file:name*test?.txt")
        #expect(!result.contains("/"))
        #expect(!result.contains(":"))
        #expect(!result.contains("*"))
        #expect(!result.contains("?"))
    }

    @Test func allSpecialChars() {
        let input = "a/b\\c:d*e?f\"g<h>i|j"
        let result = PathSanitizer.sanitize(input)
        for ch: Character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"] {
            #expect(!result.contains(ch))
        }
    }

    @Test func trimsWhitespaceAndDots() {
        #expect(PathSanitizer.sanitize("  hello  ") == "hello")
        #expect(PathSanitizer.sanitize("...hello...") == "hello")
    }

    @Test func emptyInput() {
        #expect(PathSanitizer.sanitize("") == "untitled")
        #expect(PathSanitizer.sanitize("***") == "untitled")
    }

    @Test func collapsesUnderscores() {
        let result = PathSanitizer.sanitize("a//b")
        #expect(!result.contains("__"))
    }

    @Test func collisionResolution() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("sanitizer_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let file = tmp.appendingPathComponent("test.mp3")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        let resolved = PathSanitizer.resolveCollision(for: file)
        #expect(resolved.lastPathComponent == "test 2.mp3")

        FileManager.default.createFile(atPath: resolved.path, contents: nil)
        let resolved2 = PathSanitizer.resolveCollision(for: file)
        #expect(resolved2.lastPathComponent == "test 3.mp3")
    }
}
