import SwiftUI

struct AuditionResultView: View {
    let folderURL: URL
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Audition Package Ready!")
                .font(.title2)
                .fontWeight(.bold)

            Text(folderURL.lastPathComponent)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
                }
                .buttonStyle(.bordered)

                Button("Create Another") {
                    onReset()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
