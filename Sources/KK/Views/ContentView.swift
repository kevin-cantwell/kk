import SwiftUI

enum NavItem: String, Hashable, CaseIterable, Identifiable {
    case convert
    case scan

    var id: String { rawValue }

    var label: String {
        switch self {
        case .convert: "Convert"
        case .scan: "Scan"
        }
    }

    var icon: String {
        switch self {
        case .convert: "arrow.triangle.2.circlepath"
        case .scan: "scanner"
        }
    }
}

struct ContentView: View {
    let openedFile: OpenedFile
    @State private var selection: NavItem? = .convert

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(NavItem.allCases) { item in
                    Label(item.label, systemImage: item.icon)
                        .tag(item)
                }
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            switch selection {
            case .convert:
                ConvertView(openedFile: openedFile)
            case .scan:
                ScanView()
            case nil:
                ConvertView(openedFile: openedFile)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: openedFile.url) { _, newValue in
            if newValue != nil {
                selection = .convert
            }
        }
    }
}
