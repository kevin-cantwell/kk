import SwiftUI
import UniformTypeIdentifiers

struct ScanView: View {
    @StateObject private var scannerService = ScannerService()
    @State private var selectedFormat: ScanOutputFormat = .pdf

    var body: some View {
        VStack(spacing: 20) {
            Text("Scan Document")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch scannerService.state {
            case .idle:
                startButton

            case .browsing, .connecting:
                lookingView

            case .pickScanner:
                scannerPicker

            case .scanning:
                scanningView

            case .scanned:
                scanResultView

            case .error(let message):
                errorView(message)
            }
        }
    }

    private var startButton: some View {
        Button {
            scannerService.startBrowsing()
        } label: {
            Label("Start Scan", systemImage: "scanner")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var lookingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Looking for scanners...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("Cancel") {
                scannerService.reset()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scannerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose a scanner:")
                .font(.headline)
            ForEach(scannerService.scanners, id: \.self) { scanner in
                Button {
                    scannerService.selectScanner(scanner)
                } label: {
                    HStack {
                        Image(systemName: "scanner")
                        Text(scanner.name ?? "Unknown Scanner")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Button("Cancel") {
                scannerService.reset()
            }
            .buttonStyle(.bordered)
        }
    }

    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("Cancel") {
                scannerService.cancelScan()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var scanResultView: some View {
        if let image = scannerService.scannedImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Save as:")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(ScanOutputFormat.allCases) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        Text(format.displayName)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFormat == format ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08))
                            .foregroundStyle(selectedFormat == format ? .blue : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(selectedFormat == format ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        HStack(spacing: 12) {
            Button("Save") {
                saveScannedDocument()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Home") {
                scannerService.reset()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            FriendlyErrorView(message: message)
            Button("Try Again") {
                scannerService.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func saveScannedDocument() {
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        panel.nameFieldStringValue = "scan.\(selectedFormat.fileExtension)"
        if let uttype = UTType(filenameExtension: selectedFormat.fileExtension) {
            panel.allowedContentTypes = [uttype]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        if scannerService.save(format: selectedFormat, to: url) {
            FileHelpers.revealInFinder(url)
            scannerService.reset()
        }
    }
}
