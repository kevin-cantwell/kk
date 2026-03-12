import SwiftUI

struct ConvertResultView: View {
    let result: ConversionService.ConversionResult
    let fileInfo: FileIntakeService.FileInfo
    let preset: ConversionPreset
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if result.success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Conversion Complete!")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Original") {
                        Text(fileInfo.displayName)
                    }
                    LabeledContent("Preset") {
                        Text(preset.displayName)
                    }
                    LabeledContent("Output") {
                        Text(result.outputURL.lastPathComponent)
                    }
                    LabeledContent("Size") {
                        Text(FileHelpers.formattedFileSize(FileHelpers.fileSize(at: result.outputURL)))
                    }
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    Button("Show in Finder") {
                        FileHelpers.revealInFinder(result.outputURL)
                    }
                    .buttonStyle(.bordered)

                    Button("Convert Another") {
                        onReset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                FriendlyErrorView(message: result.errorMessage ?? "Something went wrong during conversion.")

                Button("Try Again") {
                    onReset()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
