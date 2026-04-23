import Foundation
import Combine

struct StudioNativeDocument: Equatable {
    struct ColorToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let lightHex: String
        let darkHex: String
        let referenceCount: Int
    }

    struct GradientToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let lightColors: [String]
        let darkColors: [String]
        let kind: String
        let referenceCount: Int
    }

    struct TypographyToken: Identifiable, Equatable {
        let id: String
        let role: String
        let preview: String
        let swiftUI: String
        let size: Double
        let weight: Int
        let referenceCount: Int
    }

    struct MetricToken: Identifiable, Equatable {
        let id: String
        let name: String
        let group: String
        let value: String
        let usage: String
        let kind: String
        let referenceCount: Int
    }

    struct IconToken: Identifiable, Equatable {
        let id: String
        let name: String
        let symbol: String
        let assetPath: String
        let description: String
        let referenceCount: Int
    }

    let appName: String
    let appVersion: String
    let appDescription: String
    let assetRootURL: URL?
    let iconBasePath: String?
    let colors: [ColorToken]
    let gradients: [GradientToken]
    let typography: [TypographyToken]
    let spacing: [MetricToken]
    let radius: [MetricToken]
    let icons: [IconToken]

    func resolvedIconURL(for icon: IconToken) -> URL? {
        resolvedAssetURL(basePath: iconBasePath, relativePath: icon.assetPath)
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
    @Published var pageTitle = "HumbleStudio"
    @Published var breadcrumb = "Bundled studio"
    @Published var sourceLabel = "Bundled studio"
    @Published var sourceValue = "Embedded app assets"
    @Published var statusLevel = "loading"
    @Published var statusText = "Loading bundled studio…"
    @Published var recentImportName = UserDefaults.standard.string(forKey: RecentImportStore.nameKey)
    @Published var recentRemoteURL = UserDefaults.standard.string(forKey: RecentRemoteStore.urlKey)
    @Published var nativeDocument: StudioNativeDocument?
    @Published var nativeErrorMessage: String?

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
        statusText = "Loading bundled studio…"
    }

    func reload() {
        isPageReady = false
        statusLevel = "loading"
        statusText = "Reloading studio…"
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
        sourceLabel = "Bundled studio"
        sourceValue = "Embedded app assets"
        statusLevel = "loading"
        statusText = "Loading bundled studio…"
        nativeDocument = nil
        nativeErrorMessage = nil
        actions.loadBundledStudio?()
    }

    func loadDemo() {
        preferredLaunchSource = .demo
        statusLevel = "loading"
        statusText = "Loading demo config…"
        nativeDocument = nil
        nativeErrorMessage = nil
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
        preferredLaunchSource = .recentRemote
        clearError()
        sourceLabel = "Remote URL"
        sourceValue = trimmed
        statusLevel = "loading"
        statusText = "Loading remote source…"
        actions.loadRemoteURL?(trimmed)
        hydrateNativeDocumentFromRemoteURL(parsed)
    }

    func reopenRecentRemoteURL() {
        guard let recentRemoteURL, !recentRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusLevel = "warn"
            statusText = "No recent remote URL is available yet."
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
            statusText = "Unsupported incoming URL."
            return
        }

        if ["http", "https"].contains(scheme) {
            loadRemoteURL(url.absoluteString)
            return
        }

        statusLevel = "warn"
        statusText = "Only file, http, and https URLs are supported."
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
            statusText = "Restoring demo source…"
            actions.loadDemo?()
        case .recentImport:
            guard hasRecentImport else {
                preferredLaunchSource = .bundled
                statusLevel = "warn"
                statusText = "Recent import is unavailable. Showing bundled studio."
                return
            }
            statusLevel = "loading"
            statusText = "Reopening recent import…"
            reopenRecentImport()
        case .recentRemote:
            guard hasRecentRemoteURL else {
                preferredLaunchSource = .bundled
                statusLevel = "warn"
                statusText = "Recent remote URL is unavailable. Showing bundled studio."
                return
            }
            statusLevel = "loading"
            statusText = "Restoring remote source…"
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
            sourceLabel = "Local file"
            sourceValue = url.lastPathComponent
            statusLevel = "loading"
            statusText = "Importing \(url.lastPathComponent)…"
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

    private func hydrateNativeDocument(fileName: String, data: Data, sourceURL: URL?) {
        nativeErrorMessage = nil
        Task {
            do {
                let document = try Self.makeNativeDocument(fileName: fileName, data: data, sourceURL: sourceURL)
                await MainActor.run {
                    self.nativeDocument = document
                    self.nativeErrorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.nativeDocument = nil
                    self.nativeErrorMessage = error.localizedDescription
                    if self.errorMessage == nil {
                        self.statusLevel = "warn"
                        self.statusText = "Native preview is unavailable for this source."
                    }
                }
            }
        }
    }

    private func hydrateNativeDocumentFromRemoteURL(_ url: URL) {
        nativeErrorMessage = nil
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let fileName = url.lastPathComponent.isEmpty ? "remote-source" : url.lastPathComponent
                let document = try Self.makeNativeDocument(fileName: fileName, data: data, sourceURL: url)
                await MainActor.run {
                    self.nativeDocument = document
                    self.nativeErrorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.nativeDocument = nil
                    self.nativeErrorMessage = error.localizedDescription
                    if self.errorMessage == nil {
                        self.statusLevel = "warn"
                        self.statusText = "Remote source loaded, but native preview could not be prepared."
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
        let tokens = object["tokens"] as? [String: Any] ?? [:]

        let colors = parseColorTokens(tokens["colors"] as? [String: Any] ?? [:])
        let gradients = parseGradientTokens(tokens["gradients"] as? [String: Any] ?? [:])
        let typography = parseTypographyTokens(tokens["typography"] as? [[String: Any]] ?? [])
        let spacing = parseMetricTokens(tokens["spacing"] as? [String: Any] ?? [:], defaultKind: "padding")
        let radius = parseMetricTokens(tokens["radius"] as? [String: Any] ?? [:], defaultKind: "cornerRadius")
        let icons = parseIconTokens(tokens["icons"] as? [[String: Any]] ?? [])

        return StudioNativeDocument(
            appName: (meta["name"] as? String) ?? fileName,
            appVersion: (meta["version"] as? String) ?? "",
            appDescription: (meta["description"] as? String) ?? "",
            assetRootURL: assetRootURL,
            iconBasePath: assets["iconBasePath"] as? String,
            colors: colors,
            gradients: gradients,
            typography: typography,
            spacing: spacing,
            radius: radius,
            icons: icons
        )
    }

    private static func parseColorTokens(_ object: [String: Any]) -> [StudioNativeDocument.ColorToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            return StudioNativeDocument.ColorToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                lightHex: (value["light"] as? String) ?? "#000000",
                darkHex: (value["dark"] as? String) ?? ((value["light"] as? String) ?? "#000000"),
                referenceCount: parseReferenceCount(from: value["references"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseGradientTokens(_ object: [String: Any]) -> [StudioNativeDocument.GradientToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            return StudioNativeDocument.GradientToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                lightColors: (value["light"] as? [String]) ?? [],
                darkColors: (value["dark"] as? [String]) ?? ((value["light"] as? [String]) ?? []),
                kind: (value["type"] as? String) ?? "gradient",
                referenceCount: parseReferenceCount(from: value["references"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseTypographyTokens(_ array: [[String: Any]]) -> [StudioNativeDocument.TypographyToken] {
        array.enumerated().compactMap { index, value in
            guard let role = value["role"] as? String else { return nil }
            return StudioNativeDocument.TypographyToken(
                id: role,
                role: role,
                preview: (value["preview"] as? String) ?? "HumbleStudio",
                swiftUI: (value["swiftui"] as? String) ?? "",
                size: (value["size"] as? NSNumber)?.doubleValue ?? Double(value["size"] as? Int ?? 0),
                weight: value["weight"] as? Int ?? 400,
                referenceCount: parseReferenceCount(from: value["references"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            lhs.role == rhs.role ? lhs.id < rhs.id : lhs.role < rhs.role
        }
    }

    private static func parseMetricTokens(_ object: [String: Any], defaultKind: String) -> [StudioNativeDocument.MetricToken] {
        object.compactMap { key, rawValue in
            guard let value = rawValue as? [String: Any] else { return nil }
            return StudioNativeDocument.MetricToken(
                id: key,
                name: humanizedIdentifier(key),
                group: (value["group"] as? String) ?? "Ungrouped",
                value: (value["value"] as? String) ?? String(describing: value["value"] ?? "—"),
                usage: (value["usage"] as? String) ?? "",
                kind: (value["kind"] as? String) ?? defaultKind,
                referenceCount: parseReferenceCount(from: value["references"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in
            lhs.group == rhs.group ? lhs.name < rhs.name : lhs.group < rhs.group
        }
    }

    private static func parseIconTokens(_ array: [[String: Any]]) -> [StudioNativeDocument.IconToken] {
        array.compactMap { value in
            guard let id = value["id"] as? String else { return nil }
            return StudioNativeDocument.IconToken(
                id: id,
                name: (value["name"] as? String) ?? humanizedIdentifier(id),
                symbol: (value["symbol"] as? String) ?? "",
                assetPath: (value["path"] as? String) ?? "",
                description: (value["description"] as? String) ?? "",
                referenceCount: parseReferenceCount(from: value["references"] as? [String: Any])
            )
        }
        .sorted { lhs, rhs in lhs.name < rhs.name }
    }

    private static func parseReferenceCount(from references: [String: Any]?) -> Int {
        if let count = references?["count"] as? Int {
            return count
        }
        return 0
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
}
