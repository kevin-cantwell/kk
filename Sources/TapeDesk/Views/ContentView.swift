import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $appState.selectedNavItem)
        } detail: {
            switch appState.selectedNavItem {
            case .home:
                HomeView(selection: $appState.selectedNavItem)
            case .convert:
                ConvertView()
            case .audition:
                AuditionView()
            case .share:
                ShareView()
            case .review:
                ReviewView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            case nil:
                HomeView(selection: $appState.selectedNavItem)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
