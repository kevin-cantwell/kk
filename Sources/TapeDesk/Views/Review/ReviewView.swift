import SwiftUI

struct ReviewView: View {
    @State private var reviewService = ReviewService()
    @State private var selectedItem: ReviewItem?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Review Submissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()

                Button("Scan Folder...") {
                    pickFolder()
                }
                .buttonStyle(.bordered)

                if !reviewService.items.isEmpty {
                    Button("Export CSV") {
                        exportCSV()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)

            if let error = errorMessage {
                FriendlyErrorView(message: error)
                    .padding(.horizontal, 24)
            }

            if reviewService.items.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No files to review")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Click \"Scan Folder\" to load media files for review.")
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                HSplitView {
                    List(reviewService.items, selection: $selectedItem) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(URL(fileURLWithPath: item.sourcePath).lastPathComponent)
                                    .fontWeight(.medium)
                                Text("\(item.mediaType.displayName) - \(FileHelpers.formattedFileSize(item.fileSize))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(item.status)
                        }
                        .tag(item)
                        .padding(.vertical, 2)
                    }
                    .frame(minWidth: 250)

                    if let item = selectedItem {
                        ReviewDetailView(item: item, reviewService: reviewService)
                    } else {
                        Text("Select a file to review")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: ReviewStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ReviewStatus) -> Color {
        switch status {
        case .unreviewed: .gray
        case .reviewed: .blue
        case .strong: .green
        case .followUp: .orange
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try reviewService.scanFolder(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportCSV() {
        do {
            let url = try reviewService.exportCSV()
            FileHelpers.revealInFinder(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
