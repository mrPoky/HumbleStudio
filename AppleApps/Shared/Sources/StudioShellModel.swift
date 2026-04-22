import Foundation
import Combine

struct StudioShellActions {
    var loadBundledStudio: (() -> Void)?
    var loadDemo: (() -> Void)?
    var importPayload: ((String, Data) -> Void)?
    var loadRemoteURL: ((String) -> Void)?
    var navigateBack: (() -> Void)?
    var navigateForward: (() -> Void)?
    var reload: (() -> Void)?
}

final class StudioShellModel: ObservableObject {
    private enum RecentImportStore {
        static let bookmarkKey = "StudioShell.recentImportBookmark"
        static let nameKey = "StudioShell.recentImportName"
    }

    private enum RecentRemoteStore {
        static let urlKey = "StudioShell.recentRemoteURL"
    }

    private var actions = StudioShellActions()

    #if os(iOS)
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = []
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = []
    #else
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #endif

    @Published var errorMessage: String?
    @Published var isConnected = false
    @Published var isPageReady = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var pageTitle = "HumbleStudio"
    @Published var breadcrumb = "Bundled studio"
    @Published var sourceLabel = "Bundled studio"
    @Published var sourceValue = "Embedded app assets"
    @Published var statusLevel = "loading"
    @Published var statusText = "Loading bundled studio…"
    @Published var recentImportName = UserDefaults.standard.string(forKey: RecentImportStore.nameKey)
    @Published var recentRemoteURL = UserDefaults.standard.string(forKey: RecentRemoteStore.urlKey)

    var sourceSummary: String {
        let trimmedValue = sourceValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return sourceLabel
        }
        return "\(sourceLabel) · \(trimmedValue)"
    }

    var hasRecentImport: Bool {
        recentImportName != nil && UserDefaults.standard.data(forKey: RecentImportStore.bookmarkKey) != nil
    }

    var hasRecentRemoteURL: Bool {
        !(recentRemoteURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
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

    func reopenRecentImport() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: RecentImportStore.bookmarkKey) else {
            statusLevel = "warn"
            statusText = "No recent import is available yet."
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: Self.bookmarkResolutionOptions,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                try rememberRecentImport(for: url)
            }
            importFile(at: url)
        } catch {
            report(error: error)
        }
    }

    func loadRemoteURL(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusLevel = "warn"
            statusText = "Enter a remote bundle or config URL."
            return
        }

        guard let parsed = URL(string: trimmed), let scheme = parsed.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            statusLevel = "warn"
            statusText = "Only http and https URLs are supported."
            return
        }

        rememberRecentRemoteURL(trimmed)
        clearError()
        sourceLabel = "Remote URL"
        sourceValue = trimmed
        statusLevel = "loading"
        statusText = "Loading remote source…"
        actions.loadRemoteURL?(trimmed)
    }

    func reopenRecentRemoteURL() {
        guard let recentRemoteURL, !recentRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusLevel = "warn"
            statusText = "No recent remote URL is available yet."
            return
        }

        loadRemoteURL(recentRemoteURL)
    }

    func navigateBack() {
        guard canGoBack else { return }
        actions.navigateBack?()
    }

    func navigateForward() {
        guard canGoForward else { return }
        actions.navigateForward?()
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
            try rememberRecentImport(for: url)
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
        statusLevel: String?,
        canGoBack: Bool?,
        canGoForward: Bool?
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
        if let canGoBack {
            self.canGoBack = canGoBack
        }
        if let canGoForward {
            self.canGoForward = canGoForward
        }
    }

    func report(error: Error) {
        errorMessage = error.localizedDescription
        statusLevel = "err"
        statusText = error.localizedDescription
    }

    private func rememberRecentImport(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: Self.bookmarkCreationOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: RecentImportStore.bookmarkKey)
        UserDefaults.standard.set(url.lastPathComponent, forKey: RecentImportStore.nameKey)
        recentImportName = url.lastPathComponent
    }

    private func rememberRecentRemoteURL(_ urlString: String) {
        UserDefaults.standard.set(urlString, forKey: RecentRemoteStore.urlKey)
        recentRemoteURL = urlString
    }
}
