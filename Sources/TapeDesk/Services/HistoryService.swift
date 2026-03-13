import Foundation
import GRDB

@MainActor
final class HistoryService: ObservableObject {
    @Published var jobs: [Job] = []

    private let db: DatabaseService

    init(db: DatabaseService = .shared) {
        self.db = db
    }

    func loadJobs() throws {
        jobs = try db.dbQueue.read { db in
            try Job.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func createJob(workflow: Workflow, sourcePath: String, sourceDisplayName: String, presetName: String) throws -> Job {
        let job = Job(
            id: nil,
            workflow: workflow,
            status: .pending,
            sourcePath: sourcePath,
            sourceDisplayName: sourceDisplayName,
            outputPathsJSON: "[]",
            presetName: presetName,
            errorMessage: nil,
            createdAt: Date(),
            completedAt: nil
        )
        let inserted = try db.dbQueue.write { db in
            try job.inserted(db)
        }
        try loadJobs()
        return inserted
    }

    func markCompleted(_ job: Job, outputPaths: [String]) throws {
        try db.dbQueue.write { db in
            var updated = job
            updated.status = .completed
            updated.completedAt = Date()
            let pathsData = try JSONEncoder().encode(outputPaths)
            updated.outputPathsJSON = String(data: pathsData, encoding: .utf8) ?? "[]"
            try updated.update(db)
        }
        try loadJobs()
    }

    func markFailed(_ job: Job, error: String) throws {
        try db.dbQueue.write { db in
            var updated = job
            updated.status = .failed
            updated.errorMessage = error
            updated.completedAt = Date()
            try updated.update(db)
        }
        try loadJobs()
    }

    func markRunning(_ job: Job) throws {
        try db.dbQueue.write { db in
            var updated = job
            updated.status = .running
            try updated.update(db)
        }
        try loadJobs()
    }

    func deleteJob(_ job: Job) throws {
        _ = try db.dbQueue.write { db in
            try job.delete(db)
        }
        try loadJobs()
    }
}
