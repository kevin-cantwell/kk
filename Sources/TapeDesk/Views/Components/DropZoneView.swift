import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onDrop: ([URL]) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 36))
                .foregroundStyle(isTargeted ? .blue : .secondary)

            Text("Drop files here")
                .font(.title3)
                .fontWeight(.medium)

            Text("or click to browse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Choose Files...") {
                pickFiles()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.blue.opacity(0.08) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        let supported = FileIntakeService.supportedExtensions()
        panel.allowedContentTypes = supported.compactMap { UTType(filenameExtension: $0) }
        if panel.runModal() == .OK {
            onDrop(panel.urls)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let urlString = String(data: data, encoding: .utf8),
                      let url = URL(string: urlString) else { return }
                DispatchQueue.main.async {
                    onDrop([url])
                }
            }
        }
    }
}
