import SwiftUI

struct ReviewDetailView: View {
    let item: ReviewItem
    let reviewService: ReviewService
    @State private var note: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(URL(fileURLWithPath: item.sourcePath).lastPathComponent)
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Type") { Text(item.mediaType.displayName) }
                    LabeledContent("Size") { Text(FileHelpers.formattedFileSize(item.fileSize)) }
                    if let duration = item.durationSeconds {
                        LabeledContent("Duration") { Text(String(format: "%.1f sec", duration)) }
                    }
                    LabeledContent("Modified") { Text(item.modifiedAt.formatted()) }
                }

                Divider()

                Text("Status")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(ReviewStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            try? reviewService.updateStatus(item, status: status)
                        }
                        .buttonStyle(.bordered)
                        .tint(item.status == status ? .accentColor : nil)
                        .controlSize(.small)
                    }
                }

                Text("Notes")
                    .font(.headline)

                TextEditor(text: $note)
                    .frame(minHeight: 80)
                    .border(Color.secondary.opacity(0.2))
                    .onAppear { note = item.note }
                    .onChange(of: note) { _, newValue in
                        try? reviewService.updateNote(item, note: newValue)
                    }

                Button("Open in Default App") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.sourcePath))
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
        }
    }
}
