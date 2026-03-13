import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationItem?

    var body: some View {
        List(selection: $selection) {
            Section("Workflows") {
                ForEach([NavigationItem.home, .convert, .share]) { item in
                    Label(item.label, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section {
                Label(NavigationItem.history.label, systemImage: NavigationItem.history.icon)
                    .tag(NavigationItem.history)
            }

            Section {
                Label(NavigationItem.settings.label, systemImage: NavigationItem.settings.icon)
                    .tag(NavigationItem.settings)
            }
        }
        .navigationTitle("Tape Desk")
    }
}
