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
        WindowGroup("K.K's App") {
            ContentView(openedFile: appDelegate.openedFile)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 720, height: 540)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About K.K") {
                    AboutWindow.show()
                }
            }
        }
    }
}

@MainActor
private enum AboutWindow {
    static let windowTitle = "About K.K"

    static func show() {
        let existing = NSApp.windows.first { $0.title == windowTitle }
        if let existing {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let aboutView = NSHostingView(rootView: AboutView())
        let frame = NSRect(x: 0, y: 0, width: 440, height: 720)
        aboutView.frame = frame

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = windowTitle
        window.contentView = aboutView
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("K.K's App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Version \(AppVersion.current)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("Made with love for K.K Moggie")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("About K.K")
                        .font(.headline)

                    Text("""
                    K.K Moggie is an actress, teacher, and all-around force of nature. \
                    Born in Malaysia to an Iban father and New Zealand mother, they grew up \
                    across cultures in Kuala Lumpur, Christchurch, and Auckland before \
                    earning their MFA from Columbia University.
                    """)
                    .font(.body)

                    Text("""
                    Their screen credits include Anna and the King, The Sleeping Dictionary, \
                    Inventing Anna (Netflix), The Good Wife (CBS), Gotham Knights (CW), \
                    Bull, God Friended Me, White Collar, Gossip Girl, and Mercy. On stage, \
                    they have performed Off-Broadway in Eureka Day, Daphne's Dive, Passage, \
                    and Richard III, and starred as Mary in Mary Stuart at Chicago \
                    Shakespeare Theater.
                    """)
                    .font(.body)

                    Text("""
                    They are also an adjunct professor of acting for camera at Columbia \
                    University, PACE, and Long Island University.
                    """)
                    .font(.body)

                    Text("""
                    They live in Brooklyn with their adoring husband, cheeky son, and a \
                    very small, very majestic dog.
                    """)
                    .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let image = loadHeadshot() {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 440, height: 720)
    }

    private func loadHeadshot() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "kkmoggie", withExtension: "jpg") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

enum AppVersion {
    static let current = "1.0.0"
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
