import SwiftUI

struct ContentView: View {
    let openedFile: OpenedFile

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ConvertView(openedFile: openedFile)

                Divider()

                ScanView()
            }
            .padding(24)
        }
    }
}
