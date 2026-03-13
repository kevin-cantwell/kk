import Testing
import GRDB
@testable import TapeDesk

@Suite("DatabaseService")
struct DatabaseServiceTests {
    @Test func createsTables() throws {
        let db = try DatabaseService(inMemory: true)
        let tables = try db.dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        }
        #expect(tables.contains("jobs"))
        #expect(tables.contains("reviewItems"))
        #expect(tables.contains("settings"))
    }

    @Test func settingsRoundTrip() throws {
        let db = try DatabaseService(inMemory: true)
        try db.setSetting("test_key", value: "test_value")
        let value = try db.getSetting("test_key")
        #expect(value == "test_value")
    }

    @Test func jobCRUD() throws {
        let db = try DatabaseService(inMemory: true)
        let job = Job(
            id: nil,
            workflow: .convert,
            status: .pending,
            sourcePath: "/tmp/test.m4a",
            sourceDisplayName: "test.m4a",
            outputPathsJSON: "[]",
            presetName: "make_mp3",
            createdAt: Date()
        )
        let inserted = try db.dbQueue.write { dbConn in
            try job.inserted(dbConn)
        }
        #expect(inserted.id != nil)

        let fetched = try db.dbQueue.read { dbConn in
            try Job.fetchAll(dbConn)
        }
        #expect(fetched.count == 1)
        #expect(fetched[0].sourceDisplayName == "test.m4a")
    }

    @Test func reviewItemCRUD() throws {
        let db = try DatabaseService(inMemory: true)
        let item = ReviewItem(
            id: nil,
            sourcePath: "/tmp/clip.mp4",
            fileSize: 1024,
            modifiedAt: Date(),
            mediaType: .video,
            status: .unreviewed,
            note: ""
        )
        let insertedItem = try db.dbQueue.write { dbConn in
            try item.inserted(dbConn)
        }
        #expect(insertedItem.id != nil)

        let fetched = try db.dbQueue.read { dbConn in
            try ReviewItem.fetchAll(dbConn)
        }
        #expect(fetched.count == 1)
        #expect(fetched[0].status == .unreviewed)
    }
}
