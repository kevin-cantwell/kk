import Foundation

enum NamingService {
    /// Build output filename from source and preset
    static func outputName(source: URL, preset: ConversionPreset) -> String {
        let stem = source.deletingPathExtension().lastPathComponent
        let sanitized = PathSanitizer.sanitize(stem)
        return "\(sanitized).\(preset.outputExtension)"
    }

    /// Build audition folder name
    static func auditionFolderName(project: AuditionProject) -> String {
        PathSanitizer.sanitize(project.folderName)
    }

    /// Build audition file name with index
    static func auditionFileName(project: AuditionProject, file: URL, index: Int) -> String {
        let ext = file.pathExtension.lowercased()
        let sanitizedRole = PathSanitizer.sanitize(project.roleName)
        let sanitizedActor = PathSanitizer.sanitize(project.actorName)
        return "\(sanitizedActor) - \(sanitizedRole) \(index + 1).\(ext)"
    }
}
