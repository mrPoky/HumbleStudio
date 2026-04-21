import Foundation
import Observation

struct StudioShellActions {
    var loadBundledStudio: (() -> Void)?
    var loadDemo: (() -> Void)?
    var importPayload: ((String, Data) -> Void)?
    var reload: (() -> Void)?
}

@Observable
final class StudioShellModel {
    private var actions = StudioShellActions()

    var errorMessage: String?
    var isConnected = false
    var isPageReady = false
    var sourceLabel = "Bundled studio"

    func connect(actions: StudioShellActions) {
        self.actions = actions
        isConnected = true
        isPageReady = false
    }

    func reload() {
        isPageReady = false
        actions.reload?()
    }

    func loadBundledStudio() {
        isPageReady = false
        actions.loadBundledStudio?()
    }

    func loadDemo() {
        actions.loadDemo?()
    }

    func importFile(at url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let fileData = try Data(contentsOf: url)
            clearError()
            actions.importPayload?(url.lastPathComponent, fileData)
        } catch {
            report(error: error)
        }
    }

    func markPageReady() {
        isPageReady = true
    }

    func clearError() {
        errorMessage = nil
    }

    func report(error: Error) {
        errorMessage = error.localizedDescription
    }
}
