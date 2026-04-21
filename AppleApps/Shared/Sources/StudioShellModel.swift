import Foundation
import Observation

struct StudioShellActions {
    var loadBundledStudio: (() -> Void)?
    var reload: (() -> Void)?
}

@Observable
final class StudioShellModel {
    private var actions = StudioShellActions()

    var errorMessage: String?
    var isConnected = false
    var sourceLabel = "Bundled studio"

    func connect(actions: StudioShellActions) {
        self.actions = actions
        isConnected = true
    }

    func reload() {
        actions.reload?()
    }

    func loadBundledStudio() {
        actions.loadBundledStudio?()
    }

    func clearError() {
        errorMessage = nil
    }

    func report(error: Error) {
        errorMessage = error.localizedDescription
    }
}
