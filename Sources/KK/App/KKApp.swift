import SwiftUI
import AppKit

@Observable
final class OpenedFile: @unchecked Sendable {
    var url: URL?
}

@main
struct KKApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(openedFile: appDelegate.openedFile)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 600, height: 580)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    let openedFile = OpenedFile()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let first = filenames.first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }
        let url = URL(fileURLWithPath: first)
        if FileIntakeService.validate(url: url) {
            openedFile.url = url
            sender.reply(toOpenOrPrint: .success)
        } else {
            sender.reply(toOpenOrPrint: .failure)
        }
    }
}
