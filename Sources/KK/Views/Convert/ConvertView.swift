import SwiftUI
import UniformTypeIdentifiers

struct ConvertView: View {
    let openedFile: OpenedFile
    @State private var droppedFile: URL?
    @State private var fileInfo: FileIntakeService.FileInfo?
    @State private var selectedFormat: OutputFormat?
    @StateObject private var conversionService = ConversionService()
    @State private var result: ConversionService.ConversionResult?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("File Converter")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if result != nil {
                    ConvertResultView(result: result!, fileInfo: fileInfo!, format: selectedFormat!) {
                        reset()
                    }
                } else if conversionService.isRunning {
                    ProgressOverlay(status: conversionService.currentStatus)
                } else if let info = fileInfo {
                    FileInfoCard(info: info) {
                        reset()
                    }

                    formatPicker(for: info.mediaType)

                    if selectedFormat != nil {
                        Button("Convert") {
                            Task { await pickLocationAndConvert(info: info) }
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
        .onAppear {
            if let url = openedFile.url {
                openedFile.url = nil
                handleDrop([url])
            }
        }
        .onChange(of: openedFile.url) { _, newValue in
            if let url = newValue {
                openedFile.url = nil
                reset()
                handleDrop([url])
            }
        }
    }

    private func formatPicker(for mediaType: MediaType) -> some View {
        let formats = OutputFormat.formats(for: mediaType)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Output format:")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(formats) { format in
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
    }

    private func handleDrop(_ urls: [URL]) {
        guard let url = urls.first else { return }
        if FileIntakeService.validate(url: url) {
            droppedFile = url
            let info = FileIntakeService.analyze(url: url)
            fileInfo = info
            selectedFormat = OutputFormat.defaultFormat(for: info.mediaType)
            errorMessage = nil
        } else {
            errorMessage = "This file type isn't supported. Try audio, video, or image files."
        }
    }

    private func pickLocationAndConvert(info: FileIntakeService.FileInfo) async {
        guard let format = selectedFormat else { return }

        let sanitizedName = PathSanitizer.sanitize(info.url.deletingPathExtension().lastPathComponent)
        let defaultName = "\(sanitizedName).\(format.fileExtension)"

        let panel = NSSavePanel()
        panel.directoryURL = info.url.deletingLastPathComponent()
        panel.nameFieldStringValue = defaultName
        if let uttype = UTType(filenameExtension: format.fileExtension) {
            panel.allowedContentTypes = [uttype]
        }

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        let convResult = await conversionService.convert(input: info.url, format: format, outputURL: saveURL)
        result = convResult
        if !convResult.success {
            errorMessage = convResult.errorMessage
        }
    }

    private func reset() {
        droppedFile = nil
        fileInfo = nil
        selectedFormat = nil
        result = nil
        errorMessage = nil
    }
}
