import SwiftUI

@main
struct HumbleStudioMacApp: App {
    var body: some Scene {
        WindowGroup(StudioStrings.appTitle) {
            StudioMacWorkspaceView()
                .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1320, height: 860)
        .commands {
            CommandMenu(StudioStrings.appTitle) {
                Button("\(StudioStrings.quickOpen)…") {
                    post(.studioOpenQuickOpen)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Divider()

                Button(StudioStrings.back) {
                    post(.studioNavigateBack)
                }
                .keyboardShortcut("[", modifiers: [.command])

                Button(StudioStrings.forward) {
                    post(.studioNavigateForward)
                }
                .keyboardShortcut("]", modifiers: [.command])

                Divider()

                Button(StudioStrings.openBundle) {
                    post(.studioOpenImport)
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button(StudioStrings.openRemoteURL) {
                    post(.studioOpenRemoteURL)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Button(StudioStrings.reopenRecentImport) {
                    post(.studioReopenRecentImport)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button(StudioStrings.reopenRecentRemoteURL) {
                    post(.studioReopenRecentRemoteURL)
                }
                .keyboardShortcut("u", modifiers: [.command, .option])

                Button(StudioStrings.reload) {
                    post(.studioReload)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button(StudioStrings.showHome) {
                    post(.studioLoadHome)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button(StudioStrings.loadDemo) {
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
