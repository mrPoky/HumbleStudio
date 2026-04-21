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
    var pageTitle = "HumbleStudio"
    var breadcrumb = "Bundled studio"
    var sourceLabel = "Bundled studio"
    var sourceValue = "Embedded app assets"
    var statusLevel = "loading"
    var statusText = "Loading bundled studio…"

    var sourceSummary: String {
        let trimmedValue = sourceValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return sourceLabel
        }
        return "\(sourceLabel) · \(trimmedValue)"
    }

    func connect(actions: StudioShellActions) {
        self.actions = actions
        isConnected = true
        isPageReady = false
        statusLevel = "loading"
        statusText = "Loading bundled studio…"
    }

    func reload() {
        isPageReady = false
        statusLevel = "loading"
        statusText = "Reloading studio…"
        actions.reload?()
    }

    func loadBundledStudio() {
        isPageReady = false
        sourceLabel = "Bundled studio"
        sourceValue = "Embedded app assets"
        statusLevel = "loading"
        statusText = "Loading bundled studio…"
        actions.loadBundledStudio?()
    }

    func loadDemo() {
        statusLevel = "loading"
        statusText = "Loading demo config…"
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
            sourceLabel = "Local file"
            sourceValue = url.lastPathComponent
            statusLevel = "loading"
            statusText = "Importing \(url.lastPathComponent)…"
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

    func updateShellState(
        title: String?,
        breadcrumb: String?,
        sourceLabel: String?,
        sourceValue: String?,
        statusText: String?,
        statusLevel: String?
    ) {
        if let title, !title.isEmpty {
            pageTitle = title
        }
        if let breadcrumb {
            self.breadcrumb = breadcrumb.isEmpty ? "Bundled studio" : breadcrumb
        }
        if let sourceLabel, !sourceLabel.isEmpty {
            self.sourceLabel = sourceLabel
        }
        if let sourceValue {
            self.sourceValue = sourceValue
        }
        if let statusText, !statusText.isEmpty {
            self.statusText = statusText
        }
        if let statusLevel, !statusLevel.isEmpty {
            self.statusLevel = statusLevel
        }
    }

    func report(error: Error) {
        errorMessage = error.localizedDescription
        statusLevel = "err"
        statusText = error.localizedDescription
    }
}
