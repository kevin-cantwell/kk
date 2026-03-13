import SwiftUI

struct ContentView: View {
    let openedFile: OpenedFile

    var body: some View {
        ConvertView(openedFile: openedFile)
    }
}
