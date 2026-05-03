import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct StudioMacWorkspaceSourceSession: Equatable {
    var isImportingFile = false
    var isImportingRemoteURL = false
    var remoteURLDraft = ""

    mutating func presentImport() {
        isImportingFile = true
    }

    mutating func presentRemoteURL(recentRemoteURL: String?) {
        remoteURLDraft = recentRemoteURL ?? ""
        isImportingRemoteURL = true
    }

    mutating func dismissRemoteURL() {
        isImportingRemoteURL = false
    }
}

struct StudioMacWorkspaceSourceCommandContext {
    let hasRecentImport: Bool
    let recentImportName: String?
    let hasRecentRemoteURL: Bool
    let recentRemoteURL: String?
    let openImport: () -> Void
    let openRemoteURL: () -> Void
    let reopenRecentImport: () -> Void
    let reopenRecentRemoteURL: () -> Void
    let loadHome: () -> Void
    let reload: () -> Void
}

struct StudioMacWorkspaceEventCommandContext {
    let recentRemoteURL: String?
    let openQuickOpen: () -> Void
    let openImport: () -> Void
    let reopenRecentImport: () -> Void
    let openRemoteURL: () -> Void
    let reopenRecentRemoteURL: () -> Void
    let navigateBack: () -> Void
    let navigateForward: () -> Void
    let loadDemo: () -> Void
    let loadHome: () -> Void
    let reloadCurrentSelection: () -> Void
    let handleIncomingURL: (URL) -> Void
}

struct StudioMacWorkspaceObservedRouteContext {
    let selection: StudioNativeDestination?
    let tokenSelection: StudioNativeTokenSelection?
    let iconID: String?
    let typographyID: String?
    let metricSelection: StudioNativeMetricSelection?
    let componentID: String?
    let viewID: String?
    let navigationViewID: String?
    let syncRouteFromState: () -> Void
}

struct StudioMacWorkspaceToolbar: ToolbarContent {
    let canNavigateBack: Bool
    let canNavigateForward: Bool
    let source: StudioMacWorkspaceSourceCommandContext

    let navigateBack: () -> Void
    let navigateForward: () -> Void
    let openQuickOpen: () -> Void
    let showLegacyWeb: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                navigateBack()
            } label: {
                Label(StudioStrings.back, systemImage: "chevron.backward")
            }
            .disabled(!canNavigateBack)

            Button {
                navigateForward()
            } label: {
                Label(StudioStrings.forward, systemImage: "chevron.forward")
            }
            .disabled(!canNavigateForward)

            Button {
                openQuickOpen()
            } label: {
                Label(StudioStrings.quickOpen, systemImage: "magnifyingglass")
            }

            Button {
                source.openImport()
            } label: {
                Label(StudioStrings.open, systemImage: "folder")
            }

            Button {
                source.openRemoteURL()
            } label: {
                Label(StudioStrings.url, systemImage: "link")
            }

            if source.hasRecentImport {
                Button {
                    source.reopenRecentImport()
                } label: {
                    Label(StudioStrings.recent, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .help(source.recentImportName ?? StudioStrings.reopenRecentImportHelp)
            }

            if source.hasRecentRemoteURL {
                Button {
                    source.reopenRecentRemoteURL()
                } label: {
                    Label(StudioStrings.recentURL, systemImage: "clock.badge.checkmark")
                }
                .help(source.recentRemoteURL ?? StudioStrings.reopenRecentRemoteURLHelp)
            }

            Button {
                source.loadHome()
            } label: {
                Label(StudioStrings.home, systemImage: "house")
            }

            Button {
                source.reload()
            } label: {
                Label(StudioStrings.reload, systemImage: "arrow.clockwise")
            }

            Button {
                showLegacyWeb()
            } label: {
                Label(StudioStrings.legacyWeb, systemImage: "globe")
            }
        }
    }
}

enum StudioMacWorkspaceImportSupport {
    static var supportedImportTypes: [UTType] {
        [UTType(filenameExtension: "humblebundle") ?? .zip, .zip, .json]
    }

    static func handleImportResult(
        _ result: Result<[URL], Error>,
        importFile: (URL) -> Void,
        reportError: (Error) -> Void
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(url)
        case .failure(let error):
            reportError(error)
        }
    }

    static func handleFileDrop(
        _ providers: [NSItemProvider],
        importFile: @escaping (URL) -> Void,
        reportError: @escaping (Error) -> Void
    ) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error {
                Task { @MainActor in
                    reportError(error)
                }
                return
            }

            let resolvedURL: URL?
            if let url = item as? URL {
                resolvedURL = url
            } else if let data = item as? Data {
                resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                resolvedURL = nil
            }

            guard let resolvedURL else { return }
            Task { @MainActor in
                importFile(resolvedURL)
            }
        }

        return true
    }
}

private struct StudioMacWorkspaceEventBridgeModifier: ViewModifier {
    @Binding var isQuickOpenPresented: Bool
    @Binding var isImportingFile: Bool
    @Binding var isImportingRemoteURL: Bool
    @Binding var remoteURLDraft: String

    let commands: StudioMacWorkspaceEventCommandContext
    let observedRoute: StudioMacWorkspaceObservedRouteContext

    func body(content: Content) -> some View {
        routeObservedContent(
            eventObservedContent(content)
        )
    }

    private func eventObservedContent(_ content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenQuickOpen)) { _ in
                commands.openQuickOpen()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenImport)) { _ in
                commands.openImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentImport)) { _ in
                commands.reopenRecentImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenRemoteURL)) { _ in
                commands.openRemoteURL()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentRemoteURL)) { _ in
                commands.reopenRecentRemoteURL()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioNavigateBack)) { _ in
                commands.navigateBack()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioNavigateForward)) { _ in
                commands.navigateForward()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioLoadDemo)) { _ in
                commands.loadDemo()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioLoadHome)) { _ in
                commands.loadHome()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReload)) { _ in
                commands.reloadCurrentSelection()
            }
            .onOpenURL { url in
                commands.handleIncomingURL(url)
            }
    }

    private func routeObservedContent<V: View>(_ content: V) -> some View {
        content
            .onChange(of: observedRoute.selection) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.tokenSelection) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.iconID) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.typographyID) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.metricSelection) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.componentID) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.viewID) { _, _ in
                observedRoute.syncRouteFromState()
            }
            .onChange(of: observedRoute.navigationViewID) { _, _ in
                observedRoute.syncRouteFromState()
            }
    }
}

extension View {
    func studioMacWorkspaceEventBridge(
        isQuickOpenPresented: Binding<Bool>,
        isImportingFile: Binding<Bool>,
        isImportingRemoteURL: Binding<Bool>,
        remoteURLDraft: Binding<String>,
        commands: StudioMacWorkspaceEventCommandContext,
        observedRoute: StudioMacWorkspaceObservedRouteContext
    ) -> some View {
        modifier(
            StudioMacWorkspaceEventBridgeModifier(
                isQuickOpenPresented: isQuickOpenPresented,
                isImportingFile: isImportingFile,
                isImportingRemoteURL: isImportingRemoteURL,
                remoteURLDraft: remoteURLDraft,
                commands: commands,
                observedRoute: observedRoute
            )
        )
    }
}
