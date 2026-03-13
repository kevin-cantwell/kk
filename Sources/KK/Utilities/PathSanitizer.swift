import Foundation

enum PathSanitizer {
    /// Characters not allowed in filenames on macOS/Windows
    private static let illegalCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")

    /// Sanitize a filename by replacing illegal characters with underscores
    static func sanitize(_ filename: String) -> String {
        var sanitized = filename.unicodeScalars.map { scalar in
            illegalCharacters.contains(scalar) ? "_" : String(scalar)
        }.joined()

        // Trim leading/trailing whitespace and dots
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        // Collapse multiple underscores
        while sanitized.contains("__") {
            sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
        }

        if sanitized.isEmpty {
            sanitized = "untitled"
        }

        return sanitized
    }

    /// Resolve filename collision by appending ` 2`, ` 3`, etc.
    static func resolveCollision(for path: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path.path) else { return path }

        let directory = path.deletingLastPathComponent()
        let stem = path.deletingPathExtension().lastPathComponent
        let ext = path.pathExtension

        var counter = 2
        while true {
            let newName = ext.isEmpty ? "\(stem) \(counter)" : "\(stem) \(counter).\(ext)"
            let candidate = directory.appendingPathComponent(newName)
            if !fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }
}
