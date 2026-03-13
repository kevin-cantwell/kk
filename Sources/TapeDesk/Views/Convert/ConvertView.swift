import SwiftUI

struct ConvertView: View {
    @State private var droppedFile: URL?
    @State private var fileInfo: FileIntakeService.FileInfo?
    @State private var selectedPreset: ConversionPreset?
    @StateObject private var conversionService = ConversionService()
    @State private var result: ConversionService.ConversionResult?
    @StateObject private var historyService = HistoryService()
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Convert Files")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if result != nil {
                    ConvertResultView(result: result!, fileInfo: fileInfo!, preset: selectedPreset!) {
                        reset()
                    }
                } else if conversionService.isRunning {
                    ProgressOverlay(status: conversionService.currentStatus)
                } else if let info = fileInfo {
                    FileInfoCard(info: info) {
                        reset()
                    }

                    presetPicker(for: info.mediaType)

                    if let preset = selectedPreset {
                        Button("Convert") {
                            Task { await startConversion(info: info, preset: preset) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
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

    private func presetPicker(for mediaType: MediaType) -> some View {
        let presets = PresetStore.presets(for: mediaType)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Choose a preset:")
                .font(.headline)
            ForEach(presets) { preset in
                Button {
                    selectedPreset = preset
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preset.displayName).fontWeight(.medium)
                            Text(preset.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedPreset?.name == preset.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                    .background(selectedPreset?.name == preset.name ? Color.blue.opacity(0.1) : Color.clear)
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
            errorMessage = "This file type isn't supported. Try audio, video, or image files."
        }
    }

    private func startConversion(info: FileIntakeService.FileInfo, preset: ConversionPreset) async {
        do {
            let outputDir = try OutputService.ensureFolder(.converted)
            let job = try historyService.createJob(
                workflow: .convert,
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
        selectedPreset = nil
        result = nil
        errorMessage = nil
    }
}
