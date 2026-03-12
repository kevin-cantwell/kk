import SwiftUI

struct AuditionView: View {
    @State private var project = AuditionProject()
    @State private var conversionService = ConversionService()
    @State private var historyService = HistoryService()
    @State private var isProcessing = false
    @State private var resultFolder: URL?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Audition Package")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let folder = resultFolder {
                    AuditionResultView(folderURL: folder) {
                        reset()
                    }
                } else if isProcessing {
                    ProgressOverlay(status: "Preparing audition package...")
                } else {
                    auditionForm
                }
            }
            .padding(24)
        }
    }

    private var auditionForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                TextField("Actor Name", text: $project.actorName)
                TextField("Project Name", text: $project.projectName)
                TextField("Role Name", text: $project.roleName)
            }
            .textFieldStyle(.roundedBorder)

            Text("Attach Files")
                .font(.headline)

            DropZoneView { urls in
                let valid = urls.filter { FileIntakeService.validate(url: $0) }
                project.files.append(contentsOf: valid)
            }

            if !project.files.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(project.files, id: \.path) { url in
                        HStack {
                            Image(systemName: "doc")
                            Text(url.lastPathComponent)
                            Spacer()
                            Button {
                                project.files.removeAll { $0 == url }
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if let error = errorMessage {
                FriendlyErrorView(message: error)
            }

            Button("Create Package") {
                Task { await createPackage() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!project.isValid)
        }
    }

    private func createPackage() async {
        isProcessing = true
        errorMessage = nil

        do {
            let folderName = NamingService.auditionFolderName(project: project)
            let outputDir = try OutputService.ensureSubfolder(.auditions, name: folderName)

            for (_, file) in project.files.enumerated() {
                let mediaType = MediaType.detect(from: file)
                let preset: ConversionPreset
                switch mediaType {
                case .audio: preset = PresetStore.prepareForSharing
                case .video: preset = PresetStore.prepareForAudition
                case .image: preset = PresetStore.makeJPG
                case .unknown: continue
                }

                let result = await conversionService.convert(input: file, preset: preset, outputDir: outputDir)
                if !result.success {
                    errorMessage = "Failed to convert \(file.lastPathComponent): \(result.errorMessage ?? "Unknown error")"
                    isProcessing = false
                    return
                }
            }

            let job = try historyService.createJob(
                workflow: .audition,
                sourcePath: project.files.first?.path ?? "",
                sourceDisplayName: project.folderName,
                presetName: "audition_package"
            )
            try historyService.markCompleted(job, outputPaths: [outputDir.path])

            resultFolder = outputDir
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    private func reset() {
        project = AuditionProject()
        resultFolder = nil
        errorMessage = nil
    }
}
