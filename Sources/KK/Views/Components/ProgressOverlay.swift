import SwiftUI

struct ProgressOverlay: View {
    let status: String
    var progress: Double?

    var body: some View {
        VStack(spacing: 16) {
            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 240)
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }
            Text(status)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
