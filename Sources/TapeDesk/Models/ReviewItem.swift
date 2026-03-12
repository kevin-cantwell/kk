import Foundation
import GRDB

enum ReviewStatus: String, Codable, Sendable, CaseIterable {
    case unreviewed
    case reviewed
    case strong
    case followUp

    var displayName: String {
        switch self {
        case .unreviewed: "Unreviewed"
        case .reviewed: "Reviewed"
        case .strong: "Strong"
        case .followUp: "Follow Up"
        }
    }
}

struct ReviewItem: Codable, Sendable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var sourcePath: String
    var fileSize: Int64
    var modifiedAt: Date
    var mediaType: MediaType
    var durationSeconds: Double?
    var status: ReviewStatus
    var note: String
    var lastReviewedAt: Date?

    static let databaseTableName = "reviewItems"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
