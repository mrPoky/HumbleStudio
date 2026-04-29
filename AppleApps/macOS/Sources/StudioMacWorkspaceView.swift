import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct StudioMacWorkspaceView: View {
    private enum Destination: String, Hashable, CaseIterable {
        case overview
        case tokens
        case components
        case views
        case review
        case navigation
        case icons
        case typography
        case spacing
        case legacyWeb

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .tokens: return "Tokens"
            case .components: return "Components"
            case .views: return "Views"
            case .review: return "Review Queue"
            case .navigation: return "Navigation Map"
            case .icons: return "Icons"
            case .typography: return "Typography"
            case .spacing: return "Spacing & Radius"
            case .legacyWeb: return "Legacy Web Inspector"
            }
        }

        var subtitle: String {
            switch self {
            case .overview:
                return "Native foundations workspace for imported design exports."
            case .tokens:
                return "Colors and gradients rendered directly in SwiftUI."
            case .components:
                return "Snapshot-first component catalog rendered natively."
            case .views:
                return "Screen catalog with snapshot and flow truth, rendered natively."
            case .review:
                return "Native queue for components and views whose exported truth still needs attention."
            case .navigation:
                return "Native flow map over exported navigation edges and root routing."
            case .icons:
                return "Native icon catalog sourced from the imported bundle."
            case .typography:
                return "Type styles decoded from the export contract."
            case .spacing:
                return "Padding and corner radius tokens rendered natively."
            case .legacyWeb:
                return "Fallback web inspector for any parity gaps that are not native yet."
            }
        }

        var symbolName: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .tokens: return "paintpalette"
            case .components: return "square.grid.3x2"
            case .views: return "rectangle.on.rectangle"
            case .review: return "exclamationmark.circle"
            case .navigation: return "arrow.triangle.branch"
            case .icons: return "app.gift"
            case .typography: return "textformat"
            case .spacing: return "square.on.square"
            case .legacyWeb: return "globe"
            }
        }
    }

    private enum NativeRoute: Equatable {
        case overview
        case tokens(StudioNativeTokenSelection?)
        case components(String?)
        case views(String?)
        case review
        case navigation(String?)
        case icons(String?)
        case typography(String?)
        case spacing(StudioNativeMetricSelection?)
        case legacyWeb

        var destination: Destination {
            switch self {
            case .overview: return .overview
            case .tokens: return .tokens
            case .components: return .components
            case .views: return .views
            case .review: return .review
            case .navigation: return .navigation
            case .icons: return .icons
            case .typography: return .typography
            case .spacing: return .spacing
            case .legacyWeb: return .legacyWeb
            }
        }
    }

    @StateObject private var model = StudioShellModel()
    @State private var selection: Destination? = .overview
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
    @State private var nativeHistory: [NativeRoute] = [.overview]
    @State private var nativeHistoryIndex = 0
    @State private var isApplyingNativeRoute = false

    private static var supportedImportTypes: [UTType] {
        [UTType(filenameExtension: "humblebundle") ?? .zip, .zip, .json]
    }

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
            allowedContentTypes: Self.supportedImportTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
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
        var view = AnyView(modalWorkspaceView)
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioOpenQuickOpen)) { _ in
            isQuickOpenPresented = true
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioOpenImport)) { _ in
            isImportingFile = true
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentImport)) { _ in
            model.reopenRecentImport()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioOpenRemoteURL)) { _ in
            remoteURLDraft = model.recentRemoteURL ?? ""
            isImportingRemoteURL = true
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentRemoteURL)) { _ in
            model.reopenRecentRemoteURL()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioNavigateBack)) { _ in
            navigateBack()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioNavigateForward)) { _ in
            navigateForward()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioLoadDemo)) { _ in
            navigateToDestination(.overview)
            model.loadDemo()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioLoadHome)) { _ in
            navigateToDestination(.overview)
            model.loadBundledStudio()
        })
        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .studioReload)) { _ in
            reloadCurrentSelection()
        })
        view = AnyView(view.onOpenURL { url in
            model.handleIncomingURL(url)
        })
        view = AnyView(view.onChange(of: selection) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedTokenSelection) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedIconID) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedTypographyID) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedMetricSelection) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedComponentID) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedViewID) { _, _ in
            syncRouteFromState()
        })
        view = AnyView(view.onChange(of: selectedNavigationViewID) { _, _ in
            syncRouteFromState()
        })
        return view
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
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted, perform: handleFileDrop)
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            model.importFile(at: url)
        case .failure(let error):
            model.report(error: error)
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

    private func sidebarRow(_ destination: Destination, count: Int? = nil) -> some View {
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

    private var sidebarSelection: Binding<Destination?> {
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
        return nativeHistoryIndex > 0
    }

    private var canNavigateForward: Bool {
        if selection == .legacyWeb {
            return model.canGoForward
        }
        return nativeHistoryIndex < nativeHistory.count - 1
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error {
                Task { @MainActor in
                    model.report(error: error)
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
                model.importFile(at: resolvedURL)
            }
        }

        return true
    }

    private func inspectComponent(_ componentID: String) {
        applyNativeRoute(.components(componentID))
    }

    private func inspectView(_ viewID: String) {
        applyNativeRoute(.views(viewID))
    }

    private func inspectToken(_ tokenSelection: StudioNativeTokenSelection) {
        applyNativeRoute(.tokens(tokenSelection))
    }

    private func inspectIcon(_ iconID: String) {
        applyNativeRoute(.icons(iconID))
    }

    private func inspectTypography(_ typographyID: String) {
        applyNativeRoute(.typography(typographyID))
    }

    private func inspectMetric(_ metricSelection: StudioNativeMetricSelection) {
        applyNativeRoute(.spacing(metricSelection))
    }

    private func navigateToDestination(_ destination: Destination) {
        switch destination {
        case .overview:
            applyNativeRoute(.overview)
        case .tokens:
            applyNativeRoute(.tokens(resolvedTokenSelectionForRoute()))
        case .components:
            applyNativeRoute(.components(resolvedComponentIDForRoute()))
        case .views:
            applyNativeRoute(.views(resolvedViewIDForRoute()))
        case .review:
            applyNativeRoute(.review)
        case .navigation:
            applyNativeRoute(.navigation(resolvedNavigationViewIDForRoute()))
        case .icons:
            applyNativeRoute(.icons(resolvedIconIDForRoute()))
        case .typography:
            applyNativeRoute(.typography(resolvedTypographyIDForRoute()))
        case .spacing:
            applyNativeRoute(.spacing(resolvedMetricSelectionForRoute()))
        case .legacyWeb:
            applyNativeRoute(.legacyWeb)
        }
    }

    private func navigateBack() {
        if selection == .legacyWeb {
            model.navigateBack()
            return
        }
        guard nativeHistoryIndex > 0 else { return }
        nativeHistoryIndex -= 1
        applyNativeRoute(nativeHistory[nativeHistoryIndex], addToHistory: false)
    }

    private func navigateForward() {
        if selection == .legacyWeb {
            model.navigateForward()
            return
        }
        guard nativeHistoryIndex < nativeHistory.count - 1 else { return }
        nativeHistoryIndex += 1
        applyNativeRoute(nativeHistory[nativeHistoryIndex], addToHistory: false)
    }

    private func syncRouteFromState() {
        guard !isApplyingNativeRoute else { return }
        recordRoute(currentNativeRoute())
    }

    private func recordRoute(_ route: NativeRoute) {
        if nativeHistory.isEmpty {
            nativeHistory = [route]
            nativeHistoryIndex = 0
            return
        }

        if nativeHistory[nativeHistoryIndex] == route {
            return
        }

        if nativeHistoryIndex < nativeHistory.count - 1 {
            nativeHistory = Array(nativeHistory.prefix(nativeHistoryIndex + 1))
        }
        nativeHistory.append(route)
        nativeHistoryIndex = nativeHistory.count - 1
    }

    private func applyNativeRoute(_ route: NativeRoute, addToHistory: Bool = true) {
        isApplyingNativeRoute = true
        switch route {
        case .overview:
            selection = .overview
        case let .tokens(tokenSelection):
            selectedTokenSelection = tokenSelection ?? resolvedTokenSelectionForRoute()
            selection = .tokens
        case let .components(componentID):
            selectedComponentID = componentID ?? resolvedComponentIDForRoute()
            selection = .components
        case let .views(viewID):
            let resolvedViewID = viewID ?? resolvedViewIDForRoute()
            selectedViewID = resolvedViewID
            selectedNavigationViewID = resolvedViewID
            selection = .views
        case .review:
            selection = .review
        case let .navigation(viewID):
            selectedNavigationViewID = viewID ?? resolvedNavigationViewIDForRoute()
            selection = .navigation
        case let .icons(iconID):
            selectedIconID = iconID ?? resolvedIconIDForRoute()
            selection = .icons
        case let .typography(typographyID):
            selectedTypographyID = typographyID ?? resolvedTypographyIDForRoute()
            selection = .typography
        case let .spacing(metricSelection):
            selectedMetricSelection = metricSelection ?? resolvedMetricSelectionForRoute()
            selection = .spacing
        case .legacyWeb:
            selection = .legacyWeb
        }
        isApplyingNativeRoute = false
        if addToHistory {
            recordRoute(currentNativeRoute())
        }
    }

    private func currentNativeRoute() -> NativeRoute {
        switch selection ?? .overview {
        case .overview:
            return .overview
        case .tokens:
            return .tokens(resolvedTokenSelectionForRoute())
        case .components:
            return .components(resolvedComponentIDForRoute())
        case .views:
            return .views(resolvedViewIDForRoute())
        case .review:
            return .review
        case .navigation:
            return .navigation(resolvedNavigationViewIDForRoute())
        case .icons:
            return .icons(resolvedIconIDForRoute())
        case .typography:
            return .typography(resolvedTypographyIDForRoute())
        case .spacing:
            return .spacing(resolvedMetricSelectionForRoute())
        case .legacyWeb:
            return .legacyWeb
        }
    }

    private func resolvedTokenSelectionForRoute() -> StudioNativeTokenSelection? {
        if let selectedTokenSelection {
            return selectedTokenSelection
        }
        if let firstColor = model.nativeDocument?.colors.first {
            return .color(firstColor.id)
        }
        if let firstGradient = model.nativeDocument?.gradients.first {
            return .gradient(firstGradient.id)
        }
        return nil
    }

    private func resolvedComponentIDForRoute() -> String? {
        selectedComponentID ?? model.nativeDocument?.components.first?.id
    }

    private func resolvedViewIDForRoute() -> String? {
        selectedViewID ?? model.nativeDocument?.views.first?.id
    }

    private func resolvedNavigationViewIDForRoute() -> String? {
        selectedNavigationViewID
            ?? model.nativeDocument?.navigationRootID
            ?? model.nativeDocument?.views.first?.id
    }

    private func resolvedIconIDForRoute() -> String? {
        selectedIconID ?? model.nativeDocument?.icons.first?.id
    }

    private func resolvedTypographyIDForRoute() -> String? {
        selectedTypographyID ?? model.nativeDocument?.typography.first?.id
    }

    private func resolvedMetricSelectionForRoute() -> StudioNativeMetricSelection? {
        if let selectedMetricSelection {
            return selectedMetricSelection
        }
        if let firstSpacing = model.nativeDocument?.spacing.first {
            return .spacing(firstSpacing.id)
        }
        if let firstRadius = model.nativeDocument?.radius.first {
            return .radius(firstRadius.id)
        }
        return nil
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
        var items: [StudioQuickOpenItem] = [
            quickOpenPageItem(.overview, subtitle: "Native app overview and migration status"),
            quickOpenPageItem(.tokens, subtitle: "Colors and gradients"),
            quickOpenPageItem(.components, subtitle: "Snapshot-first component catalog"),
            quickOpenPageItem(.views, subtitle: "Screen catalog and flow truth"),
            quickOpenPageItem(.review, subtitle: "Truth gaps and review queue"),
            quickOpenPageItem(.navigation, subtitle: "Native navigation graph"),
            quickOpenPageItem(.icons, subtitle: "Bundled icon catalog"),
            quickOpenPageItem(.typography, subtitle: "Typography roles"),
            quickOpenPageItem(.spacing, subtitle: "Spacing and corner radius"),
            quickOpenPageItem(.legacyWeb, subtitle: "Fallback web inspector")
        ]

        if let document = model.nativeDocument {
            items.append(contentsOf: document.colors.map { token in
                StudioQuickOpenItem(
                    title: token.name,
                    subtitle: "Color token · \(token.group)",
                    symbolName: "paintpalette",
                    section: "Colors",
                    keywords: [token.id, token.group, token.lightHex, token.darkHex],
                    activate: { inspectToken(.color(token.id)) }
                )
            })
            items.append(contentsOf: document.gradients.map { token in
                StudioQuickOpenItem(
                    title: token.name,
                    subtitle: "Gradient token · \(token.group)",
                    symbolName: "sparkles",
                    section: "Gradients",
                    keywords: [token.id, token.group, token.swiftUI, token.usage],
                    activate: { inspectToken(.gradient(token.id)) }
                )
            })
            items.append(contentsOf: document.icons.map { token in
                StudioQuickOpenItem(
                    title: token.name,
                    subtitle: "Icon · \(token.symbol)",
                    symbolName: "app.gift",
                    section: "Icons",
                    keywords: [token.id, token.symbol, token.description],
                    activate: { inspectIcon(token.id) }
                )
            })
            items.append(contentsOf: document.typography.map { token in
                StudioQuickOpenItem(
                    title: token.role,
                    subtitle: "Typography · \(Int(token.size)) pt",
                    symbolName: "textformat",
                    section: "Typography",
                    keywords: [token.id, token.swiftUI, token.preview],
                    activate: { inspectTypography(token.id) }
                )
            })
            items.append(contentsOf: document.spacing.map { token in
                StudioQuickOpenItem(
                    title: token.name,
                    subtitle: "Spacing · \(token.value)",
                    symbolName: "rectangle.inset.filled",
                    section: "Spacing",
                    keywords: [token.id, token.group, token.usage],
                    activate: { inspectMetric(.spacing(token.id)) }
                )
            })
            items.append(contentsOf: document.radius.map { token in
                StudioQuickOpenItem(
                    title: token.name,
                    subtitle: "Corner radius · \(token.value)",
                    symbolName: "roundedcorner",
                    section: "Corner Radius",
                    keywords: [token.id, token.group, token.usage],
                    activate: { inspectMetric(.radius(token.id)) }
                )
            })
            items.append(contentsOf: document.components.map { component in
                StudioQuickOpenItem(
                    title: component.name,
                    subtitle: "Component · \(component.group)",
                    symbolName: "square.grid.3x2",
                    section: "Components",
                    keywords: [component.id, component.renderer, component.swiftUI, component.summary],
                    activate: { inspectComponent(component.id) }
                )
            })
            items.append(contentsOf: document.views.map { view in
                StudioQuickOpenItem(
                    title: view.name,
                    subtitle: "View · \(view.presentation.capitalized)",
                    symbolName: "rectangle.on.rectangle",
                    section: "Views",
                    keywords: [view.id, view.presentation, view.summary],
                    activate: { inspectView(view.id) }
                )
            })
        }

        return items
    }

    private func quickOpenPageItem(_ destination: Destination, subtitle: String) -> StudioQuickOpenItem {
        StudioQuickOpenItem(
            title: destination.title,
            subtitle: subtitle,
            symbolName: destination.symbolName,
            section: "Pages",
            keywords: [destination.rawValue, destination.subtitle],
            activate: { navigateToDestination(destination) }
        )
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
