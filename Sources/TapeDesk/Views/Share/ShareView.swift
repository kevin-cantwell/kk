import SwiftUI

struct ShareView: View {
    @State private var droppedFile: URL?
    @State private var fileInfo: FileIntakeService.FileInfo?
    @State private var selectedIntent: DeliveryIntent?
    @StateObject private var conversionService = ConversionService()
    @StateObject private var historyService = HistoryService()
    @State private var result: ConversionService.ConversionResult?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Share Files")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let result = result, let info = fileInfo, let intent = selectedIntent {
                    ShareResultView(result: result, fileInfo: info, intent: intent) {
                        reset()
                    }
                } else if conversionService.isRunning {
                    ProgressOverlay(status: conversionService.currentStatus)
                } else if let info = fileInfo {
                    FileInfoCard(info: info) {
                        reset()
                    }

                    intentPicker

                    if let intent = selectedIntent {
                        if let preset = PresetStore.preset(for: intent, mediaType: info.mediaType) {
                            Text("Will use: \(preset.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Prepare for Sharing") {
                                Task { await startSharing(info: info, preset: preset) }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            FriendlyErrorView(message: "No preset available for this combination.")
                        }
                    }

                    if let error = errorMessage {
                        FriendlyErrorView(message: error)
                    }
                } else {
                    DropZoneView { urls in
                        handleDrop(urls)
                    }
                }
            }
            .padding(24)
        }
    }

    private var intentPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How will you share this?")
                .font(.headline)
            ForEach(DeliveryIntent.allCases) { intent in
                Button {
                    selectedIntent = intent
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(intent.displayName).fontWeight(.medium)
                            Text(intent.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedIntent == intent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                    .background(selectedIntent == intent ? Color.green.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleDrop(_ urls: [URL]) {
        guard let url = urls.first else { return }
        if FileIntakeService.validate(url: url) {
            droppedFile = url
            fileInfo = FileIntakeService.analyze(url: url)
            errorMessage = nil
        } else {
            errorMessage = "This file type isn't supported."
        }
    }

    private func startSharing(info: FileIntakeService.FileInfo, preset: ConversionPreset) async {
        do {
            let outputDir = try OutputService.ensureFolder(.shared)
            let job = try historyService.createJob(
                workflow: .share,
                sourcePath: info.url.path,
                sourceDisplayName: info.displayName,
                presetName: preset.name
            )
            try historyService.markRunning(job)

            let convResult = await conversionService.convert(input: info.url, preset: preset, outputDir: outputDir)
            result = convResult

            if convResult.success {
                try historyService.markCompleted(job, outputPaths: [convResult.outputURL.path])
            } else {
                try historyService.markFailed(job, error: convResult.errorMessage ?? "Unknown error")
                errorMessage = convResult.errorMessage
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reset() {
        droppedFile = nil
        fileInfo = nil
        selectedIntent = nil
        result = nil
        errorMessage = nil
    }
}
