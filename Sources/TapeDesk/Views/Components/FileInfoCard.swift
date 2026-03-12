import SwiftUI

struct FileInfoCard: View {
    let info: FileIntakeService.FileInfo
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(info.displayName)
                    .fontWeight(.medium)
                HStack(spacing: 12) {
                    Text(info.mediaType.displayName)
                    Text(FileHelpers.formattedFileSize(info.fileSize))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch info.mediaType {
        case .audio: "waveform"
        case .video: "film"
        case .image: "photo"
        case .unknown: "doc"
        }
    }
}
