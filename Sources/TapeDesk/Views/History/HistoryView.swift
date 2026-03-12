import SwiftUI

struct HistoryView: View {
    @State private var historyService = HistoryService()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(24)

            if historyService.jobs.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No jobs yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Completed conversions will appear here.")
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(historyService.jobs) { job in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(job.sourceDisplayName)
                                    .fontWeight(.medium)
                                HStack(spacing: 8) {
                                    Text(job.workflow.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(job.presetName)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            statusBadge(job.status)

                            if job.status == .completed, let firstOutput = job.outputPaths.first {
                                Button("Reveal") {
                                    FileHelpers.revealInFinder(URL(fileURLWithPath: firstOutput))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear {
            try? historyService.loadJobs()
        }
    }

    private func statusBadge(_ status: JobStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .pending: .gray
        case .running: .blue
        case .completed: .green
        case .failed: .red
        }
    }
}
