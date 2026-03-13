import Foundation

enum OutputFolder: String, Sendable {
    case converted = "Converted"
    case shared = "Shared"
    case logs = "Logs"
}

enum OutputService {
    static var baseURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("Tape Desk")
    }

    static func folder(_ folder: OutputFolder) -> URL {
        baseURL.appendingPathComponent(folder.rawValue)
    }

    static func ensureFolder(_ folder: OutputFolder) throws -> URL {
        let url = self.folder(folder)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func ensureSubfolder(_ folder: OutputFolder, name: String) throws -> URL {
        let parent = try ensureFolder(folder)
        let sub = parent.appendingPathComponent(PathSanitizer.sanitize(name))
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        return sub
    }

    static func ensureAllFolders() throws {
        for folder in [OutputFolder.converted, .shared, .logs] {
            _ = try ensureFolder(folder)
        }
    }
}
