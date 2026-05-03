import Foundation
import Combine

enum StudioNativeAppearance: String, CaseIterable, Identifiable {
    case dark
    case light
    case both

    var id: String { rawValue }
}

struct StudioNativeDocument: Equatable {
    struct SnapshotAsset: Equatable {
        let name: String
        let defaultPath: String?
        let lightPath: String?
        let darkPath: String?
    }

    struct TokenDependencySet: Equatable {
        let colors: [String]
        let gradients: [String]
        let spacing: [String]
        let radius: [String]
        let typography: [String]
        let textTones: [String]
        let surfaces: [String]
        let preferredIcons: [String]
        let primitives: [String]
        let actionRoles: [String]
        let frames: [String]

        static let empty = TokenDependencySet(
            colors: [],
            gradients: [],
            spacing: [],
            radius: [],
            typography: [],
            textTones: [],
            surfaces: [],
            preferredIcons: [],
            primitives: [],
            actionRoles: [],
            frames: []
        )
    }

    struct ColorToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let lightHex: String
        let darkHex: String
        let referenceCount: Int
        let sourcePaths: [String]
        let derivedGradientIDs: [String]
    }

    struct GradientToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let lightColors: [String]
        let darkColors: [String]
        let kind: String
        let referenceCount: Int
        let usage: String
        let swiftUI: String
        let tokenColors: [String]
        let sourcePaths: [String]
        let designComponentIDs: [String]
    }

    struct TypographyToken: Identifiable, Equatable {
        let id: String
        let role: String
        let preview: String
        let swiftUI: String
        let size: Double
        let weight: Int
        let referenceCount: Int
        let sourcePaths: [String]
    }

    struct MetricToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let value: String
        let usage: String
        let kind: String
        let referenceCount: Int
        let sourcePaths: [String]
    }

    struct IconToken: Identifiable, Equatable {
        let id: String
        let name: String
        let symbol: String
        let assetPath: String
        let description: String
        let referenceCount: Int
        let sourcePaths: [String]
    }

    struct ComponentItem: Identifiable, Equatable {
        struct StateSummary: Equatable, Identifiable {
            let id: String
            let label: String
            let detail: String
        }

        let id: String
        let name: String
        let group: String
        let renderer: String
        let summary: String
        let swiftUI: String
        let sourcePath: String
        let defaultState: String
        let statesCount: Int
        let states: [StateSummary]
        let designDependencies: TokenDependencySet
        let sourceDependencies: TokenDependencySet
        let designTokenCategories: [String]
        let designTokenCount: Int
        let sourceTokenCount: Int
        let sourceSnippetSymbol: String
        let sourceSnippetRange: String
        let snapshot: SnapshotAsset?
    }

    struct ViewItem: Identifiable, Equatable {
        struct NavigationSummary: Equatable, Identifiable {
            let id: String
            let targetID: String
            let trigger: String
            let type: String
        }

        let id: String
        let name: String
        let summary: String
        let presentation: String
        let sourcePath: String
        let root: Bool
        let defaultState: String
        let statesCount: Int
        let componentsCount: Int
        let components: [String]
        let states: [String]
        let entryPoints: [String]
        let primaryActions: [String]
        let secondaryActions: [String]
        let navigationCount: Int
        let navigatesTo: [NavigationSummary]
        let designDependencies: TokenDependencySet
        let sourceDependencies: TokenDependencySet
        let designTokenCategories: [String]
        let designTokenCount: Int
        let sourceTokenCount: Int
        let sourceSnippetSymbol: String
        let sourceSnippetRange: String
        let sheetPatternsCount: Int
        let overlayPatternsCount: Int
        let snapshot: SnapshotAsset?
    }

    let appName: String
    let appVersion: String
    let appDescription: String
    let assetRootURL: URL?
    let iconBasePath: String?
    let snapshotBasePath: String?
    let navigationRootID: String?
    let navigationType: String
    let colors: [ColorToken]
    let gradients: [GradientToken]
    let typography: [TypographyToken]
    let spacing: [MetricToken]
    let radius: [MetricToken]
    let icons: [IconToken]
    let components: [ComponentItem]
    let views: [ViewItem]

    func resolvedIconURL(for icon: IconToken) -> URL? {
        resolvedAssetURL(basePath: iconBasePath, relativePath: icon.assetPath)
    }

    func resolvedSnapshotURL(for snapshot: SnapshotAsset?, appearance: StudioNativeAppearance = .dark) -> URL? {
        guard let snapshot else { return nil }
        let relativePath: String?
        switch appearance {
        case .light:
            relativePath = snapshot.lightPath ?? snapshot.defaultPath ?? snapshot.darkPath
        case .dark:
            relativePath = snapshot.darkPath ?? snapshot.defaultPath ?? snapshot.lightPath
        case .both:
            relativePath = snapshot.darkPath ?? snapshot.defaultPath ?? snapshot.lightPath
        }
        guard let relativePath else { return nil }
        return resolvedAssetURL(basePath: snapshotBasePath, relativePath: relativePath)
    }

    private func resolvedAssetURL(basePath: String?, relativePath: String) -> URL? {
        let trimmedPath = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return nil }
        if let absoluteURL = URL(string: trimmedPath), absoluteURL.scheme != nil {
            return absoluteURL
        }

        let normalizedBase = (basePath ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedBase.hasPrefix("/") {
            return URL(fileURLWithPath: normalizedBase).appendingPathComponent(trimmedPath)
        }
        if let baseURL = URL(string: normalizedBase), baseURL.scheme != nil {
            return baseURL.appendingPathComponent(trimmedPath)
        }

        guard let assetRootURL else { return nil }
        if normalizedBase.isEmpty {
            return assetRootURL.appendingPathComponent(trimmedPath)
        }
        return assetRootURL.appendingPathComponent(normalizedBase).appendingPathComponent(trimmedPath)
    }
}

