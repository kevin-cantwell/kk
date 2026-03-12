import Foundation
import GRDB

@MainActor
final class ReviewService: ObservableObject {
    @Published var items: [ReviewItem] = []

    private let db: DatabaseService

    init(db: DatabaseService = .shared) {
        self.db = db
    }

    func scanFolder(_ folderURL: URL) throws {
        let fm = FileManager.default
        let supportedExts = FileIntakeService.supportedExtensions()

        guard let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return
        }

        var newItems: [ReviewItem] = []

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard supportedExts.contains(ext) else { continue }

            let mediaType = MediaType.detect(from: fileURL)
            let size = FileHelpers.fileSize(at: fileURL)
            let modified = FileHelpers.modificationDate(at: fileURL)

            let item = ReviewItem(
                id: nil,
                sourcePath: fileURL.path,
                fileSize: size,
                modifiedAt: modified,
                mediaType: mediaType,
                durationSeconds: nil,
                status: .unreviewed,
                note: "",
                lastReviewedAt: nil
            )
            newItems.append(item)
        }

        try db.dbQueue.write { db in
            for item in newItems {
                // Insert only if not already tracked
                let existing = try ReviewItem.filter(Column("sourcePath") == item.sourcePath).fetchOne(db)
                if existing == nil {
                    try item.insert(db)
                }
            }
        }

        try loadItems()
    }

    func loadItems() throws {
        items = try db.dbQueue.read { db in
            try ReviewItem.order(Column("modifiedAt").desc).fetchAll(db)
        }
    }

    func updateStatus(_ item: ReviewItem, status: ReviewStatus) throws {
        try db.dbQueue.write { db in
            var updated = item
            updated.status = status
            updated.lastReviewedAt = Date()
            try updated.update(db)
        }
        try loadItems()
    }

    func updateNote(_ item: ReviewItem, note: String) throws {
        try db.dbQueue.write { db in
            var updated = item
            updated.note = note
            updated.lastReviewedAt = Date()
            try updated.update(db)
        }
        try loadItems()
    }

    func exportCSV() throws -> URL {
        let outputDir = try OutputService.ensureFolder(.logs)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "review_export_\(formatter.string(from: Date())).csv"
        let outputURL = outputDir.appendingPathComponent(filename)

        var csv = "File,Size,Type,Duration,Status,Note,Last Reviewed\n"
        for item in items {
            let size = FileHelpers.formattedFileSize(item.fileSize)
            let duration = item.durationSeconds.map { String(format: "%.1f", $0) } ?? ""
            let reviewed = item.lastReviewedAt?.description ?? ""
            let note = item.note.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(item.sourcePath)\",\"\(size)\",\"\(item.mediaType.rawValue)\",\"\(duration)\",\"\(item.status.rawValue)\",\"\(note)\",\"\(reviewed)\"\n"
        }

        try csv.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }
}
