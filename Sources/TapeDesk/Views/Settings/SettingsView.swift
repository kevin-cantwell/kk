import SwiftUI

struct SettingsView: View {
    @State private var outputFolder: String = ""
    @State private var saved = false

    private let db = DatabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                GroupBox("Output") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("Output Folder", text: $outputFolder)
                                .textFieldStyle(.roundedBorder)
                            Button("Reset") {
                                outputFolder = OutputService.baseURL.path
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text("Default: \(OutputService.baseURL.path)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }

                HStack {
                    Button("Save") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    if saved {
                        Text("Saved!")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        outputFolder = (try? db.getSetting("default_output_folder")) ?? OutputService.baseURL.path
    }

    private func saveSettings() {
        try? db.setSetting("default_output_folder", value: outputFolder)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saved = false
        }
    }
}
