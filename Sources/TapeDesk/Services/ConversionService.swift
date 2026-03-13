import Foundation

/// Runs FFmpeg using posix_spawn + waitpid to avoid Foundation Process/RunLoop issues.
private enum FFmpegRunner {
    struct Result: Sendable {
        let success: Bool
        let errorOutput: String
    }

    static let ffmpegPath = "/opt/homebrew/bin/ffmpeg"

    static func run(arguments: [String]) -> Result {
        let stderrFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("tapedesk_ffmpeg_\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: stderrFile.path, contents: nil)

        // Build argv for posix_spawn: [ffmpeg, arg1, arg2, ..., NULL]
        let allArgs = [ffmpegPath] + arguments
        var cArgs = allArgs.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.forEach { free($0) } }

        // Set up file actions: stdout -> /dev/null, stderr -> file
        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        // Open /dev/null for stdout (fd 1)
        posix_spawn_file_actions_addopen(&fileActions, 1, "/dev/null", O_WRONLY, 0)
        // Open stderr log file for stderr (fd 2)
        posix_spawn_file_actions_addopen(&fileActions, 2, stderrFile.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)

        var pid: pid_t = 0
        let spawnResult = posix_spawn(&pid, ffmpegPath, &fileActions, nil, &cArgs, environ)

        if spawnResult != 0 {
            try? FileManager.default.removeItem(at: stderrFile)
            return Result(success: false, errorOutput: "posix_spawn failed: \(spawnResult)")
        }

        print("[TapeDesk] Spawned ffmpeg pid=\(pid)")

        var status: Int32 = 0
        waitpid(pid, &status, 0)

        let exitCode = (status >> 8) & 0xFF
        print("[TapeDesk] ffmpeg exited with code \(exitCode)")

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

    func convert(input: URL, preset: ConversionPreset, outputDir: URL) async -> ConversionResult {
        isRunning = true
        progress = 0
        currentStatus = "Converting..."

        let sanitizedName = PathSanitizer.sanitize(input.deletingPathExtension().lastPathComponent)
        let outputName = "\(sanitizedName).\(preset.outputExtension)"
        let rawOutputURL = outputDir.appendingPathComponent(outputName)
        let outputURL = PathSanitizer.resolveCollision(for: rawOutputURL)

        let args = preset.ffmpegArguments(input.path, outputURL.path)
        print("[TapeDesk] Running: ffmpeg \(args.joined(separator: " "))")

        let ffmpegResult: FFmpegRunner.Result = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = FFmpegRunner.run(arguments: args)
                continuation.resume(returning: result)
            }
        }

        print("[TapeDesk] FFmpeg finished: success=\(ffmpegResult.success)")

        isRunning = false

        if ffmpegResult.success {
            progress = 1.0
            currentStatus = "Complete"
            return ConversionResult(outputURL: outputURL, success: true, errorMessage: nil)
        } else {
            currentStatus = "Failed"
            return ConversionResult(outputURL: outputURL, success: false, errorMessage: ffmpegResult.errorOutput)
        }
    }

    func cancel() {
        isRunning = false
        currentStatus = "Cancelled"
    }
}
