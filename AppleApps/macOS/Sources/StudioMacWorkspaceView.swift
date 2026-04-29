import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct StudioMacWorkspaceView: View {
    @StateObject private var model = StudioShellModel()
    @State private var selection: StudioNativeDestination? = .overview
    @State private var isImportingFile = false
    @State private var isImportingRemoteURL = false
    @State private var isQuickOpenPresented = false
    @State private var isDropTargeted = false
    @State private var remoteURLDraft = ""
    @State private var componentAppearance: StudioNativeAppearance = .dark
    @State private var viewAppearance: StudioNativeAppearance = .dark
    @State private var selectedTokenSelection: StudioNativeTokenSelection?
    @State private var selectedIconID: String?
    @State private var selectedTypographyID: String?
    @State private var selectedMetricSelection: StudioNativeMetricSelection?
    @State private var selectedComponentID: String?
    @State private var selectedViewID: String?
    @State private var selectedNavigationViewID: String?
    @State private var recentQuickOpenKeys: [String] = []
    @State private var nativeHistory = StudioNativeHistoryState()
    @State private var isApplyingNativeRoute = false

    var body: some View {
        observedWorkspaceView
    }

    private var baseWorkspaceView: some View {
        workspaceSplitView
        .navigationTitle("HumbleStudio")
        .toolbar {
            shellToolbar
        }
    }

    private var importerWorkspaceView: some View {
        baseWorkspaceView
        .fileImporter(
            isPresented: $isImportingFile,
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
        .sheet(isPresented: $isImportingRemoteURL) {
            remoteURLSheet
        }
        .sheet(isPresented: $isQuickOpenPresented) {
            quickOpenSheet
        }
    }

    private var observedWorkspaceView: some View {
        modalWorkspaceView.studioMacWorkspaceEventBridge(
            isQuickOpenPresented: $isQuickOpenPresented,
            isImportingFile: $isImportingFile,
            isImportingRemoteURL: $isImportingRemoteURL,
            remoteURLDraft: $remoteURLDraft,
            recentRemoteURL: model.recentRemoteURL,
            selection: selection,
            tokenSelection: selectedTokenSelection,
            iconID: selectedIconID,
            typographyID: selectedTypographyID,
            metricSelection: selectedMetricSelection,
            componentID: selectedComponentID,
            viewID: selectedViewID,
            navigationViewID: selectedNavigationViewID,
            reopenRecentImport: model.reopenRecentImport,
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
            handleIncomingURL: model.handleIncomingURL,
            syncRouteFromState: syncRouteFromState
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
                    dropOverlay
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
        List(selection: sidebarSelection) {
            Section("Native") {
                sidebarRow(.overview)
                sidebarRow(.tokens, count: model.nativeDocument.map { $0.colors.count + $0.gradients.count })
                sidebarRow(.components, count: model.nativeDocument?.components.count)
                sidebarRow(.views, count: model.nativeDocument?.views.count)
                sidebarRow(.review, count: model.nativeDocument.map { reviewQueueCounts(for: $0).total })
                sidebarRow(.navigation, count: model.nativeDocument.map(navigationEdgeCount(for:)))
                sidebarRow(.icons, count: model.nativeDocument?.icons.count)
                sidebarRow(.typography, count: model.nativeDocument?.typography.count)
                sidebarRow(.spacing, count: model.nativeDocument.map { $0.spacing.count + $0.radius.count })
            }

            Section("Migration") {
                sidebarRow(.legacyWeb)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 230, ideal: 250)
    }

    private func sidebarRow(_ destination: StudioNativeDestination, count: Int? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: destination.symbolName)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.title)
                    .lineLimit(1)
                Text(destination.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let count {
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.55), in: Capsule())
                    .foregroundStyle(.secondary)
            }
        }
        .tag(destination)
    }

    @ToolbarContentBuilder
    private var shellToolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                navigateBack()
            } label: {
                Label("Back", systemImage: "chevron.backward")
            }
            .disabled(!canNavigateBack)

            Button {
                navigateForward()
            } label: {
                Label("Forward", systemImage: "chevron.forward")
            }
            .disabled(!canNavigateForward)

            Button {
                isQuickOpenPresented = true
            } label: {
                Label("Quick Open", systemImage: "magnifyingglass")
            }

            Button {
                isImportingFile = true
            } label: {
                Label("Open", systemImage: "folder")
            }

            Button {
                remoteURLDraft = model.recentRemoteURL ?? ""
                isImportingRemoteURL = true
            } label: {
                Label("URL", systemImage: "link")
            }

            if model.hasRecentImport {
                Button {
                    model.reopenRecentImport()
                } label: {
                    Label("Recent", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .help(model.recentImportName ?? "Reopen recent import")
            }

            if model.hasRecentRemoteURL {
                Button {
                    model.reopenRecentRemoteURL()
                } label: {
                    Label("Recent URL", systemImage: "clock.badge.checkmark")
                }
                .help(model.recentRemoteURL ?? "Reopen recent remote URL")
            }

            Button {
                navigateToDestination(.overview)
                model.loadBundledStudio()
            } label: {
                Label("Home", systemImage: "house")
            }

            Button {
                reloadCurrentSelection()
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }

            Button {
                navigateToDestination(.legacyWeb)
            } label: {
                Label("Legacy Web", systemImage: "globe")
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? .overview {
        case .overview:
            StudioMacOverviewPage(model: model)
        case .tokens:
            StudioMacTokensPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                selection: $selectedTokenSelection,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .components:
            StudioMacComponentsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $componentAppearance,
                selectedComponentID: $selectedComponentID,
                inspectView: inspectView
            )
        case .views:
            StudioMacViewsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $viewAppearance,
                selectedViewID: $selectedViewID,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .review:
            StudioMacReviewPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .navigation:
            StudioMacNavigationPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                selectedViewID: $selectedNavigationViewID,
                inspectView: inspectView
            )
        case .icons:
            StudioMacIconsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                selection: $selectedIconID
            )
        case .typography:
            StudioMacTypographyPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView,
                selection: $selectedTypographyID
            )
        case .spacing:
            StudioMacSpacingPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView,
                selection: $selectedMetricSelection
            )
        case .legacyWeb:
            legacyWebContent
        }
    }

    private var legacyWebContent: some View {
        ZStack {
            StudioWebView(model: model)

            if let errorMessage = model.errorMessage {
                ContentUnavailableView(
                    "Unable to load legacy inspector",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var remoteURLSheet: some View {
        NavigationStack {
            Form {
                Section("Remote source") {
                    TextField(
                        "https://raw.githubusercontent.com/user/repo/main/.humble/HumbleSudoku.humblebundle",
                        text: $remoteURLDraft,
                        axis: .vertical
                    )

                    Text("Use an http/https URL to a `.humblebundle`, `.zip`, or `design.json`. Native foundations and the legacy web inspector will both follow this source.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if model.hasRecentRemoteURL, let recentRemoteURL = model.recentRemoteURL {
                        Button {
                            remoteURLDraft = recentRemoteURL
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use recent URL")
                                Text(recentRemoteURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Open Remote URL")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isImportingRemoteURL = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Load") {
                        let url = remoteURLDraft
                        isImportingRemoteURL = false
                        model.loadRemoteURL(url)
                    }
                    .disabled(remoteURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 540, minHeight: 250)
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

    private var nativeContextBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(contextTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Text(contextSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Label(model.sourceSummary, systemImage: "shippingbox")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.45), in: Capsule())
                    .foregroundStyle(.secondary)

                statusChip
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .opacity(0.35)
        }
        .background(.thinMaterial)
    }

    private var contextTitle: String {
        if selection == .legacyWeb {
            return model.pageTitle
        }
        return (selection ?? .overview).title
    }

    private var contextSubtitle: String {
        if selection == .legacyWeb {
            return model.breadcrumb
        }
        return (selection ?? .overview).subtitle
    }

    private var statusChip: some View {
        HStack(spacing: 8) {
            if model.statusLevel == "loading" {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: statusSymbolName)
                    .font(.caption.weight(.semibold))
            }

            Text(model.statusText)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusBackground, in: Capsule())
        .foregroundStyle(statusForeground)
    }

    private var statusSymbolName: String {
        switch model.statusLevel {
        case "ok":
            return "checkmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "err":
            return "xmark.octagon.fill"
        default:
            return "circle.fill"
        }
    }

    private var statusForeground: Color {
        switch model.statusLevel {
        case "ok":
            return .green
        case "warn":
            return .orange
        case "err":
            return .red
        default:
            return .secondary
        }
    }

    private var statusBackground: Color {
        switch model.statusLevel {
        case "ok":
            return .green.opacity(0.14)
        case "warn":
            return .orange.opacity(0.14)
        case "err":
            return .red.opacity(0.14)
        default:
            return .secondary.opacity(0.12)
        }
    }

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Drop a Humble bundle to import")
                        .font(.headline)
                    Text(".humblebundle, .zip or .json")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(28)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.tint.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [10, 8]))
            )
            .padding(28)
    }

    private func reloadCurrentSelection() {
        if selection == .legacyWeb {
            model.reload()
        } else {
            model.reloadCurrentSource()
        }
    }

    private var nativeSelectionState: StudioNativeSelectionState {
        get {
            StudioNativeSelectionState(
                tokenSelection: selectedTokenSelection,
                iconID: selectedIconID,
                typographyID: selectedTypographyID,
                metricSelection: selectedMetricSelection,
                componentID: selectedComponentID,
                viewID: selectedViewID,
                navigationViewID: selectedNavigationViewID
            )
        }
        set {
            selectedTokenSelection = newValue.tokenSelection
            selectedIconID = newValue.iconID
            selectedTypographyID = newValue.typographyID
            selectedMetricSelection = newValue.metricSelection
            selectedComponentID = newValue.componentID
            selectedViewID = newValue.viewID
            selectedNavigationViewID = newValue.navigationViewID
        }
    }

    private var sidebarSelection: Binding<StudioNativeDestination?> {
        Binding(
            get: { selection },
            set: { newValue in
                guard let newValue else { return }
                navigateToDestination(newValue)
            }
        )
    }

    private var canNavigateBack: Bool {
        if selection == .legacyWeb {
            return model.canGoBack
        }
        return nativeHistory.canNavigateBack
    }

    private var canNavigateForward: Bool {
        if selection == .legacyWeb {
            return model.canGoForward
        }
        return nativeHistory.canNavigateForward
    }

    private func inspectComponent(_ componentID: String) {
        recordRecentQuickOpenKey("component:\(componentID)")
        applyNativeRoute(.components(componentID))
    }

    private func inspectView(_ viewID: String) {
        recordRecentQuickOpenKey("view:\(viewID)")
        applyNativeRoute(.views(viewID))
    }

    private func inspectToken(_ tokenSelection: StudioNativeTokenSelection) {
        recordRecentQuickOpenKey(quickOpenKey(for: tokenSelection))
        applyNativeRoute(.tokens(tokenSelection))
    }

    private func inspectIcon(_ iconID: String) {
        recordRecentQuickOpenKey("icon:\(iconID)")
        applyNativeRoute(.icons(iconID))
    }

    private func inspectTypography(_ typographyID: String) {
        recordRecentQuickOpenKey("typography:\(typographyID)")
        applyNativeRoute(.typography(typographyID))
    }

    private func inspectMetric(_ metricSelection: StudioNativeMetricSelection) {
        recordRecentQuickOpenKey(quickOpenKey(for: metricSelection))
        applyNativeRoute(.spacing(metricSelection))
    }

    private func navigateToDestination(_ destination: StudioNativeDestination) {
        recordRecentQuickOpenKey("page:\(destination.rawValue)")
        applyNativeRoute(
            StudioNativeRouteResolver.route(
                for: destination,
                state: nativeSelectionState,
                document: model.nativeDocument
            )
        )
    }

    private func navigateBack() {
        if selection == .legacyWeb {
            model.navigateBack()
            return
        }
        guard let route = StudioNativeRouteController.navigateBack(
            selection: selection,
            history: &nativeHistory
        ) else { return }
        applyNativeRoute(route, addToHistory: false)
    }

    private func navigateForward() {
        if selection == .legacyWeb {
            model.navigateForward()
            return
        }
        guard let route = StudioNativeRouteController.navigateForward(
            selection: selection,
            history: &nativeHistory
        ) else { return }
        applyNativeRoute(route, addToHistory: false)
    }

    private func syncRouteFromState() {
        StudioNativeRouteController.syncRoute(
            selection: selection,
            selectionState: nativeSelectionState,
            document: model.nativeDocument,
            history: &nativeHistory,
            isApplyingRoute: isApplyingNativeRoute
        )
    }

    private func applyNativeRoute(_ route: StudioNativeRoute, addToHistory: Bool = true) {
        var selectionState = nativeSelectionState
        StudioNativeRouteController.apply(
            route: route,
            selection: &selection,
            selectionState: &selectionState,
            document: model.nativeDocument,
            history: &nativeHistory,
            isApplyingRoute: &isApplyingNativeRoute,
            addToHistory: addToHistory
        )
        selectedTokenSelection = selectionState.tokenSelection
        selectedIconID = selectionState.iconID
        selectedTypographyID = selectionState.typographyID
        selectedMetricSelection = selectionState.metricSelection
        selectedComponentID = selectionState.componentID
        selectedViewID = selectionState.viewID
        selectedNavigationViewID = selectionState.navigationViewID
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
                recentKeys: recentQuickOpenKeys,
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
        switch selection {
        case .overview:
            return "page:overview"
        case .tokens:
            guard let selectedTokenSelection else { return "page:tokens" }
            return quickOpenKey(for: selectedTokenSelection)
        case .components:
            guard let selectedComponentID else { return "page:components" }
            return "component:\(selectedComponentID)"
        case .views:
            guard let selectedViewID else { return "page:views" }
            return "view:\(selectedViewID)"
        case .review:
            return "page:review"
        case .navigation:
            if let selectedNavigationViewID {
                return "view:\(selectedNavigationViewID)"
            }
            return "page:navigation"
        case .icons:
            guard let selectedIconID else { return "page:icons" }
            return "icon:\(selectedIconID)"
        case .typography:
            guard let selectedTypographyID else { return "page:typography" }
            return "typography:\(selectedTypographyID)"
        case .spacing:
            guard let selectedMetricSelection else { return "page:spacing" }
            return quickOpenKey(for: selectedMetricSelection)
        case .legacyWeb:
            return "page:legacyWeb"
        case nil:
            return nil
        }
    }

    private func recordRecentQuickOpenKey(_ key: String) {
        recentQuickOpenKeys.removeAll(where: { $0 == key })
        recentQuickOpenKeys.insert(key, at: 0)
        recentQuickOpenKeys = Array(recentQuickOpenKeys.prefix(12))
    }

    private func quickOpenKey(for tokenSelection: StudioNativeTokenSelection) -> String {
        switch tokenSelection {
        case let .color(id):
            return "color:\(id)"
        case let .gradient(id):
            return "gradient:\(id)"
        }
    }

    private func quickOpenKey(for metricSelection: StudioNativeMetricSelection) -> String {
        switch metricSelection {
        case let .spacing(id):
            return "spacing:\(id)"
        case let .radius(id):
            return "radius:\(id)"
        }
    }
}

private struct StudioMacOverviewPage: View {
    @ObservedObject var model: StudioShellModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let document = model.nativeDocument {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.appName)
                            .font(.system(size: 32, weight: .bold))
                        if !document.appDescription.isEmpty {
                            Text(document.appDescription)
                                .foregroundStyle(.secondary)
                        }
                        if !document.appVersion.isEmpty {
                            Text("v\(document.appVersion)")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary.opacity(0.55), in: Capsule())
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                        StudioCountCard(title: "Tokens", value: "\(document.colors.count + document.gradients.count)", caption: "Colors and gradients")
                        StudioCountCard(title: "Components", value: "\(document.components.count)", caption: "Native dashboard now reads snapshots from the bundle")
                        StudioCountCard(title: "Views", value: "\(document.views.count)", caption: "Native screen catalog with snapshot-first previews")
                        StudioCountCard(title: "Navigation", value: "\(document.views.reduce(0) { $0 + $1.navigatesTo.count })", caption: "Flow edges derived from the exported contract")
                        StudioCountCard(title: "Icons", value: "\(document.icons.count)", caption: "Resolved from the bundle")
                        StudioCountCard(title: "Typography", value: "\(document.typography.count)", caption: "Type roles")
                        StudioCountCard(title: "Spacing & Radius", value: "\(document.spacing.count + document.radius.count)", caption: "Spatial tokens")
                    }

                    StudioMigrationCard(
                        title: "Migration status",
                        message: "The macOS app now reads bundle truth natively for foundations, components, views, review, and navigation. The legacy web inspector remains as a fallback for any parity gaps while the SwiftUI rewrite catches up."
                    )
                } else if let nativeErrorMessage = model.nativeErrorMessage {
                    ContentUnavailableView(
                        "Native preview unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(nativeErrorMessage)
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    ContentUnavailableView(
                        "Load a design export",
                        systemImage: "shippingbox",
                        description: Text("Open a `.humblebundle`, `.zip`, or `design.json` to populate the native foundations workspace.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(24)
        }
    }
}
