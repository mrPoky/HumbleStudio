import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct StudioMacWorkspaceView: View {
    @StateObject private var model = StudioShellModel()
    @State private var isQuickOpenPresented = false
    @State private var isDropTargeted = false
    @State private var componentAppearance: StudioNativeAppearance = .dark
    @State private var viewAppearance: StudioNativeAppearance = .dark
    @State private var routeSession = StudioMacWorkspaceRouteSession()
    @State private var sourceSession = StudioMacWorkspaceSourceSession()

    var body: some View {
        observedWorkspaceView
    }

    private var baseWorkspaceView: some View {
        workspaceSplitView
        .navigationTitle(StudioStrings.appTitle)
        .toolbar {
            shellToolbar
        }
    }

    private var importerWorkspaceView: some View {
        baseWorkspaceView
        .fileImporter(
            isPresented: sourceImportBinding,
            allowedContentTypes: StudioMacWorkspaceImportSupport.supportedImportTypes,
            allowsMultipleSelection: false
        ) { result in
            StudioMacWorkspaceImportSupport.handleImportResult(
                result,
                importFile: model.importFile(at:),
                reportError: model.report(error:)
            )
        }
    }

    private var modalWorkspaceView: some View {
        importerWorkspaceView
        .sheet(isPresented: sourceRemoteURLBinding) {
            remoteURLSheet
        }
        .sheet(isPresented: $isQuickOpenPresented) {
            quickOpenSheet
        }
    }

    private var observedWorkspaceView: some View {
        modalWorkspaceView.studioMacWorkspaceEventBridge(
            isQuickOpenPresented: $isQuickOpenPresented,
            isImportingFile: sourceImportBinding,
            isImportingRemoteURL: sourceRemoteURLBinding,
            remoteURLDraft: sourceRemoteURLDraftBinding,
            commands: eventCommandContext,
            observedRoute: observedRouteContext
        )
    }

    private var workspaceSplitView: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
        }
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            nativeContextBar

            ZStack {
                detailContent

                if isDropTargeted {
                    StudioMacWorkspaceDropOverlay()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            StudioMacWorkspaceImportSupport.handleFileDrop(
                providers,
                importFile: model.importFile(at:),
                reportError: model.report(error:)
            )
        }
    }

    private var sidebar: some View {
        StudioMacWorkspaceSidebar(
            document: model.nativeDocument,
            selection: sidebarSelection,
            reviewQueueCount: model.nativeDocument.map { reviewQueueCounts(for: $0).total },
            navigationEdgeCount: model.nativeDocument.map(navigationEdgeCount(for:))
        )
    }

    @ToolbarContentBuilder
    private var shellToolbar: some ToolbarContent {
        StudioMacWorkspaceToolbar(
            canNavigateBack: canNavigateBack,
            canNavigateForward: canNavigateForward,
            source: sourceCommandContext,
            navigateBack: navigateBack,
            navigateForward: navigateForward,
            openQuickOpen: {
                isQuickOpenPresented = true
            },
            showLegacyWeb: {
                navigateToDestination(.legacyWeb)
            }
        )
    }

    private var detailContent: some View {
        StudioMacWorkspaceDetailContent(
            model: model,
            selection: routeSession.selection,
            selectedTokenSelection: tokenSelectionBinding,
            componentAppearance: $componentAppearance,
            viewAppearance: $viewAppearance,
            selectedComponentID: componentIDBinding,
            selectedViewID: viewIDBinding,
            selectedNavigationViewID: navigationViewIDBinding,
            selectedIconID: iconIDBinding,
            selectedTypographyID: typographyIDBinding,
            selectedMetricSelection: metricSelectionBinding,
            inspectComponent: inspectComponent,
            inspectView: inspectView
        )
    }

    private var remoteURLSheet: some View {
        StudioMacRemoteURLSheet(
            remoteURLDraft: sourceRemoteURLDraftBinding,
            recentRemoteURL: model.recentRemoteURL,
            hasRecentRemoteURL: model.hasRecentRemoteURL,
            dismiss: {
                sourceSession.dismissRemoteURL()
            },
            load: model.loadRemoteURL(_:)
        )
    }

    private var quickOpenSheet: some View {
        StudioNativeQuickOpenSheet(
            items: quickOpenItems(),
            onSelect: { item in
                item.activate()
                isQuickOpenPresented = false
            }
        )
        .frame(minWidth: 640, minHeight: 520)
    }

    private var nativeContext: StudioMacWorkspaceContextSnapshot {
        StudioMacWorkspaceContextResolver.resolve(
            selection: routeSession.selection,
            selectionState: routeSession.selectionState,
            history: routeSession.history,
            document: model.nativeDocument,
            pageTitle: model.pageTitle,
            breadcrumb: model.breadcrumb
        )
    }

    private var nativeStatus: StudioMacWorkspaceStatusSnapshot {
        StudioMacWorkspaceContextResolver.statusSnapshot(model: model, selection: routeSession.selection)
    }

    private var nativeContextBar: some View {
        StudioMacWorkspaceContextChrome(
            context: nativeContext,
            status: nativeStatus,
            navigateBack: navigateBack
        )
    }

    private func reloadCurrentSelection() {
        if routeSession.selection == .legacyWeb {
            model.reload()
        } else {
            model.reloadCurrentSource()
        }
    }

    private var sidebarSelection: Binding<StudioNativeDestination?> {
        Binding(
            get: { routeSession.selection },
            set: { newValue in
                guard let newValue else { return }
                navigateToDestination(newValue)
            }
        )
    }

    private var canNavigateBack: Bool {
        StudioMacWorkspaceRouteActions.canNavigateBack(
            selection: routeSession.selection,
            webCanGoBack: model.canGoBack,
            history: routeSession.history
        )
    }

    private var canNavigateForward: Bool {
        StudioMacWorkspaceRouteActions.canNavigateForward(
            selection: routeSession.selection,
            webCanGoForward: model.canGoForward,
            history: routeSession.history
        )
    }

    private func inspectComponent(_ componentID: String) {
        routeSession.recordQuickOpenKey("component:\(componentID)")
        routeSession.applyRoute(.components(componentID), document: model.nativeDocument)
    }

    private func inspectView(_ viewID: String) {
        routeSession.recordQuickOpenKey("view:\(viewID)")
        routeSession.applyRoute(.views(viewID), document: model.nativeDocument)
    }

    private func inspectToken(_ tokenSelection: StudioNativeTokenSelection) {
        routeSession.recordQuickOpenKey(StudioMacWorkspaceQuickOpenState.key(for: tokenSelection))
        routeSession.applyRoute(.tokens(tokenSelection), document: model.nativeDocument)
    }

    private func inspectIcon(_ iconID: String) {
        routeSession.recordQuickOpenKey("icon:\(iconID)")
        routeSession.applyRoute(.icons(iconID), document: model.nativeDocument)
    }

    private func inspectTypography(_ typographyID: String) {
        routeSession.recordQuickOpenKey("typography:\(typographyID)")
        routeSession.applyRoute(.typography(typographyID), document: model.nativeDocument)
    }

    private func inspectMetric(_ metricSelection: StudioNativeMetricSelection) {
        routeSession.recordQuickOpenKey(StudioMacWorkspaceQuickOpenState.key(for: metricSelection))
        routeSession.applyRoute(.spacing(metricSelection), document: model.nativeDocument)
    }

    private func navigateToDestination(_ destination: StudioNativeDestination) {
        routeSession.navigateToDestination(destination, document: model.nativeDocument)
    }

    private func navigateBack() {
        routeSession.navigateBack(
            document: model.nativeDocument,
            navigateLegacyBack: model.navigateBack
        )
    }

    private func navigateForward() {
        routeSession.navigateForward(
            document: model.nativeDocument,
            navigateLegacyForward: model.navigateForward
        )
    }

    private func syncRouteFromState() {
        routeSession.syncRouteFromState(document: model.nativeDocument)
    }

    private func reviewQueueCounts(for document: StudioNativeDocument) -> (components: Int, views: Int, total: Int) {
        let components = document.components.filter { nativeComponentTruthStatus(for: $0).needsAttention }.count
        let views = document.views.filter { nativeViewTruthStatus(for: $0).needsAttention }.count
        return (components, views, components + views)
    }

    private func navigationEdgeCount(for document: StudioNativeDocument) -> Int {
        document.views.reduce(0) { $0 + $1.navigatesTo.count }
    }

    private func quickOpenItems() -> [StudioQuickOpenItem] {
        StudioMacQuickOpenFactory.makeItems(
            context: StudioMacQuickOpenContext(
                document: model.nativeDocument,
                recentKeys: routeSession.recentQuickOpenKeys,
                currentKey: currentQuickOpenKey,
                navigateToDestination: navigateToDestination,
                inspectToken: inspectToken,
                inspectIcon: inspectIcon,
                inspectTypography: inspectTypography,
                inspectMetric: inspectMetric,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        )
    }

    private var currentQuickOpenKey: String? {
        routeSession.currentQuickOpenKey
    }

    private var sourceCommandContext: StudioMacWorkspaceSourceCommandContext {
        StudioMacWorkspaceSourceCommandContext(
            hasRecentImport: model.hasRecentImport,
            recentImportName: model.recentImportName,
            hasRecentRemoteURL: model.hasRecentRemoteURL,
            recentRemoteURL: model.recentRemoteURL,
            openImport: { sourceSession.presentImport() },
            openRemoteURL: { sourceSession.presentRemoteURL(recentRemoteURL: model.recentRemoteURL) },
            reopenRecentImport: model.reopenRecentImport,
            reopenRecentRemoteURL: model.reopenRecentRemoteURL,
            loadHome: {
                navigateToDestination(.overview)
                model.loadBundledStudio()
            },
            reload: reloadCurrentSelection
        )
    }

    private var eventCommandContext: StudioMacWorkspaceEventCommandContext {
        StudioMacWorkspaceEventCommandContext(
            recentRemoteURL: model.recentRemoteURL,
            openQuickOpen: { isQuickOpenPresented = true },
            openImport: { sourceSession.presentImport() },
            reopenRecentImport: model.reopenRecentImport,
            openRemoteURL: { sourceSession.presentRemoteURL(recentRemoteURL: model.recentRemoteURL) },
            reopenRecentRemoteURL: model.reopenRecentRemoteURL,
            navigateBack: navigateBack,
            navigateForward: navigateForward,
            loadDemo: {
                navigateToDestination(.overview)
                model.loadDemo()
            },
            loadHome: {
                navigateToDestination(.overview)
                model.loadBundledStudio()
            },
            reloadCurrentSelection: reloadCurrentSelection,
            handleIncomingURL: model.handleIncomingURL
        )
    }

    private var observedRouteContext: StudioMacWorkspaceObservedRouteContext {
        StudioMacWorkspaceObservedRouteContext(
            selection: routeSession.selection,
            tokenSelection: routeSession.selectionState.tokenSelection,
            iconID: routeSession.selectionState.iconID,
            typographyID: routeSession.selectionState.typographyID,
            metricSelection: routeSession.selectionState.metricSelection,
            componentID: routeSession.selectionState.componentID,
            viewID: routeSession.selectionState.viewID,
            navigationViewID: routeSession.selectionState.navigationViewID,
            syncRouteFromState: syncRouteFromState
        )
    }

    private var sourceImportBinding: Binding<Bool> {
        Binding(
            get: { sourceSession.isImportingFile },
            set: { sourceSession.isImportingFile = $0 }
        )
    }

    private var sourceRemoteURLBinding: Binding<Bool> {
        Binding(
            get: { sourceSession.isImportingRemoteURL },
            set: { sourceSession.isImportingRemoteURL = $0 }
        )
    }

    private var sourceRemoteURLDraftBinding: Binding<String> {
        Binding(
            get: { sourceSession.remoteURLDraft },
            set: { sourceSession.remoteURLDraft = $0 }
        )
    }

    private var tokenSelectionBinding: Binding<StudioNativeTokenSelection?> {
        Binding(
            get: { routeSession.selectionState.tokenSelection },
            set: { routeSession.selectionState.tokenSelection = $0 }
        )
    }

    private var iconIDBinding: Binding<String?> {
        Binding(
            get: { routeSession.selectionState.iconID },
            set: { routeSession.selectionState.iconID = $0 }
        )
    }

    private var typographyIDBinding: Binding<String?> {
        Binding(
            get: { routeSession.selectionState.typographyID },
            set: { routeSession.selectionState.typographyID = $0 }
        )
    }

    private var metricSelectionBinding: Binding<StudioNativeMetricSelection?> {
        Binding(
            get: { routeSession.selectionState.metricSelection },
            set: { routeSession.selectionState.metricSelection = $0 }
        )
    }

    private var componentIDBinding: Binding<String?> {
        Binding(
            get: { routeSession.selectionState.componentID },
            set: { routeSession.selectionState.componentID = $0 }
        )
    }

    private var viewIDBinding: Binding<String?> {
        Binding(
            get: { routeSession.selectionState.viewID },
            set: { routeSession.selectionState.viewID = $0 }
        )
    }

    private var navigationViewIDBinding: Binding<String?> {
        Binding(
            get: { routeSession.selectionState.navigationViewID },
            set: { routeSession.selectionState.navigationViewID = $0 }
        )
    }
}
