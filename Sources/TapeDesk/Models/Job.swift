import Foundation
import GRDB

enum Workflow: String, Codable, Sendable {
    case convert
    case audition
    case share
}

enum JobStatus: String, Codable, Sendable {
    case pending
    case running
    case completed
    case failed
}

struct Job: Codable, Sendable, Identifiable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var workflow: Workflow
    var status: JobStatus
    var sourcePath: String
    var sourceDisplayName: String
    var outputPathsJSON: String
    var presetName: String
    var errorMessage: String?
    var createdAt: Date
    var completedAt: Date?

    static let databaseTableName = "jobs"

    var outputPaths: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(outputPathsJSON.utf8))) ?? []
        }
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
