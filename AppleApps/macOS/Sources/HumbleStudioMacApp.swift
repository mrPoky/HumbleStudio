import SwiftUI

@main
struct HumbleStudioMacApp: App {
    var body: some Scene {
        WindowGroup("HumbleStudio") {
            StudioShellView()
                .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1320, height: 860)
        .commands {
            CommandMenu("Studio") {
                Button("Back") {
                    post(.studioNavigateBack)
                }
                .keyboardShortcut("[", modifiers: [.command])

                Button("Forward") {
                    post(.studioNavigateForward)
                }
                .keyboardShortcut("]", modifiers: [.command])

                Divider()

                Button("Open Bundle…") {
                    post(.studioOpenImport)
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Open Remote URL…") {
                    post(.studioOpenRemoteURL)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Button("Reopen Recent Import") {
                    post(.studioReopenRecentImport)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Reopen Recent Remote URL") {
                    post(.studioReopenRecentRemoteURL)
                }
                .keyboardShortcut("u", modifiers: [.command, .option])

                Button("Reload") {
                    post(.studioReload)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button("Show Home") {
                    post(.studioLoadHome)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Load Demo") {
                    post(.studioLoadDemo)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }

    private func post(_ notification: Notification.Name) {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}
