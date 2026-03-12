import Foundation

@MainActor
final class ConversionService: ObservableObject {
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var currentStatus: String = ""

    private var currentProcess: Process?
    private static let ffmpegPath = "/opt/homebrew/bin/ffmpeg"

    struct ConversionResult: Sendable {
        let outputURL: URL
        let success: Bool
        let errorMessage: String?
    }

    func convert(input: URL, preset: ConversionPreset, outputDir: URL) async -> ConversionResult {
        isRunning = true
        progress = 0
        currentStatus = "Starting conversion..."

        let sanitizedName = PathSanitizer.sanitize(input.deletingPathExtension().lastPathComponent)
        let outputName = "\(sanitizedName).\(preset.outputExtension)"
        let rawOutputURL = outputDir.appendingPathComponent(outputName)
        let outputURL = PathSanitizer.resolveCollision(for: rawOutputURL)

        let args = preset.ffmpegArguments(input.path, outputURL.path)

        let result = await runFFmpeg(arguments: args)

        isRunning = false

        if result.success {
            progress = 1.0
            currentStatus = "Complete"
            return ConversionResult(outputURL: outputURL, success: true, errorMessage: nil)
        } else {
            currentStatus = "Failed"
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: result.errorOutput)
        }
    }

    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
        isRunning = false
        currentStatus = "Cancelled"
    }

    private struct FFmpegResult: Sendable {
        let success: Bool
        let errorOutput: String
    }

    private func runFFmpeg(arguments: [String]) async -> FFmpegResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.ffmpegPath)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe() // discard stdout

        self.currentProcess = process

        do {
            try process.run()
        } catch {
            return FFmpegResult(success: false, errorOutput: error.localizedDescription)
        }

        currentStatus = "Converting..."

        // Wait for process on a background thread
        let ffmpegProcess = process
        let pipe = errorPipe
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                ffmpegProcess.waitUntilExit()
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorStr = String(data: errorData, encoding: .utf8) ?? ""
                let success = ffmpegProcess.terminationStatus == 0
                continuation.resume(returning: FFmpegResult(success: success, errorOutput: errorStr))
            }
        }
    }
}
