import SwiftUI

enum NavigationItem: String, Hashable, CaseIterable, Identifiable {
    case home
    case convert
    case share
    case history
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: "Home"
        case .convert: "Convert"
        case .share: "Share"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .convert: "arrow.triangle.2.circlepath"
        case .share: "square.and.arrow.up"
        case .history: "clock"
        case .settings: "gear"
        }
    }
}

@MainActor
@Observable
final class AppState {
    var selectedNavItem: NavigationItem? = .home
}
