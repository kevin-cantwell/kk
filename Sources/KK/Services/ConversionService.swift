import Foundation
import AVFoundation

private enum CLIRunner {
    struct Result: Sendable {
        let success: Bool
        let errorOutput: String
    }

    static func run(executable: String, arguments: [String]) -> Result {
        let stderrFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("kk_cli_\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: stderrFile.path, contents: nil)

        let allArgs = [executable] + arguments
        var cArgs = allArgs.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.forEach { free($0) } }

        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        posix_spawn_file_actions_addopen(&fileActions, 1, "/dev/null", O_WRONLY, 0)
        posix_spawn_file_actions_addopen(&fileActions, 2, stderrFile.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)

        var pid: pid_t = 0
        let spawnResult = posix_spawn(&pid, executable, &fileActions, nil, &cArgs, environ)

        if spawnResult != 0 {
            try? FileManager.default.removeItem(at: stderrFile)
            return Result(success: false, errorOutput: "Failed to launch process: \(spawnResult)")
        }

        print("[KK] Spawned \(URL(fileURLWithPath: executable).lastPathComponent) pid=\(pid)")

        var status: Int32 = 0
        waitpid(pid, &status, 0)

        let exitCode = (status >> 8) & 0xFF
        print("[KK] Process exited with code \(exitCode)")

        let errorStr = (try? String(contentsOf: stderrFile, encoding: .utf8)) ?? ""
        try? FileManager.default.removeItem(at: stderrFile)

        return Result(success: exitCode == 0, errorOutput: errorStr)
    }
}

@MainActor
final class ConversionService: ObservableObject {
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var currentStatus: String = ""

    struct ConversionResult: Sendable {
        let outputURL: URL
        let success: Bool
        let errorMessage: String?
    }

    func convert(input: URL, format: OutputFormat, outputURL: URL) async -> ConversionResult {
        isRunning = true
        progress = 0
        currentStatus = "Converting..."

        let result: ConversionResult
        switch format.conversionMethod {
        case .sips:
            result = await convertWithSips(input: input, format: format, outputURL: outputURL)
        case .afconvert:
            result = await convertWithAfconvert(input: input, format: format, outputURL: outputURL)
        case .avfoundation:
            result = await convertWithAVFoundation(input: input, format: format, outputURL: outputURL)
        }

        isRunning = false
        if result.success {
            progress = 1.0
            currentStatus = "Complete"
        } else {
            currentStatus = "Failed"
        }
        return result
    }

    func cancel() {
        isRunning = false
        currentStatus = "Cancelled"
    }

    // MARK: - Image conversion via sips (built into macOS)

    private func convertWithSips(input: URL, format: OutputFormat, outputURL: URL) async -> ConversionResult {
        let args = ["-s", "format", format.sipsFormat, input.path, "--out", outputURL.path]
        print("[KK] Running: sips \(args.joined(separator: " "))")

        let cliResult = await runCLI(executable: "/usr/bin/sips", arguments: args)
        return toResult(cliResult, outputURL: outputURL, format: format)
    }

    // MARK: - Audio conversion via afconvert (built into macOS)

    private func convertWithAfconvert(input: URL, format: OutputFormat, outputURL: URL) async -> ConversionResult {
        let args = format.afconvertArguments(input: input.path, output: outputURL.path)
        print("[KK] Running: afconvert \(args.joined(separator: " "))")

        let cliResult = await runCLI(executable: "/usr/bin/afconvert", arguments: args)
        return toResult(cliResult, outputURL: outputURL, format: format)
    }

    // MARK: - Video conversion via AVFoundation

    private func convertWithAVFoundation(input: URL, format: OutputFormat, outputURL: URL) async -> ConversionResult {
        let asset = AVURLAsset(url: input)

        let fileType: AVFileType = format == .mp4 ? .mp4 : .mov

        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return ConversionResult(outputURL: outputURL, success: false,
                                    errorMessage: "This file can't be converted to \(format.displayName).")
        }

        session.outputURL = outputURL
        session.outputFileType = fileType

        await session.export()

        switch session.status {
        case .completed:
            return ConversionResult(outputURL: outputURL, success: true, errorMessage: nil)
        case .failed:
            let msg = session.error?.localizedDescription ?? "Video conversion failed."
            print("[KK] AVAssetExportSession failed: \(msg)")
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: msg)
        case .cancelled:
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: "Conversion was cancelled.")
        default:
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: "Conversion failed.")
        }
    }

    // MARK: - Helpers

    private func runCLI(executable: String, arguments: [String]) async -> CLIRunner.Result {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = CLIRunner.run(executable: executable, arguments: arguments)
                continuation.resume(returning: result)
            }
        }
    }

    private func toResult(_ cliResult: CLIRunner.Result, outputURL: URL, format: OutputFormat) -> ConversionResult {
        if cliResult.success {
            return ConversionResult(outputURL: outputURL, success: true, errorMessage: nil)
        } else {
            print("[KK] Conversion failed: \(cliResult.errorOutput)")
            let friendly = friendlyError(from: cliResult.errorOutput, format: format)
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: friendly)
        }
    }

    private func friendlyError(from raw: String, format: OutputFormat) -> String {
        let lower = raw.lowercased()
        if lower.contains("permission denied") {
            return "Permission denied. Check that the app can access the file and save location."
        }
        if lower.contains("not a valid") || lower.contains("unsupported") {
            return "This file can't be converted to \(format.displayName). The format may not be compatible."
        }
        return "Conversion to \(format.displayName) failed. The file may not be compatible with this format."
    }
}
