import SwiftUI

struct HomeView: View {
    @Binding var selection: NavigationItem?

    private let cards: [(NavigationItem, String, String, Color)] = [
        (.convert, "Convert Files", "Change format, make smaller, or prepare for sharing", .blue),
        (.share, "Share Files", "Optimize files for a specific delivery method", .green),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Tape Desk")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Your gentle file-prep assistant. Original files are never modified.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(cards, id: \.0) { item, title, desc, color in
                        WorkflowCard(title: title, description: desc, color: color) {
                            selection = item
                        }
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(24)
        }
    }
}

struct WorkflowCard: View {
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .padding(16)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
