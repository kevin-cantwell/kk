import Foundation
import GRDB

final class DatabaseService: Sendable {
    static let shared = DatabaseService()
    let dbQueue: DatabaseQueue

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("TapeDesk", isDirectory: true)
        try! FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbPath = dbDir.appendingPathComponent("tapedesk.sqlite").path

        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }

        dbQueue = try! DatabaseQueue(path: dbPath)
        try! migrator.migrate(dbQueue)
    }

    /// For testing with in-memory database
    init(inMemory: Bool) throws {
        dbQueue = try DatabaseQueue()
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "jobs") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("workflow", .text).notNull()
                t.column("status", .text).notNull()
                t.column("sourcePath", .text).notNull()
                t.column("sourceDisplayName", .text).notNull()
                t.column("outputPathsJSON", .text).notNull().defaults(to: "[]")
                t.column("presetName", .text).notNull()
                t.column("errorMessage", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("completedAt", .datetime)
            }

            try db.create(table: "reviewItems") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sourcePath", .text).notNull().unique()
                t.column("fileSize", .integer).notNull()
                t.column("modifiedAt", .datetime).notNull()
                t.column("mediaType", .text).notNull()
                t.column("durationSeconds", .double)
                t.column("status", .text).notNull().defaults(to: "unreviewed")
                t.column("note", .text).notNull().defaults(to: "")
                t.column("lastReviewedAt", .datetime)
            }

            try db.create(table: "settings") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
        }

        return migrator
    }

    // MARK: - Settings helpers

    func getSetting(_ key: String) throws -> String? {
        try dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?", arguments: [key])
        }
    }

    func setSetting(_ key: String, value: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                arguments: [key, value]
            )
        }
    }
}