enum StudioNativeImportError: LocalizedError {
    case unsupportedBundlePlatform
    case invalidArchive
    case missingDesignJSON
    case invalidDesignJSON

    var errorDescription: String? {
        switch self {
        case .unsupportedBundlePlatform:
            return "Native bundle import is currently only available on macOS."
        case .invalidArchive:
            return "The Humble bundle could not be unpacked."
        case .missingDesignJSON:
            return "The imported source does not contain a design.json manifest."
        case .invalidDesignJSON:
            return "The imported design.json file could not be decoded."
        }
    }
}

enum StudioRecoveryAction: Equatable {
    case reopenRecentImport
    case reopenRecentRemoteURL
    case loadBundledStudio
}

struct StudioNativeRecoveryIssue: Equatable {
    let title: String
    let detail: String
    let primaryAction: StudioRecoveryAction
    let secondaryActions: [StudioRecoveryAction]
}

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

    private enum PreferredLaunchStore {
        static let sourceKey = "StudioShell.preferredLaunchSource"
    }

    enum PreferredLaunchSource: String {
        case bundled
        case demo
        case recentImport
        case recentRemote
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
    @Published var pageTitle = StudioStrings.appTitle
    @Published var breadcrumb = StudioStrings.bundledStudio
    @Published var sourceLabel = StudioStrings.bundledStudio
    @Published var sourceValue = "Embedded app assets"
    @Published var statusLevel = "loading"
    @Published var statusText = StudioStrings.loadingBundledStudio
    @Published var recentImportName = UserDefaults.standard.string(forKey: RecentImportStore.nameKey)
    @Published var recentRemoteURL = UserDefaults.standard.string(forKey: RecentRemoteStore.urlKey)
    @Published var nativeDocument: StudioNativeDocument?
    @Published var nativeErrorMessage: String?
    @Published var nativeRecoveryIssue: StudioNativeRecoveryIssue?

    var sourceSummary: String {
        let trimmedValue = sourceValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return sourceLabel
        }
        return "\(sourceLabel) · \(trimmedValue)"
    }

    var sourceKindLabel: String {
        switch preferredLaunchSource {
        case .bundled:
            return "Bundled"
        case .demo:
            return "Demo"
        case .recentImport:
            return "Local Import"
        case .recentRemote:
            return "Remote URL"
        }
    }

    var recoveryReadinessLabel: String {
        if hasRecentImport && hasRecentRemoteURL {
            return "Import + URL ready"
        }
        if hasRecentImport {
            return "Import ready"
        }
        if hasRecentRemoteURL {
            return "URL ready"
        }
        return "Bundled only"
    }

    var recoveryReadinessTone: String {
        if hasRecentImport || hasRecentRemoteURL {
            return "ok"
        }
        return "warn"
    }

    var recommendedRecoveryActionTitle: String {
        if let nativeRecoveryIssue {
            return title(for: nativeRecoveryIssue.primaryAction)
        }
        if hasRecentImport {
            return StudioStrings.reopenRecentImport
        }
        if hasRecentRemoteURL {
            return StudioStrings.reopenRecentRemoteURL
        }
        return StudioStrings.loadBundledStudioAction
    }

    var recommendedRecoveryDetail: String {
        if let nativeRecoveryIssue {
            return nativeRecoveryIssue.detail
        }
        if let nativeErrorMessage, !nativeErrorMessage.isEmpty {
            return "Native hydration hit an issue. \(recommendedRecoveryActionTitle) is the safest next step while keeping the current session recoverable."
        }
        if nativeDocument != nil {
            return "Recovery is healthy. \(recommendedRecoveryActionTitle) remains available if you need to rehydrate the current source quickly."
        }
        return "No native document is loaded yet. \(recommendedRecoveryActionTitle) is the fastest way to establish working source truth."
    }

    var reloadActionLabel: String {
        switch preferredLaunchSource {
        case .bundled:
            return StudioStrings.loadBundledStudioAction
        case .demo:
            return "Reload demo source"
        case .recentImport:
            return StudioStrings.reopenRecentImport
        case .recentRemote:
            return StudioStrings.reopenRecentRemoteURL
        }
    }

    var recoveryAlternativeActionTitles: [String] {
        guard let nativeRecoveryIssue else { return [] }
        return nativeRecoveryIssue.secondaryActions.map(title(for:))
    }

    var hasRecentImport: Bool {
        recentImportName != nil && UserDefaults.standard.data(forKey: RecentImportStore.bookmarkKey) != nil
    }

    var hasRecentRemoteURL: Bool {
        !(recentRemoteURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var preferredLaunchSource: PreferredLaunchSource {
        get {
            let rawValue = UserDefaults.standard.string(forKey: PreferredLaunchStore.sourceKey)
            return PreferredLaunchSource(rawValue: rawValue ?? "") ?? .bundled
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: PreferredLaunchStore.sourceKey)
        }
    }

    func connect(actions: StudioShellActions) {
        self.actions = actions
        isConnected = true
        isPageReady = false
        statusLevel = "loading"
        statusText = StudioStrings.loadingBundledStudio
    }

    func reload() {
        isPageReady = false
        statusLevel = "loading"
        statusText = StudioStrings.reloadingStudio
        actions.reload?()
    }

    func reloadCurrentSource() {
        switch preferredLaunchSource {
        case .bundled:
            loadBundledStudio()
        case .demo:
            loadDemo()
        case .recentImport:
            reopenRecentImport()
        case .recentRemote:
            reopenRecentRemoteURL()
        }
    }

    func loadBundledStudio() {
        isPageReady = false
        preferredLaunchSource = .bundled
        sourceLabel = StudioStrings.bundledStudio
        sourceValue = "Embedded app assets"
        statusLevel = "loading"
        statusText = StudioStrings.loadingBundledStudio
        nativeDocument = nil
        nativeErrorMessage = nil
        nativeRecoveryIssue = nil
        actions.loadBundledStudio?()
    }

    func loadDemo() {
        preferredLaunchSource = .demo
        statusLevel = "loading"
        statusText = StudioStrings.loadingDemoConfig
        nativeDocument = nil
        nativeErrorMessage = nil
        nativeRecoveryIssue = nil
        actions.loadDemo?()
    }

    func reopenRecentImport() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: RecentImportStore.bookmarkKey) else {
            statusLevel = "warn"
            statusText = StudioStrings.recentImportUnavailable
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
            statusText = StudioStrings.enterRemoteURL
            return
        }

        guard let parsed = URL(string: trimmed), let scheme = parsed.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            statusLevel = "warn"
            statusText = StudioStrings.onlyHTTPSSupported
            return
        }

        rememberRecentRemoteURL(trimmed)
        preferredLaunchSource = .recentRemote
            clearError()
            sourceLabel = StudioStrings.remoteSource
            sourceValue = trimmed
            statusLevel = "loading"
            statusText = StudioStrings.loadingRemoteSource
            nativeRecoveryIssue = nil
            actions.loadRemoteURL?(trimmed)
            hydrateNativeDocumentFromRemoteURL(parsed)
    }

    func reopenRecentRemoteURL() {
        guard let recentRemoteURL, !recentRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusLevel = "warn"
            statusText = StudioStrings.recentRemoteUnavailable
            return
        }

        loadRemoteURL(recentRemoteURL)
    }

    func handleIncomingURL(_ url: URL) {
        if url.isFileURL {
            importFile(at: url)
            return
        }

        guard let scheme = url.scheme?.lowercased() else {
            statusLevel = "warn"
            statusText = StudioStrings.unsupportedIncomingURL
            return
        }

        if ["http", "https"].contains(scheme) {
            loadRemoteURL(url.absoluteString)
            return
        }

        statusLevel = "warn"
        statusText = StudioStrings.onlyFileOrWebURLSupported
    }

    func navigateBack() {
        guard canGoBack else { return }
        actions.navigateBack?()
    }

    func navigateForward() {
        guard canGoForward else { return }
        actions.navigateForward?()
    }

    func resumePreferredSourceAfterLaunch() {
        switch preferredLaunchSource {
        case .bundled:
            return
        case .demo:
            statusLevel = "loading"
            statusText = StudioStrings.restoringDemoSource
            actions.loadDemo?()
        case .recentImport:
            guard hasRecentImport else {
                preferredLaunchSource = .bundled
                statusLevel = "warn"
                statusText = StudioStrings.recentImportUnavailableFallback
                return
            }
            statusLevel = "loading"
            statusText = StudioStrings.reopeningRecentImport
            reopenRecentImport()
        case .recentRemote:
            guard hasRecentRemoteURL else {
                preferredLaunchSource = .bundled
                statusLevel = "warn"
                statusText = StudioStrings.recentRemoteUnavailableFallback
                return
            }
            statusLevel = "loading"
            statusText = StudioStrings.restoringRemoteSource
            reopenRecentRemoteURL()
        }
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
            preferredLaunchSource = .recentImport
            clearError()
            sourceLabel = StudioStrings.localFile
            sourceValue = url.lastPathComponent
            statusLevel = "loading"
            statusText = StudioStrings.importingFileNamed(url.lastPathComponent)
            nativeRecoveryIssue = nil
            actions.importPayload?(url.lastPathComponent, fileData)
            hydrateNativeDocument(fileName: url.lastPathComponent, data: fileData, sourceURL: url)
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

    func performRecoveryAction(named title: String) {
        guard let action = recoveryAction(named: title) else { return }
        performRecoveryAction(action)
    }

    func performRecoveryAction(_ action: StudioRecoveryAction) {
        switch action {
        case .reopenRecentImport:
            reopenRecentImport()
        case .reopenRecentRemoteURL:
            reopenRecentRemoteURL()
        case .loadBundledStudio:
            loadBundledStudio()
        }
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
            self.breadcrumb = breadcrumb.isEmpty ? StudioStrings.bundledStudio : breadcrumb
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

    private func hydrateNativeDocument(fileName: String, data: Data, sourceURL: URL?) {
        nativeErrorMessage = nil
        nativeRecoveryIssue = nil
        Task {
            do {
                let document = try Self.makeNativeDocument(fileName: fileName, data: data, sourceURL: sourceURL)
                await MainActor.run {
                    self.nativeDocument = document
                    self.nativeErrorMessage = nil
                    self.nativeRecoveryIssue = nil
                }
            } catch {
                await MainActor.run {
                    self.nativeDocument = nil
                    self.nativeErrorMessage = error.localizedDescription
                    self.nativeRecoveryIssue = self.makeRecoveryIssue(from: error, remote: false)
                    if self.errorMessage == nil {
                        self.statusLevel = "warn"
                        self.statusText = StudioStrings.nativePreviewUnavailableForSource
                    }
                }
            }
        }
    }

    private func hydrateNativeDocumentFromRemoteURL(_ url: URL) {
        nativeErrorMessage = nil
        nativeRecoveryIssue = nil
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let fileName = url.lastPathComponent.isEmpty ? "remote-source" : url.lastPathComponent
                let document = try Self.makeNativeDocument(fileName: fileName, data: data, sourceURL: url)
                await MainActor.run {
                    self.nativeDocument = document
                    self.nativeErrorMessage = nil
                    self.nativeRecoveryIssue = nil
                }
            } catch {
                await MainActor.run {
                    self.nativeDocument = nil
                    self.nativeErrorMessage = error.localizedDescription
                    self.nativeRecoveryIssue = self.makeRecoveryIssue(from: error, remote: true)
                    if self.errorMessage == nil {
                        self.statusLevel = "warn"
                        self.statusText = StudioStrings.remotePreviewUnavailable
                    }
                }
            }
        }
    }

    private static func makeNativeDocument(fileName: String, data: Data, sourceURL: URL?) throws -> StudioNativeDocument {
        let resolvedSource = try resolveNativeSource(fileName: fileName, data: data, sourceURL: sourceURL)
        guard
            let object = try JSONSerialization.jsonObject(with: resolvedSource.designData) as? [String: Any]
        else {
            throw StudioNativeImportError.invalidDesignJSON
        }
        return try parseNativeDocument(fileName: fileName, object: object, assetRootURL: resolvedSource.assetRootURL)
    }

    private static func resolveNativeSource(fileName: String, data: Data, sourceURL: URL?) throws -> (designData: Data, assetRootURL: URL?) {
        let lowercasedName = fileName.lowercased()
        let isArchive = lowercasedName.hasSuffix(".humblebundle")
            || lowercasedName.hasSuffix(".zip")
            || data.starts(with: [0x50, 0x4B, 0x03, 0x04])

        guard isArchive else {
            let assetRootURL: URL?
            if let sourceURL {
                assetRootURL = sourceURL.deletingLastPathComponent()
            } else {
                assetRootURL = nil
            }
            return (data, assetRootURL)
        }

        #if os(macOS)
        let fileManager = FileManager.default
        let workingDirectory = fileManager.temporaryDirectory.appendingPathComponent("HumbleStudioNativeImport-\(UUID().uuidString)", isDirectory: true)
        let archiveURL = workingDirectory.appendingPathComponent(fileName.isEmpty ? "bundle.humblebundle" : fileName)
        let extractedURL = workingDirectory.appendingPathComponent("contents", isDirectory: true)
        try fileManager.createDirectory(at: extractedURL, withIntermediateDirectories: true)
        try data.write(to: archiveURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-oq", archiveURL.path, "-d", extractedURL.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw StudioNativeImportError.invalidArchive
        }

        let designURL = extractedURL.appendingPathComponent("design.json")
        guard fileManager.fileExists(atPath: designURL.path) else {
            throw StudioNativeImportError.missingDesignJSON
        }

        return (try Data(contentsOf: designURL), extractedURL)
        #else
        throw StudioNativeImportError.unsupportedBundlePlatform
        #endif
    }

    private static func parseNativeDocument(fileName: String, object: [String: Any], assetRootURL: URL?) throws -> StudioNativeDocument {
        let meta = object["meta"] as? [String: Any] ?? [:]
        let assets = object["assets"] as? [String: Any] ?? [:]
        let navigation = object["navigation"] as? [String: Any] ?? [:]
        let tokens = object["tokens"] as? [String: Any] ?? [:]

        let colors = parseColorTokens(tokens["colors"] as? [String: Any] ?? [:])
        let gradients = parseGradientTokens(tokens["gradients"] as? [String: Any] ?? [:])
        let typography = parseTypographyTokens(tokens["typography"] as? [[String: Any]] ?? [])
        let spacing = parseMetricTokens(tokens["spacing"] as? [String: Any] ?? [:], defaultKind: "padding")
        let radius = parseMetricTokens(tokens["radius"] as? [String: Any] ?? [:], defaultKind: "cornerRadius")
        let icons = parseIconTokens(tokens["icons"] as? [[String: Any]] ?? [])
        let components = parseComponentItems(object["components"] as? [[String: Any]] ?? [])
        let views = parseViewItems(object["views"] as? [[String: Any]] ?? [])

        return StudioNativeDocument(
            appName: (meta["name"] as? String) ?? fileName,
            appVersion: (meta["version"] as? String) ?? "",
            appDescription: (meta["description"] as? String) ?? "",
            assetRootURL: assetRootURL,
            iconBasePath: assets["iconBasePath"] as? String,
            snapshotBasePath: assets["snapshotBasePath"] as? String,
            navigationRootID: navigation["root"] as? String,
            navigationType: (navigation["type"] as? String) ?? "stack",
            colors: colors,
            gradients: gradients,
            typography: typography,
            spacing: spacing,
            radius: radius,
            icons: icons,
            components: components,
            views: views
        )
    }

    private static func parseColorTokens(_ object: [String: Any]) -> [StudioNativeDocument.ColorToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            let references = value["references"] as? [String: Any] ?? [:]
            return StudioNativeDocument.ColorToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                lightHex: (value["light"] as? String) ?? "#000000",
                darkHex: (value["dark"] as? String) ?? ((value["light"] as? String) ?? "#000000"),
                referenceCount: parseReferenceCount(from: references),
                sourcePaths: parseReferencePaths(references["source"] as? [[String: Any]] ?? []),
                derivedGradientIDs: parseReferenceIDs(references["derived"] as? [[String: Any]] ?? [], matching: "gradient")
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseGradientTokens(_ object: [String: Any]) -> [StudioNativeDocument.GradientToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            let references = value["references"] as? [String: Any] ?? [:]
            return StudioNativeDocument.GradientToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                lightColors: (value["light"] as? [String]) ?? [],
                darkColors: (value["dark"] as? [String]) ?? ((value["light"] as? [String]) ?? []),
                kind: (value["type"] as? String) ?? "gradient",
                referenceCount: parseReferenceCount(from: references),
                usage: (value["usage"] as? String) ?? "",
                swiftUI: (value["swiftui"] as? String) ?? "",
                tokenColors: value["tokenColors"] as? [String] ?? [],
                sourcePaths: parseReferencePaths(references["source"] as? [[String: Any]] ?? []),
                designComponentIDs: parseReferenceIDs(references["design"] as? [[String: Any]] ?? [], matching: "component")
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseTypographyTokens(_ array: [[String: Any]]) -> [StudioNativeDocument.TypographyToken] {
        array.enumerated().compactMap { index, value in
            guard let role = value["role"] as? String else { return nil }
            let references = value["references"] as? [String: Any] ?? [:]
            return StudioNativeDocument.TypographyToken(
                id: role,
                role: role,
                preview: (value["preview"] as? String) ?? "HumbleStudio",
                swiftUI: (value["swiftui"] as? String) ?? "",
                size: (value["size"] as? NSNumber)?.doubleValue ?? Double(value["size"] as? Int ?? 0),
                weight: value["weight"] as? Int ?? 400,
                referenceCount: parseReferenceCount(from: references),
                sourcePaths: parseReferencePaths(references["source"] as? [[String: Any]] ?? [])
            )
        }
        .sorted { lhs, rhs in
            lhs.role == rhs.role ? lhs.id < rhs.id : lhs.role < rhs.role
        }
    }

    private static func parseMetricTokens(_ object: [String: Any], defaultKind: String) -> [StudioNativeDocument.MetricToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            let references = value["references"] as? [String: Any] ?? [:]
            return StudioNativeDocument.MetricToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                value: (value["value"] as? String) ?? String(describing: value["value"] ?? "—"),
                usage: (value["usage"] as? String) ?? "",
                kind: (value["kind"] as? String) ?? defaultKind,
                referenceCount: parseReferenceCount(from: references),
                sourcePaths: parseReferencePaths(references["source"] as? [[String: Any]] ?? [])
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseIconTokens(_ array: [[String: Any]]) -> [StudioNativeDocument.IconToken] {
        array.compactMap { value in
            guard let id = value["id"] as? String else { return nil }
            let references = value["references"] as? [String: Any] ?? [:]
            return StudioNativeDocument.IconToken(
                id: id,
                name: (value["name"] as? String) ?? humanizedIdentifier(id),
                symbol: (value["symbol"] as? String) ?? "",
                assetPath: (value["path"] as? String) ?? "",
                description: (value["description"] as? String) ?? "",
                referenceCount: parseReferenceCount(from: references),
                sourcePaths: parseReferencePaths(references["source"] as? [[String: Any]] ?? [])
            )
        }
        .sorted { lhs, rhs in lhs.name < rhs.name }
    }

    private static func parseComponentItems(_ array: [[String: Any]]) -> [StudioNativeDocument.ComponentItem] {
        array.compactMap { value in
            guard let id = value["id"] as? String else { return nil }
            let tokenDependencies = value["tokenDependencies"] as? [String: Any] ?? [:]
            let tokenSummary = tokenDependencies["summary"] as? [String: Any] ?? [:]
            let sourceSnippet = value["sourceSnippet"] as? [String: Any] ?? [:]
            return StudioNativeDocument.ComponentItem(
                id: id,
                name: (value["name"] as? String) ?? humanizedIdentifier(id),
                group: (value["group"] as? String) ?? "Ungrouped",
                renderer: (value["renderer"] as? String) ?? "component",
                summary: (value["description"] as? String) ?? "",
                swiftUI: (value["swiftui"] as? String) ?? "",
                sourcePath: (value["source"] as? String) ?? "",
                defaultState: (value["defaultState"] as? String) ?? "",
                statesCount: (value["states"] as? [[String: Any]])?.count ?? 0,
                states: parseStateSummaries(value["states"] as? [[String: Any]] ?? []),
                designDependencies: parseTokenDependencySet(tokenDependencies["design"] as? [String: Any] ?? [:]),
                sourceDependencies: parseTokenDependencySet(tokenDependencies["source"] as? [String: Any] ?? [:]),
                designTokenCategories: tokenSummary["categories"] as? [String] ?? [],
                designTokenCount: tokenSummary["designTokenCount"] as? Int ?? 0,
                sourceTokenCount: tokenSummary["sourceTokenCount"] as? Int ?? 0,
                sourceSnippetSymbol: (sourceSnippet["symbol"] as? String) ?? "",
                sourceSnippetRange: sourceSnippetRange(sourceSnippet),
                snapshot: parseSnapshotAsset(value["snapshot"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseViewItems(_ array: [[String: Any]]) -> [StudioNativeDocument.ViewItem] {
        array.compactMap { value in
            guard let id = value["id"] as? String else { return nil }
            let actions = value["actions"] as? [String: Any] ?? [:]
            let tokenDependencies = value["tokenDependencies"] as? [String: Any] ?? [:]
            let tokenSummary = tokenDependencies["summary"] as? [String: Any] ?? [:]
            let sourceSnippet = value["sourceSnippet"] as? [String: Any] ?? [:]
            return StudioNativeDocument.ViewItem(
                id: id,
                name: (value["name"] as? String) ?? humanizedIdentifier(id),
                summary: (value["description"] as? String) ?? "",
                presentation: (value["presentation"] as? String) ?? "screen",
                sourcePath: (value["source"] as? String) ?? "",
                root: value["root"] as? Bool ?? false,
                defaultState: (value["defaultState"] as? String) ?? "",
                statesCount: (value["states"] as? [Any])?.count ?? 0,
                componentsCount: (value["components"] as? [Any])?.count ?? 0,
                components: value["components"] as? [String] ?? [],
                states: value["states"] as? [String] ?? [],
                entryPoints: value["entryPoints"] as? [String] ?? [],
                primaryActions: actions["primary"] as? [String] ?? [],
                secondaryActions: actions["secondary"] as? [String] ?? [],
                navigationCount: (value["navigatesTo"] as? [Any])?.count ?? 0,
                navigatesTo: parseNavigationSummaries(value["navigatesTo"] as? [[String: Any]] ?? []),
                designDependencies: parseTokenDependencySet(tokenDependencies["design"] as? [String: Any] ?? [:]),
                sourceDependencies: parseTokenDependencySet(tokenDependencies["source"] as? [String: Any] ?? [:]),
                designTokenCategories: tokenSummary["categories"] as? [String] ?? [],
                designTokenCount: tokenSummary["designTokenCount"] as? Int ?? 0,
                sourceTokenCount: tokenSummary["sourceTokenCount"] as? Int ?? 0,
                sourceSnippetSymbol: (sourceSnippet["symbol"] as? String) ?? "",
                sourceSnippetRange: sourceSnippetRange(sourceSnippet),
                sheetPatternsCount: (value["sheetPatterns"] as? [Any])?.count ?? 0,
                overlayPatternsCount: (value["overlayPatterns"] as? [Any])?.count ?? 0,
                snapshot: parseSnapshotAsset(value["snapshot"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            if lhs.root != rhs.root { return lhs.root && !rhs.root }
            return lhs.name < rhs.name
        }
    }

    private static func parseNavigationSummaries(_ array: [[String: Any]]) -> [StudioNativeDocument.ViewItem.NavigationSummary] {
        array.enumerated().compactMap { index, value in
            guard let targetID = value["viewId"] as? String else { return nil }
            let trigger = value["trigger"] as? String ?? ""
            let type = value["type"] as? String ?? "navigate"
            return StudioNativeDocument.ViewItem.NavigationSummary(
                id: "\(targetID)-\(type)-\(index)",
                targetID: targetID,
                trigger: trigger,
                type: type
            )
        }
    }

    private static func parseSnapshotAsset(_ value: [String: Any]?) -> StudioNativeDocument.SnapshotAsset? {
        guard let value else { return nil }
        let defaultPath = value["path"] as? String
        let darkPath = value["dark"] as? String
        let lightPath = value["light"] as? String
        if [defaultPath, darkPath, lightPath].allSatisfy({ $0 == nil || $0?.isEmpty == true }) {
            return nil
        }
        return StudioNativeDocument.SnapshotAsset(
            name: (value["name"] as? String) ?? "Snapshot",
            defaultPath: defaultPath,
            lightPath: lightPath,
            darkPath: darkPath
        )
    }

    private static func parseStateSummaries(_ array: [[String: Any]]) -> [StudioNativeDocument.ComponentItem.StateSummary] {
        array.compactMap { value in
            guard let id = value["id"] as? String else { return nil }
            return StudioNativeDocument.ComponentItem.StateSummary(
                id: id,
                label: (value["label"] as? String) ?? humanizedIdentifier(id),
                detail: (value["description"] as? String) ?? ""
            )
        }
    }

    private static func sourceSnippetRange(_ value: [String: Any]) -> String {
        let startLine = value["startLine"] as? Int
        let endLine = value["endLine"] as? Int
        switch (startLine, endLine) {
        case let (.some(start), .some(end)):
            return "lines \(start)-\(end)"
        case let (.some(start), .none):
            return "line \(start)"
        default:
            return ""
        }
    }

    private static func parseReferenceCount(from references: [String: Any]?) -> Int {
        if let count = references?["count"] as? Int {
            return count
        }
        return 0
    }

    private static func parseReferencePaths(_ array: [[String: Any]]) -> [String] {
        array.compactMap { $0["path"] as? String }
    }

    private static func parseReferenceIDs(_ array: [[String: Any]], matching type: String) -> [String] {
        array.compactMap { value in
            guard value["type"] as? String == type else { return nil }
            return value["id"] as? String
        }
    }

    private static func parseTokenDependencySet(_ value: [String: Any]) -> StudioNativeDocument.TokenDependencySet {
        StudioNativeDocument.TokenDependencySet(
            colors: parseDependencyIDs(value["colors"] as? [[String: Any]] ?? []),
            gradients: parseDependencyIDs(value["gradients"] as? [[String: Any]] ?? []),
            spacing: parseDependencyIDs(value["spacing"] as? [[String: Any]] ?? []),
            radius: parseDependencyIDs(value["radius"] as? [[String: Any]] ?? []),
            typography: parseDependencyIDs(value["typography"] as? [[String: Any]] ?? []),
            textTones: parseDependencyIDs(value["textTones"] as? [[String: Any]] ?? []),
            surfaces: parseDependencyIDs(value["surfaces"] as? [[String: Any]] ?? []),
            preferredIcons: parseDependencyIDs(value["preferredIcons"] as? [[String: Any]] ?? []),
            primitives: parseDependencyIDs(value["primitives"] as? [[String: Any]] ?? []),
            actionRoles: parseDependencyIDs(value["actionRoles"] as? [[String: Any]] ?? []),
            frames: parseDependencyIDs(value["frames"] as? [[String: Any]] ?? [])
        )
    }

    private static func parseDependencyIDs(_ array: [[String: Any]]) -> [String] {
        array.compactMap { $0["id"] as? String }
    }

    private static func humanizedIdentifier(_ value: String) -> String {
        let separated = value.unicodeScalars.reduce(into: "") { partial, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar), !partial.isEmpty {
                partial.append(" ")
            } else if scalar == "_" || scalar == "-" {
                partial.append(" ")
                return
            }
            partial.append(String(scalar))
        }
        return separated
            .split(separator: " ")
            .map { fragment in
                fragment.prefix(1).uppercased() + fragment.dropFirst()
            }
            .joined(separator: " ")
    }

    private func makeRecoveryIssue(from error: Error, remote: Bool) -> StudioNativeRecoveryIssue {
        let primaryAction: StudioRecoveryAction = hasRecentImport ? .reopenRecentImport : (hasRecentRemoteURL ? .reopenRecentRemoteURL : .loadBundledStudio)
        let secondaryActions = availableRecoveryActions(excluding: primaryAction)

        if let importError = error as? StudioNativeImportError {
            switch importError {
            case .invalidArchive:
                return StudioNativeRecoveryIssue(
                    title: StudioStrings.recoveryIssueArchive,
                    detail: error.localizedDescription,
                    primaryAction: primaryAction,
                    secondaryActions: secondaryActions
                )
            case .missingDesignJSON:
                return StudioNativeRecoveryIssue(
                    title: StudioStrings.recoveryIssueManifest,
                    detail: error.localizedDescription,
                    primaryAction: primaryAction,
                    secondaryActions: secondaryActions
                )
            case .invalidDesignJSON:
                return StudioNativeRecoveryIssue(
                    title: StudioStrings.recoveryIssueDecode,
                    detail: error.localizedDescription,
                    primaryAction: primaryAction,
                    secondaryActions: secondaryActions
                )
            case .unsupportedBundlePlatform:
                return StudioNativeRecoveryIssue(
                    title: StudioStrings.recoveryIssuePlatform,
                    detail: error.localizedDescription,
                    primaryAction: .loadBundledStudio,
                    secondaryActions: availableRecoveryActions(excluding: .loadBundledStudio)
                )
            }
        }

        return StudioNativeRecoveryIssue(
            title: remote ? StudioStrings.recoveryIssueRemote : StudioStrings.recoveryIssueLocal,
            detail: error.localizedDescription,
            primaryAction: primaryAction,
            secondaryActions: secondaryActions
        )
    }

    private func availableRecoveryActions(excluding primaryAction: StudioRecoveryAction) -> [StudioRecoveryAction] {
        let all: [StudioRecoveryAction] = [
            hasRecentImport ? .reopenRecentImport : nil,
            hasRecentRemoteURL ? .reopenRecentRemoteURL : nil,
            .loadBundledStudio
        ].compactMap { $0 }

        return all.filter { $0 != primaryAction }
    }

    private func title(for action: StudioRecoveryAction) -> String {
        switch action {
        case .reopenRecentImport:
            return StudioStrings.reopenRecentImport
        case .reopenRecentRemoteURL:
            return StudioStrings.reopenRecentRemoteURL
        case .loadBundledStudio:
            return StudioStrings.loadBundledStudioAction
        }
    }

    private func recoveryAction(named title: String) -> StudioRecoveryAction? {
        let actions: [StudioRecoveryAction] = [.reopenRecentImport, .reopenRecentRemoteURL, .loadBundledStudio]
        return actions.first(where: { self.title(for: $0) == title })
    }
}
