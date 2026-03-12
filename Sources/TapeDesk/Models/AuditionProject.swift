import Foundation

struct AuditionProject: Sendable {
    var projectName: String = ""
    var roleName: String = ""
    var actorName: String = ""
    var files: [URL] = []

    var isValid: Bool {
        !projectName.isEmpty && !roleName.isEmpty && !actorName.isEmpty && !files.isEmpty
    }

    var folderName: String {
        let parts = [actorName, projectName, roleName].map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return parts.joined(separator: " - ")
    }
}
