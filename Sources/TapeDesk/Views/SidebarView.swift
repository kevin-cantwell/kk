import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationItem?

    var body: some View {
        List(selection: $selection) {
            Section("Workflows") {
                ForEach([NavigationItem.home, .convert, .audition, .share]) { item in
                    Label(item.label, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section("Library") {
                ForEach([NavigationItem.review, .history]) { item in
                    Label(item.label, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section {
                Label(NavigationItem.settings.label, systemImage: NavigationItem.settings.icon)
                    .tag(NavigationItem.settings)
            }
        }
        .navigationTitle("Tape Desk")
    }
}
