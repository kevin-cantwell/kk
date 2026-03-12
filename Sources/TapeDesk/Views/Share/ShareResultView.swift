import SwiftUI

struct ShareResultView: View {
    let result: ConversionService.ConversionResult
    let fileInfo: FileIntakeService.FileInfo
    let intent: DeliveryIntent
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if result.success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Ready to Share!")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Original") {
                        Text(fileInfo.displayName)
                    }
                    LabeledContent("Optimized for") {
                        Text(intent.displayName)
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

                    Button("Share Another") {
                        onReset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                FriendlyErrorView(message: result.errorMessage ?? "Something went wrong.")
                Button("Try Again") { onReset() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
