import SwiftUI
import UniformTypeIdentifiers
import AppKit

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

    let recentRemoteURL: String?
    let selection: StudioNativeDestination?
    let tokenSelection: StudioNativeTokenSelection?
    let iconID: String?
    let typographyID: String?
    let metricSelection: StudioNativeMetricSelection?
    let componentID: String?
    let viewID: String?
    let navigationViewID: String?

    let reopenRecentImport: () -> Void
    let reopenRecentRemoteURL: () -> Void
    let navigateBack: () -> Void
    let navigateForward: () -> Void
    let loadDemo: () -> Void
    let loadHome: () -> Void
    let reloadCurrentSelection: () -> Void
    let handleIncomingURL: (URL) -> Void
    let syncRouteFromState: () -> Void

    func body(content: Content) -> some View {
        routeObservedContent(
            eventObservedContent(content)
        )
    }

    private func eventObservedContent(_ content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenQuickOpen)) { _ in
                isQuickOpenPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenImport)) { _ in
                isImportingFile = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentImport)) { _ in
                reopenRecentImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioOpenRemoteURL)) { _ in
                remoteURLDraft = recentRemoteURL ?? ""
                isImportingRemoteURL = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentRemoteURL)) { _ in
                reopenRecentRemoteURL()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioNavigateBack)) { _ in
                navigateBack()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioNavigateForward)) { _ in
                navigateForward()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioLoadDemo)) { _ in
                loadDemo()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioLoadHome)) { _ in
                loadHome()
            }
            .onReceive(NotificationCenter.default.publisher(for: .studioReload)) { _ in
                reloadCurrentSelection()
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
    }

    private func routeObservedContent<V: View>(_ content: V) -> some View {
        content
            .onChange(of: selection) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: tokenSelection) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: iconID) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: typographyID) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: metricSelection) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: componentID) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: viewID) { _, _ in
                syncRouteFromState()
            }
            .onChange(of: navigationViewID) { _, _ in
                syncRouteFromState()
            }
    }
}

extension View {
    func studioMacWorkspaceEventBridge(
        isQuickOpenPresented: Binding<Bool>,
        isImportingFile: Binding<Bool>,
        isImportingRemoteURL: Binding<Bool>,
        remoteURLDraft: Binding<String>,
        recentRemoteURL: String?,
        selection: StudioNativeDestination?,
        tokenSelection: StudioNativeTokenSelection?,
        iconID: String?,
        typographyID: String?,
        metricSelection: StudioNativeMetricSelection?,
        componentID: String?,
        viewID: String?,
        navigationViewID: String?,
        reopenRecentImport: @escaping () -> Void,
        reopenRecentRemoteURL: @escaping () -> Void,
        navigateBack: @escaping () -> Void,
        navigateForward: @escaping () -> Void,
        loadDemo: @escaping () -> Void,
        loadHome: @escaping () -> Void,
        reloadCurrentSelection: @escaping () -> Void,
        handleIncomingURL: @escaping (URL) -> Void,
        syncRouteFromState: @escaping () -> Void
    ) -> some View {
        modifier(
            StudioMacWorkspaceEventBridgeModifier(
                isQuickOpenPresented: isQuickOpenPresented,
                isImportingFile: isImportingFile,
                isImportingRemoteURL: isImportingRemoteURL,
                remoteURLDraft: remoteURLDraft,
                recentRemoteURL: recentRemoteURL,
                selection: selection,
                tokenSelection: tokenSelection,
                iconID: iconID,
                typographyID: typographyID,
                metricSelection: metricSelection,
                componentID: componentID,
                viewID: viewID,
                navigationViewID: navigationViewID,
                reopenRecentImport: reopenRecentImport,
                reopenRecentRemoteURL: reopenRecentRemoteURL,
                navigateBack: navigateBack,
                navigateForward: navigateForward,
                loadDemo: loadDemo,
                loadHome: loadHome,
                reloadCurrentSelection: reloadCurrentSelection,
                handleIncomingURL: handleIncomingURL,
                syncRouteFromState: syncRouteFromState
            )
        )
    }
}
