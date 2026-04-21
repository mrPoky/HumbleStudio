import SwiftUI

@main
struct HumbleStudioMacApp: App {
    var body: some Scene {
        WindowGroup("HumbleStudio") {
            StudioShellView()
                .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1320, height: 860)
    }
}
