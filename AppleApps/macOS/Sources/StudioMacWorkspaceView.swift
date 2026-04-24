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

    @StateObject private var model = StudioShellModel()
    @State private var selection: Destination? = .overview
    @State private var isImportingFile = false
    @State private var isImportingRemoteURL = false
    @State private var isDropTargeted = false
    @State private var remoteURLDraft = ""
    @State private var componentAppearance: StudioNativeAppearance = .dark
    @State private var viewAppearance: StudioNativeAppearance = .dark
    @State private var selectedComponentID: String?
    @State private var selectedViewID: String?
    @State private var selectedNavigationViewID: String?

    private static var supportedImportTypes: [UTType] {
        [UTType(filenameExtension: "humblebundle") ?? .zip, .zip, .json]
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
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
        .navigationTitle("HumbleStudio")
        .toolbar {
            shellToolbar
        }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: Self.supportedImportTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                model.importFile(at: url)
            case .failure(let error):
                model.report(error: error)
            }
        }
        .sheet(isPresented: $isImportingRemoteURL) {
            remoteURLSheet
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioOpenImport)) { _ in
            isImportingFile = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentImport)) { _ in
            model.reopenRecentImport()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioOpenRemoteURL)) { _ in
            remoteURLDraft = model.recentRemoteURL ?? ""
            isImportingRemoteURL = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioReopenRecentRemoteURL)) { _ in
            model.reopenRecentRemoteURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioNavigateBack)) { _ in
            if selection == .legacyWeb {
                model.navigateBack()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioNavigateForward)) { _ in
            if selection == .legacyWeb {
                model.navigateForward()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioLoadDemo)) { _ in
            selection = .overview
            model.loadDemo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioLoadHome)) { _ in
            selection = .overview
            model.loadBundledStudio()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioReload)) { _ in
            reloadCurrentSelection()
        }
        .onOpenURL { url in
            model.handleIncomingURL(url)
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
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
                model.navigateBack()
            } label: {
                Label("Back", systemImage: "chevron.backward")
            }
            .disabled(selection != .legacyWeb || !model.canGoBack)

            Button {
                model.navigateForward()
            } label: {
                Label("Forward", systemImage: "chevron.forward")
            }
            .disabled(selection != .legacyWeb || !model.canGoForward)

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
                selection = .overview
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
                selection = .legacyWeb
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
            StudioMacTokensPage(document: model.nativeDocument, nativeErrorMessage: model.nativeErrorMessage)
        case .components:
            StudioMacComponentsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $componentAppearance,
                selectedComponentID: $selectedComponentID
            )
        case .views:
            StudioMacViewsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $viewAppearance,
                selectedViewID: $selectedViewID
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
            StudioMacIconsPage(document: model.nativeDocument, nativeErrorMessage: model.nativeErrorMessage)
        case .typography:
            StudioMacTypographyPage(document: model.nativeDocument, nativeErrorMessage: model.nativeErrorMessage)
        case .spacing:
            StudioMacSpacingPage(document: model.nativeDocument, nativeErrorMessage: model.nativeErrorMessage)
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
        selectedComponentID = componentID
        selection = .components
    }

    private func inspectView(_ viewID: String) {
        selectedViewID = viewID
        selectedNavigationViewID = viewID
        selection = .views
    }

    private func reviewQueueCounts(for document: StudioNativeDocument) -> (components: Int, views: Int, total: Int) {
        let components = document.components.filter { nativeComponentTruthStatus(for: $0).needsAttention }.count
        let views = document.views.filter { nativeViewTruthStatus(for: $0).needsAttention }.count
        return (components, views, components + views)
    }

    private func navigationEdgeCount(for document: StudioNativeDocument) -> Int {
        document.views.reduce(0) { $0 + $1.navigatesTo.count }
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

private struct StudioMacTokensPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @State private var selection: StudioNativeTokenSelection?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tokens")
                                .font(.system(size: 26, weight: .bold))
                            Text("Native foundation inspector for colors and gradients, backed directly by the exported token contract.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        StudioGroupedSection(title: "Colors", groups: grouped(document.colors, by: \.group)) { item in
                            StudioColorCard(
                                token: item,
                                isSelected: selection == .color(item.id)
                            )
                            .onTapGesture {
                                selection = .color(item.id)
                            }
                        }

                        StudioGroupedSection(title: "Gradients", groups: grouped(document.gradients, by: \.group)) { item in
                            StudioGradientCard(
                                token: item,
                                isSelected: selection == .gradient(item.id)
                            )
                            .onTapGesture {
                                selection = .gradient(item.id)
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioTokenDetailInspector(
                    selection: selectedToken(in: document),
                    document: document
                )
                .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selection == nil {
                    selection = defaultSelection(in: document)
                }
            }
        }
    }

    private func defaultSelection(in document: StudioNativeDocument) -> StudioNativeTokenSelection? {
        if let firstColor = document.colors.first {
            return .color(firstColor.id)
        }
        if let firstGradient = document.gradients.first {
            return .gradient(firstGradient.id)
        }
        return nil
    }

    private func selectedToken(in document: StudioNativeDocument) -> StudioNativeTokenSelection.ResolvedSelection? {
        let currentSelection = selection ?? defaultSelection(in: document)
        switch currentSelection {
        case let .color(id):
            guard let token = document.colors.first(where: { $0.id == id }) else { return nil }
            return .color(token)
        case let .gradient(id):
            guard let token = document.gradients.first(where: { $0.id == id }) else { return nil }
            return .gradient(token)
        case .none:
            return nil
        }
    }
}

private struct StudioMacComponentsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var appearance: StudioNativeAppearance
    @Binding var selectedComponentID: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Components")
                                    .font(.system(size: 26, weight: .bold))
                                Text("First native component pass: snapshot-first cards over the exported contract, now with a real native inspector instead of a jump straight back to the web.")
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 16)

                            Picker("Appearance", selection: $appearance) {
                                Text("Dark").tag(StudioNativeAppearance.dark)
                                Text("Light").tag(StudioNativeAppearance.light)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        StudioGroupedSection(title: "Component Catalog", groups: grouped(document.components, by: \.group)) { item in
                            StudioComponentCard(
                                token: item,
                                document: document,
                                appearance: appearance,
                                isSelected: item.id == selectedComponent(in: document)?.id
                            )
                            .onTapGesture {
                                selectedComponentID = item.id
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioComponentDetailInspector(
                    token: selectedComponent(in: document),
                    document: document,
                    appearance: appearance
                )
                .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selectedComponentID == nil {
                    selectedComponentID = document.components.first?.id
                }
            }
        }
    }

    private func selectedComponent(in document: StudioNativeDocument) -> StudioNativeDocument.ComponentItem? {
        if let selectedComponentID, let selected = document.components.first(where: { $0.id == selectedComponentID }) {
            return selected
        }
        return document.components.first
    }
}

private struct StudioMacViewsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var appearance: StudioNativeAppearance
    @Binding var selectedViewID: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Views")
                                    .font(.system(size: 26, weight: .bold))
                                Text("Native screen catalog over the exported truth, now with a native detail inspector for flow, linked components, and source evidence.")
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 16)

                            Picker("Appearance", selection: $appearance) {
                                Text("Dark").tag(StudioNativeAppearance.dark)
                                Text("Light").tag(StudioNativeAppearance.light)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                            ForEach(document.views) { item in
                                StudioViewCard(
                                    token: item,
                                    document: document,
                                    appearance: appearance,
                                    isSelected: item.id == selectedView(in: document)?.id
                                )
                                .onTapGesture {
                                    selectedViewID = item.id
                                }
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioViewDetailInspector(
                    token: selectedView(in: document),
                    document: document,
                    appearance: appearance
                )
                .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selectedViewID == nil {
                    selectedViewID = document.views.first?.id
                }
            }
        }
    }

    private func selectedView(in document: StudioNativeDocument) -> StudioNativeDocument.ViewItem? {
        if let selectedViewID, let selected = document.views.first(where: { $0.id == selectedViewID }) {
            return selected
        }
        return document.views.first
    }
}

private struct StudioMacReviewPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            let components = document.components.filter { nativeComponentTruthStatus(for: $0).needsAttention }
            let views = document.views.filter { nativeViewTruthStatus(for: $0).needsAttention }

            if components.isEmpty && views.isEmpty {
                ContentUnavailableView(
                    "Nothing needs review",
                    systemImage: "checkmark.circle",
                    description: Text("All currently imported components and views have reference snapshots or enough exported truth for the native inspector.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Review Queue")
                                .font(.system(size: 28, weight: .bold))
                            Text("Start with items where exported truth is weakest, then jump straight into the matching native inspector.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 16) {
                            StudioCountCard(title: "Needs Review", value: "\(components.count + views.count)", caption: "Total native truth gaps surfaced from the current import")
                            StudioCountCard(title: "Components", value: "\(components.count)", caption: "Reusable pieces missing snapshot or strong state truth")
                            StudioCountCard(title: "Views", value: "\(views.count)", caption: "Screens whose visual or flow evidence still needs attention")
                        }

                        if !components.isEmpty {
                            StudioInspectorSection(title: "Components") {
                                VStack(alignment: .leading, spacing: 14) {
                                    ForEach(components) { component in
                                        StudioNativeReviewCard(
                                            title: component.name,
                                            subtitle: [component.group, "\(getComponentUsageCount(component, in: document)) views"].filter { !$0.isEmpty }.joined(separator: " · "),
                                            status: nativeComponentTruthStatus(for: component),
                                            reason: nativeComponentReviewReason(for: component),
                                            evidence: [
                                                ("Snapshot", component.snapshot == nil ? "Missing" : "Present"),
                                                ("States", "\(component.statesCount)"),
                                                ("Source", component.sourcePath.isEmpty ? "Missing" : "Present"),
                                            ],
                                            actionTitle: "Inspect Component"
                                        ) {
                                            inspectComponent(component.id)
                                        }
                                    }
                                }
                            }
                        }

                        if !views.isEmpty {
                            StudioInspectorSection(title: "Views") {
                                VStack(alignment: .leading, spacing: 14) {
                                    ForEach(views) { view in
                                        StudioNativeReviewCard(
                                            title: view.name,
                                            subtitle: [view.root ? "Root screen" : view.presentation.capitalized, "\(view.navigationCount) links"].joined(separator: " · "),
                                            status: nativeViewTruthStatus(for: view),
                                            reason: nativeViewReviewReason(for: view),
                                            evidence: [
                                                ("Snapshot", view.snapshot == nil ? "Missing" : "Present"),
                                                ("Components", "\(view.componentsCount)"),
                                                ("Source", view.sourcePath.isEmpty ? "Missing" : "Present"),
                                            ],
                                            actionTitle: "Inspect View"
                                        ) {
                                            inspectView(view.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
}

private struct StudioMacNavigationPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var selectedViewID: String?
    let inspectView: (String) -> Void

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            let graph = makeNativeNavigationGraph(document: document)

            HStack(spacing: 0) {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Navigation Map")
                                    .font(.system(size: 26, weight: .bold))
                                Text("Native flow map derived from exported navigation edges, rooted at the app entry route.")
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 24)

                            HStack(spacing: 16) {
                                StudioCountCard(title: "Views", value: "\(document.views.count)", caption: "Nodes currently in the exported flow graph")
                                StudioCountCard(title: "Edges", value: "\(graph.edgeCount)", caption: "Push, sheet, replace, and pop transitions")
                                StudioCountCard(title: "Root", value: graph.rootViewName, caption: "Primary entry route for the current bundle")
                            }
                            .frame(maxWidth: 680)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 22) {
                                ForEach(graph.levels, id: \.depth) { level in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Depth \(level.depth)")
                                            .font(.headline)
                                        Text("\(level.views.count) view\(level.views.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(level.views) { view in
                                                StudioNativeNavigationNodeCard(
                                                    view: view,
                                                    isSelected: view.id == selectedView(in: graph)?.id,
                                                    isRoot: view.id == graph.rootViewID,
                                                    incomingCount: graph.incoming[view.id]?.count ?? 0
                                                )
                                                .onTapGesture {
                                                    selectedViewID = view.id
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 260, alignment: .topLeading)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioNavigationDetailInspector(
                    graph: graph,
                    selectedView: selectedView(in: graph),
                    inspectView: inspectView
                )
                .frame(minWidth: 350, idealWidth: 390, maxWidth: 430, maxHeight: .infinity)
            }
            .onAppear {
                if selectedViewID == nil {
                    selectedViewID = graph.rootViewID
                }
            }
        }
    }

    private func selectedView(in graph: NativeNavigationGraph) -> StudioNativeDocument.ViewItem? {
        if let selectedViewID, let selected = graph.viewByID[selectedViewID] {
            return selected
        }
        return graph.viewByID[graph.rootViewID]
    }
}

private struct StudioMacIconsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @State private var selection: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Icons")
                                .font(.system(size: 26, weight: .bold))
                            Text("Native icon browser over the exported asset bundle, with a real inspector for symbol, asset path, and usage metadata.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 16) {
                            ForEach(document.icons) { icon in
                                StudioIconCard(
                                    token: icon,
                                    document: document,
                                    isSelected: icon.id == selectedIcon(in: document)?.id
                                )
                                .onTapGesture {
                                    selection = icon.id
                                }
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioIconDetailInspector(
                    token: selectedIcon(in: document),
                    document: document
                )
                .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selection == nil {
                    selection = document.icons.first?.id
                }
            }
        }
    }

    private func selectedIcon(in document: StudioNativeDocument) -> StudioNativeDocument.IconToken? {
        if let selection, let selected = document.icons.first(where: { $0.id == selection }) {
            return selected
        }
        return document.icons.first
    }
}

private struct StudioMacTypographyPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @State private var selection: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Typography")
                                .font(.system(size: 26, weight: .bold))
                            Text("Native type role inspector for preview copy, SwiftUI mapping, and scale metadata exported from the design contract.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(document.typography) { token in
                                StudioTypographyCard(
                                    token: token,
                                    isSelected: token.id == selectedTypography(in: document)?.id
                                )
                                .onTapGesture {
                                    selection = token.id
                                }
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioTypographyDetailInspector(token: selectedTypography(in: document))
                    .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selection == nil {
                    selection = document.typography.first?.id
                }
            }
        }
    }

    private func selectedTypography(in document: StudioNativeDocument) -> StudioNativeDocument.TypographyToken? {
        if let selection, let selected = document.typography.first(where: { $0.id == selection }) {
            return selected
        }
        return document.typography.first
    }
}

private struct StudioMacSpacingPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @State private var selection: StudioNativeMetricSelection?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spacing & Radius")
                                .font(.system(size: 26, weight: .bold))
                            Text("Native spatial token inspector for spacing and corner radius values, with larger previews and contract context instead of dashboard-only cards.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        StudioGroupedSection(title: "Spacing", groups: grouped(document.spacing, by: \.group)) { item in
                            StudioMetricCard(
                                token: item,
                                isSelected: selectedMetric(in: document)?.id == item.id && selectedMetric(in: document)?.kind == item.kind
                            )
                            .onTapGesture {
                                selection = .spacing(item.id)
                            }
                        }

                        StudioGroupedSection(title: "Corner Radius", groups: grouped(document.radius, by: \.group)) { item in
                            StudioMetricCard(
                                token: item,
                                isSelected: selectedMetric(in: document)?.id == item.id && selectedMetric(in: document)?.kind == item.kind
                            )
                            .onTapGesture {
                                selection = .radius(item.id)
                            }
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .opacity(0.35)

                StudioMetricDetailInspector(token: selectedMetric(in: document))
                    .frame(minWidth: 340, idealWidth: 380, maxWidth: 420, maxHeight: .infinity)
            }
            .onAppear {
                if selection == nil {
                    selection = defaultMetricSelection(in: document)
                }
            }
        }
    }

    private func defaultMetricSelection(in document: StudioNativeDocument) -> StudioNativeMetricSelection? {
        if let firstSpacing = document.spacing.first {
            return .spacing(firstSpacing.id)
        }
        if let firstRadius = document.radius.first {
            return .radius(firstRadius.id)
        }
        return nil
    }

    private func selectedMetric(in document: StudioNativeDocument) -> StudioNativeDocument.MetricToken? {
        let currentSelection = selection ?? defaultMetricSelection(in: document)
        switch currentSelection {
        case let .spacing(id):
            return document.spacing.first(where: { $0.id == id }) ?? document.spacing.first ?? document.radius.first
        case let .radius(id):
            return document.radius.first(where: { $0.id == id }) ?? document.radius.first ?? document.spacing.first
        case .none:
            return nil
        }
    }
}

private struct StudioNativePageContainer<Content: View>: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @ViewBuilder var content: (StudioNativeDocument) -> Content

    var body: some View {
        if let document {
            content(document)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if let nativeErrorMessage {
            ContentUnavailableView(
                "Native preview unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(nativeErrorMessage)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                "Load a design export",
                systemImage: "shippingbox",
                description: Text("Open a `.humblebundle`, `.zip`, or `design.json` to populate this native page.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct StudioGroupedSection<Item: Identifiable, Card: View>: View {
    let title: String
    let groups: [(String, [Item])]
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 26, weight: .bold))

            ForEach(groups, id: \.0) { groupName, items in
                VStack(alignment: .leading, spacing: 12) {
                    Text(groupName)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                        ForEach(items) { item in
                            card(item)
                        }
                    }
                }
            }
        }
    }
}

private struct StudioIconCard: View {
    let token: StudioNativeDocument.IconToken
    let document: StudioNativeDocument
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioMacIconThumbnail(url: document.resolvedIconURL(for: token), symbol: token.symbol)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(token.symbol)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !token.description.isEmpty {
                    Text(token.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioTypographyCard: View {
    let token: StudioNativeDocument.TypographyToken
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.role)
                        .font(.headline)
                    if !token.swiftUI.isEmpty {
                        Text(token.swiftUI)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(Int(token.size)) pt · \(token.weight)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.55), in: Capsule())
            }

            Text(token.preview)
                .font(.system(size: max(15, min(token.size, 40)), weight: token.fontWeight))
                .lineLimit(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioColorCard: View {
    let token: StudioNativeDocument.ColorToken
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: token.lightHex))
                Rectangle()
                    .fill(Color(hex: token.darkHex))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(token.lightHex) · \(token.darkHex)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if token.referenceCount > 0 {
                    Text("\(token.referenceCount) references")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioGradientCard: View {
    let token: StudioNativeDocument.GradientToken
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                gradientStrip(colors: token.lightColors)
                gradientStrip(colors: token.darkColors)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(token.kind.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if token.referenceCount > 0 {
                    Text("\(token.referenceCount) references")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }

    private func gradientStrip(colors: [String]) -> some View {
        LinearGradient(
            colors: colors.isEmpty ? [.secondary.opacity(0.2), .secondary.opacity(0.4)] : colors.map(Color.init(hex:)),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum StudioNativeTokenSelection: Equatable {
    case color(String)
    case gradient(String)

    enum ResolvedSelection {
        case color(StudioNativeDocument.ColorToken)
        case gradient(StudioNativeDocument.GradientToken)
    }
}

private enum StudioNativeMetricSelection: Equatable {
    case spacing(String)
    case radius(String)
}

private struct StudioTokenDetailInspector: View {
    let selection: StudioNativeTokenSelection.ResolvedSelection?
    let document: StudioNativeDocument

    var body: some View {
        Group {
            switch selection {
            case let .color(token):
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Color Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(token.group)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary.opacity(0.55), in: Capsule())
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            StudioTonePreviewCard(title: "Light", fill: Color(hex: token.lightHex), value: token.lightHex)
                            StudioTonePreviewCard(title: "Dark", fill: Color(hex: token.darkHex), value: token.darkHex)
                        }

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Token", value: token.id)
                                StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
                                StudioKeyValueRow(label: "Variants", value: token.lightHex == token.darkHex ? "Shared light/dark value" : "Distinct light and dark values")
                            }
                        }

                        if !token.derivedGradientIDs.isEmpty {
                            StudioInspectorSection(title: "Relationships") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Derived gradients")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.derivedGradientIDs.map(resolvedGradientName(for:)))
                                }
                            }
                        }

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(token.sourcePaths.prefix(6)), id: \.self) { path in
                                        StudioKeyValueRow(label: "Source", value: path)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }

            case let .gradient(token):
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Gradient Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(token.group)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary.opacity(0.55), in: Capsule())
                                .foregroundStyle(.secondary)
                            if !token.usage.isEmpty {
                                Text(token.usage)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        VStack(spacing: 12) {
                            StudioGradientTonePreviewCard(title: "Light", colors: token.lightColors)
                            StudioGradientTonePreviewCard(title: "Dark", colors: token.darkColors)
                        }

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Token", value: token.id)
                                StudioKeyValueRow(label: "Type", value: token.kind.capitalized)
                                StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
                                if !token.swiftUI.isEmpty {
                                    StudioKeyValueRow(label: "SwiftUI", value: token.swiftUI)
                                }
                            }
                        }

                        if !token.tokenColors.isEmpty || !token.designComponentIDs.isEmpty {
                            StudioInspectorSection(title: "Relationships") {
                                VStack(alignment: .leading, spacing: 10) {
                                    if !token.tokenColors.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Token colors")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.tokenColors.map(resolvedColorName(for:)))
                                        }
                                    }
                                    if !token.designComponentIDs.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Linked components")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.designComponentIDs.map(resolvedComponentName(for:)))
                                        }
                                    }
                                }
                            }
                        }

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(token.sourcePaths.prefix(6)), id: \.self) { path in
                                        StudioKeyValueRow(label: "Source", value: path)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }

            case .none:
                ContentUnavailableView(
                    "Select a token",
                    systemImage: "paintpalette",
                    description: Text("Choose a color or gradient card to inspect its variants, references, and relationships.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }

    private func resolvedGradientName(for gradientID: String) -> String {
        document.gradients.first(where: { $0.id == gradientID })?.name ?? humanizedFoundationLabel(gradientID)
    }

    private func resolvedColorName(for colorID: String) -> String {
        document.colors.first(where: { $0.id == colorID })?.name ?? humanizedFoundationLabel(colorID)
    }

    private func resolvedComponentName(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.name ?? humanizedFoundationLabel(componentID)
    }

    private func humanizedFoundationLabel(_ value: String) -> String {
        value
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private struct StudioIconDetailInspector: View {
    let token: StudioNativeDocument.IconToken?
    let document: StudioNativeDocument

    var body: some View {
        Group {
            if let token {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Icon Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(token.symbol)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            if !token.description.isEmpty {
                                Text(token.description)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        StudioMacIconThumbnail(url: document.resolvedIconURL(for: token), symbol: token.symbol)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Symbol", value: token.symbol)
                                StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
                                StudioKeyValueRow(label: "Truth", value: "Bundled asset")
                            }
                        }

                        StudioInspectorSection(title: "Asset") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Path", value: token.assetPath.isEmpty ? "—" : token.assetPath)
                                StudioKeyValueRow(label: "Identifier", value: token.id)
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select an icon",
                    systemImage: "app.dashed",
                    description: Text("Choose an icon card to inspect its symbol, bundled asset path, and exported usage metadata.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }
}

private struct StudioTypographyDetailInspector: View {
    let token: StudioNativeDocument.TypographyToken?

    var body: some View {
        Group {
            if let token {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Typography Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.role)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            if !token.swiftUI.isEmpty {
                                Text(token.swiftUI)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text(token.preview)
                                .font(.system(size: max(24, min(token.size, 52)), weight: token.fontWeight))
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .opacity(0.35)

                            Text("The quick brown fox jumps over the lazy dog.")
                                .font(.system(size: max(15, min(token.size * 0.72, 28)), weight: token.fontWeight))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.quaternary.opacity(0.75), lineWidth: 1)
                        )

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Size", value: "\(Int(token.size)) pt")
                                StudioKeyValueRow(label: "Weight", value: "\(token.weight)")
                                StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
                                if !token.swiftUI.isEmpty {
                                    StudioKeyValueRow(label: "SwiftUI", value: token.swiftUI)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a typography role",
                    systemImage: "textformat",
                    description: Text("Choose a type card to inspect its preview copy, scale, and SwiftUI mapping.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }
}

private struct StudioMetricDetailInspector: View {
    let token: StudioNativeDocument.MetricToken?

    var body: some View {
        Group {
            if let token {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(token.kind == "cornerRadius" ? "Corner Radius Detail" : "Spacing Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(token.kindLabel)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary.opacity(0.55), in: Capsule())
                                Text(token.value)
                                    .font(.caption.monospaced())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary.opacity(0.55), in: Capsule())
                            }
                        }

                        StudioMetricPreviewSurface(token: token)

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Group", value: token.group)
                                StudioKeyValueRow(label: "Value", value: token.value)
                                StudioKeyValueRow(label: "Type", value: token.kindLabel)
                                StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
                            }
                        }

                        if !token.usage.isEmpty {
                            StudioInspectorSection(title: "Usage") {
                                Text(token.usage)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a spatial token",
                    systemImage: "rectangle.inset.filled",
                    description: Text("Choose a spacing or radius token to inspect its value, preview scale, and usage guidance.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }
}

private struct StudioTonePreviewCard: View {
    let title: String
    let fill: Color
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StudioGradientTonePreviewCard: View {
    let title: String
    let colors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LinearGradient(
                colors: colors.isEmpty ? [.secondary.opacity(0.2), .secondary.opacity(0.4)] : colors.map(Color.init(hex:)),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(colors.joined(separator: " → "))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

private struct StudioComponentCard: View {
    let token: StudioNativeDocument.ComponentItem
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioComponentSnapshotThumbnail(
                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                appearance: appearance
            )
            .frame(maxWidth: .infinity)
            .frame(height: 190)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(token.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text(token.renderer.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Text(token.snapshot == nil ? "Catalog" : "Snapshot")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((token.snapshot == nil ? Color.orange : Color.green).opacity(0.14), in: Capsule())
                        .foregroundStyle(token.snapshot == nil ? .orange : .green)
                }

                if !token.summary.isEmpty {
                    Text(token.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                HStack(spacing: 8) {
                    if token.statesCount > 0 {
                        StudioPillLabel(text: "\(token.statesCount) states")
                    }
                    if !token.defaultState.isEmpty {
                        StudioPillLabel(text: "Default: \(token.defaultState)")
                    }
                }

                if !token.swiftUI.isEmpty {
                    Text(token.swiftUI)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioComponentDetailInspector: View {
    let token: StudioNativeDocument.ComponentItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance

    var body: some View {
        Group {
            if let token {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Component Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(token.group)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary.opacity(0.55), in: Capsule())
                                .foregroundStyle(.secondary)
                            if !token.summary.isEmpty {
                                Text(token.summary)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        StudioComponentSnapshotThumbnail(
                            url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                            appearance: appearance
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Renderer", value: token.renderer)
                                StudioKeyValueRow(label: "SwiftUI", value: token.swiftUI)
                                StudioKeyValueRow(label: "Default state", value: token.defaultState.isEmpty ? "—" : token.defaultState)
                                StudioKeyValueRow(label: "States", value: "\(token.statesCount)")
                                StudioKeyValueRow(label: "Truth", value: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                            }
                        }

                        if !token.states.isEmpty {
                            StudioInspectorSection(title: "States") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(token.states.prefix(6)) { state in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(state.label)
                                                .font(.subheadline.weight(.semibold))
                                            if !state.detail.isEmpty {
                                                Text(state.detail)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        if state.id != token.states.prefix(6).last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        StudioInspectorSection(title: "Evidence") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Design tokens", value: "\(token.designTokenCount)")
                                StudioKeyValueRow(label: "Source tokens", value: "\(token.sourceTokenCount)")
                                if !token.designTokenCategories.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Categories")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                    }
                                }
                            }
                        }

                        StudioInspectorSection(title: "Source") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "File", value: token.sourcePath)
                                if !token.sourceSnippetSymbol.isEmpty {
                                    StudioKeyValueRow(
                                        label: "Symbol",
                                        value: token.sourceSnippetRange.isEmpty
                                            ? token.sourceSnippetSymbol
                                            : "\(token.sourceSnippetSymbol) · \(token.sourceSnippetRange)"
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a component",
                    systemImage: "square.grid.3x2",
                    description: Text("Choose a component card to inspect its snapshot truth, state catalog, and source metadata.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }
}

private struct StudioViewCard: View {
    let token: StudioNativeDocument.ViewItem
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioViewSnapshotThumbnail(
                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                appearance: appearance
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(token.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text(token.presentation.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if token.root {
                        Text("Root")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.14), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }

                if !token.summary.isEmpty {
                    Text(token.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                HStack(spacing: 8) {
                    StudioPillLabel(text: "\(token.componentsCount) components")
                    StudioPillLabel(text: "\(token.navigationCount) links")
                    if !token.defaultState.isEmpty {
                        StudioPillLabel(text: "State: \(token.defaultState)")
                    }
                }

                if !token.entryPoints.isEmpty {
                    Text(token.entryPoints.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioViewDetailInspector: View {
    let token: StudioNativeDocument.ViewItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance

    var body: some View {
        Group {
            if let token {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("View Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(token.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(token.presentation.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary.opacity(0.55), in: Capsule())
                                    .foregroundStyle(.secondary)
                                if token.root {
                                    Text("Root")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.14), in: Capsule())
                                        .foregroundStyle(.blue)
                                }
                            }
                            if !token.summary.isEmpty {
                                Text(token.summary)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        StudioViewSnapshotThumbnail(
                            url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                            appearance: appearance
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)

                        StudioInspectorSection(title: "Contract") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Presentation", value: token.presentation)
                                StudioKeyValueRow(label: "Default state", value: token.defaultState.isEmpty ? "—" : token.defaultState)
                                StudioKeyValueRow(label: "States", value: "\(token.statesCount)")
                                StudioKeyValueRow(label: "Linked components", value: "\(token.componentsCount)")
                                StudioKeyValueRow(label: "Truth", value: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                            }
                        }

                        if !token.entryPoints.isEmpty || !token.primaryActions.isEmpty || !token.secondaryActions.isEmpty || !token.navigatesTo.isEmpty {
                            StudioInspectorSection(title: "Flow") {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !token.entryPoints.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Entry points")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.entryPoints.map(humanizedLabel))
                                        }
                                    }

                                    if !token.primaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Primary actions")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.primaryActions)
                                        }
                                    }

                                    if !token.secondaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Secondary actions")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.secondaryActions)
                                        }
                                    }

                                    if !token.navigatesTo.isEmpty {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Navigation")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            ForEach(token.navigatesTo.prefix(5)) { navigation in
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(resolvedViewName(for: navigation.targetID))
                                                        .font(.subheadline.weight(.semibold))
                                                    Text(navigation.trigger.isEmpty ? navigation.type.capitalized : "\(navigation.type.capitalized) via \(navigation.trigger)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                if navigation.id != token.navigatesTo.prefix(5).last?.id {
                                                    Divider()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        StudioInspectorSection(title: "Evidence") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Design tokens", value: "\(token.designTokenCount)")
                                StudioKeyValueRow(label: "Source tokens", value: "\(token.sourceTokenCount)")
                                StudioKeyValueRow(label: "Sheets", value: "\(token.sheetPatternsCount)")
                                StudioKeyValueRow(label: "Overlays", value: "\(token.overlayPatternsCount)")

                                if !token.states.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("States")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.states.map(humanizedLabel))
                                    }
                                }

                                if !token.components.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Components")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.components.map(resolvedComponentName(for:)))
                                    }
                                }

                                if !token.designTokenCategories.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Categories")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                    }
                                }
                            }
                        }

                        StudioInspectorSection(title: "Source") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "File", value: token.sourcePath)
                                if !token.sourceSnippetSymbol.isEmpty {
                                    StudioKeyValueRow(
                                        label: "Symbol",
                                        value: token.sourceSnippetRange.isEmpty
                                            ? token.sourceSnippetSymbol
                                            : "\(token.sourceSnippetSymbol) · \(token.sourceSnippetRange)"
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a view",
                    systemImage: "rectangle.stack",
                    description: Text("Choose a view card to inspect its flow, linked components, and source evidence.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }

    private func resolvedComponentName(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.name ?? humanizedLabel(componentID)
    }

    private func resolvedViewName(for viewID: String) -> String {
        document.views.first(where: { $0.id == viewID })?.name ?? humanizedLabel(viewID)
    }

    private func humanizedLabel(_ value: String) -> String {
        value
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private struct StudioNavigationDetailInspector: View {
    let graph: NativeNavigationGraph
    let selectedView: StudioNativeDocument.ViewItem?
    let inspectView: (String) -> Void

    var body: some View {
        Group {
            if let selectedView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Flow Detail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedView.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(selectedView.presentation.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary.opacity(0.55), in: Capsule())
                                    .foregroundStyle(.secondary)
                                if selectedView.id == graph.rootViewID {
                                    Text("Root")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.14), in: Capsule())
                                        .foregroundStyle(.blue)
                                }
                            }
                            if !selectedView.summary.isEmpty {
                                Text(selectedView.summary)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        StudioInspectorSection(title: "Route") {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: "Depth", value: "\(graph.depths[selectedView.id] ?? 0)")
                                StudioKeyValueRow(label: "Incoming", value: "\(graph.incoming[selectedView.id]?.count ?? 0)")
                                StudioKeyValueRow(label: "Outgoing", value: "\(selectedView.navigatesTo.count)")
                                if !graph.pathToRoot(selectedView.id).isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Path from root")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: graph.pathToRoot(selectedView.id).map { graph.viewByID[$0]?.name ?? $0 })
                                    }
                                }
                            }
                        }

                        if let incoming = graph.incoming[selectedView.id], !incoming.isEmpty {
                            StudioInspectorSection(title: "How Users Get Here") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(incoming) { edge in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(graph.viewByID[edge.sourceID]?.name ?? edge.sourceID)
                                                .font(.subheadline.weight(.semibold))
                                            Text(edge.trigger.isEmpty ? edge.type.capitalized : "\(edge.type.capitalized) via \(edge.trigger)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if edge.id != incoming.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        if !selectedView.navigatesTo.isEmpty {
                            StudioInspectorSection(title: "What Users Can Do Next") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(selectedView.navigatesTo) { edge in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(graph.viewByID[edge.targetID]?.name ?? edge.targetID)
                                                .font(.subheadline.weight(.semibold))
                                            Text(edge.trigger.isEmpty ? edge.type.capitalized : "\(edge.type.capitalized) via \(edge.trigger)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if edge.id != selectedView.navigatesTo.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        if !selectedView.entryPoints.isEmpty || !selectedView.primaryActions.isEmpty || !selectedView.secondaryActions.isEmpty {
                            StudioInspectorSection(title: "Interaction Model") {
                                VStack(alignment: .leading, spacing: 10) {
                                    if !selectedView.entryPoints.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Entry points")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.entryPoints.map(humanizedFlowLabel))
                                        }
                                    }
                                    if !selectedView.primaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Primary actions")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.primaryActions)
                                        }
                                    }
                                    if !selectedView.secondaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Secondary actions")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.secondaryActions)
                                        }
                                    }
                                }
                            }
                        }

                        Button("Open View Detail") {
                            inspectView(selectedView.id)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a route node",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Choose a view in the navigation map to inspect how users reach it and where they can go next.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
    }

    private func humanizedFlowLabel(_ value: String) -> String {
        value
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private struct StudioMetricCard: View {
    let token: StudioNativeDocument.MetricToken
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(token.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(token.value)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.55), in: Capsule())
            }

            if token.kind == "cornerRadius" {
                RoundedRectangle(cornerRadius: token.scalarValue, style: .continuous)
                    .fill(.quaternary.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: token.scalarValue, style: .continuous)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 92)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.quaternary.opacity(0.25))
                        .frame(height: 26)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: max(24, min(token.scalarValue * 8, 220)), height: 26)
                        }

                    if !token.usage.isEmpty {
                        Text(token.usage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioMetricPreviewSurface: View {
    let token: StudioNativeDocument.MetricToken

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if token.kind == "cornerRadius" {
                RoundedRectangle(cornerRadius: token.scalarValue, style: .continuous)
                    .fill(.quaternary.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: token.scalarValue, style: .continuous)
                            .stroke(.secondary.opacity(0.28), lineWidth: 1)
                    )
                    .frame(height: 170)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: max(16, min(token.scalarValue * 4, 80))) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentColor.opacity(0.85))
                            .frame(width: 90, height: 90)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary.opacity(0.8))
                            .frame(width: 90, height: 90)
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.quaternary.opacity(0.25))
                        .frame(height: 26)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.72))
                                .frame(width: max(32, min(token.scalarValue * 10, 260)), height: 26)
                        }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct StudioPillLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.55), in: Capsule())
            .foregroundStyle(.secondary)
    }
}

private struct StudioInspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary.opacity(0.75), lineWidth: 1)
        )
    }
}

private struct StudioNativeReviewCard: View {
    let title: String
    let subtitle: String
    let status: StudioNativeTruthStatus
    let reason: String
    let evidence: [(String, String)]
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                Text(status.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(status.color.opacity(0.14), in: Capsule())
                    .foregroundStyle(status.color)
            }

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                ForEach(evidence, id: \.0) { item in
                    StudioKeyValueRow(label: item.0, value: item.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(status.color.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct StudioNativeNavigationNodeCard: View {
    let view: StudioNativeDocument.ViewItem
    let isSelected: Bool
    let isRoot: Bool
    let incomingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(view.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(view.presentation.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if isRoot {
                    Text("Root")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.14), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }

            if !view.summary.isEmpty {
                Text(view.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                StudioPillLabel(text: "\(incomingCount) in")
                StudioPillLabel(text: "\(view.navigatesTo.count) out")
                if view.componentsCount > 0 {
                    StudioPillLabel(text: "\(view.componentsCount) comps")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct StudioKeyValueRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StudioNativeTruthStatus {
    let label: String
    let color: Color
    let needsAttention: Bool
}

private struct NativeNavigationIncomingEdge: Identifiable {
    let id: String
    let sourceID: String
    let targetID: String
    let trigger: String
    let type: String
}

private struct NativeNavigationLevel: Identifiable {
    let depth: Int
    let views: [StudioNativeDocument.ViewItem]

    var id: Int { depth }
}

private struct NativeNavigationGraph {
    let rootViewID: String
    let rootViewName: String
    let levels: [NativeNavigationLevel]
    let depths: [String: Int]
    let incoming: [String: [NativeNavigationIncomingEdge]]
    let viewByID: [String: StudioNativeDocument.ViewItem]
    let edgeCount: Int

    func pathToRoot(_ viewID: String) -> [String] {
        guard let currentDepth = depths[viewID] else { return [] }
        if viewID == rootViewID { return [rootViewID] }
        var currentID = viewID
        var path = [currentID]
        var remainingDepth = currentDepth
        while remainingDepth > 0 {
            guard
                let parent = incoming[currentID]?.first(where: { depths[$0.sourceID] == remainingDepth - 1 })
            else { break }
            currentID = parent.sourceID
            path.insert(currentID, at: 0)
            remainingDepth -= 1
        }
        if path.first != rootViewID {
            path.insert(rootViewID, at: 0)
        }
        return Array(NSOrderedSet(array: path)) as? [String] ?? path
    }
}

private func makeNativeNavigationGraph(document: StudioNativeDocument) -> NativeNavigationGraph {
    let viewByID = Dictionary(uniqueKeysWithValues: document.views.map { ($0.id, $0) })
    let rootViewID = document.navigationRootID
        ?? document.views.first(where: \.root)?.id
        ?? document.views.first?.id
        ?? ""

    var depths: [String: Int] = rootViewID.isEmpty ? [:] : [rootViewID: 0]
    var queue = rootViewID.isEmpty ? [String]() : [rootViewID]

    while let currentID = queue.first {
        queue.removeFirst()
        let currentDepth = depths[currentID] ?? 0
        let edges = viewByID[currentID]?.navigatesTo ?? []
        for edge in edges where edge.type != "pop" {
            guard viewByID[edge.targetID] != nil, depths[edge.targetID] == nil else { continue }
            depths[edge.targetID] = currentDepth + 1
            queue.append(edge.targetID)
        }
    }

    let fallbackDepth = (depths.values.max() ?? -1) + 1
    var unattachedIndex = 0
    for view in document.views where depths[view.id] == nil {
        depths[view.id] = fallbackDepth + unattachedIndex
        unattachedIndex += 1
    }

    var incoming: [String: [NativeNavigationIncomingEdge]] = [:]
    for view in document.views {
        for edge in view.navigatesTo {
            guard viewByID[edge.targetID] != nil else { continue }
            let item = NativeNavigationIncomingEdge(
                id: "\(view.id)->\(edge.targetID)-\(edge.type)-\(edge.trigger)",
                sourceID: view.id,
                targetID: edge.targetID,
                trigger: edge.trigger,
                type: edge.type
            )
            incoming[edge.targetID, default: []].append(item)
        }
    }

    let grouped = Dictionary(grouping: document.views) { depths[$0.id] ?? 0 }
    let levels = grouped.keys.sorted().map { depth in
        NativeNavigationLevel(
            depth: depth,
            views: (grouped[depth] ?? []).sorted { lhs, rhs in
                if lhs.id == rootViewID { return true }
                if rhs.id == rootViewID { return false }
                if lhs.root != rhs.root { return lhs.root && !rhs.root }
                if lhs.navigationCount != rhs.navigationCount { return lhs.navigationCount > rhs.navigationCount }
                return lhs.name < rhs.name
            }
        )
    }

    let edgeCount = document.views.reduce(0) { $0 + $1.navigatesTo.count }
    let rootViewName = viewByID[rootViewID]?.name ?? "Unknown"

    return NativeNavigationGraph(
        rootViewID: rootViewID,
        rootViewName: rootViewName,
        levels: levels,
        depths: depths,
        incoming: incoming,
        viewByID: viewByID,
        edgeCount: edgeCount
    )
}

private func nativeComponentTruthStatus(for component: StudioNativeDocument.ComponentItem) -> StudioNativeTruthStatus {
    if component.snapshot != nil {
        return StudioNativeTruthStatus(label: "Reference snapshot", color: .green, needsAttention: false)
    }
    if component.statesCount > 0 {
        return StudioNativeTruthStatus(label: "Catalog only", color: .orange, needsAttention: true)
    }
    return StudioNativeTruthStatus(label: "Approximation only", color: .red, needsAttention: true)
}

private func nativeViewTruthStatus(for view: StudioNativeDocument.ViewItem) -> StudioNativeTruthStatus {
    if view.snapshot != nil {
        return StudioNativeTruthStatus(label: "Reference snapshot", color: .green, needsAttention: false)
    }
    return StudioNativeTruthStatus(label: "Catalog only", color: .orange, needsAttention: true)
}

private func nativeComponentReviewReason(for component: StudioNativeDocument.ComponentItem) -> String {
    if component.snapshot == nil && component.statesCount == 0 {
        return "No reference snapshot is exported and the native inspector also has no declared state catalog to lean on yet."
    }
    if component.snapshot == nil {
        return "The component has declared states, but there is still no exported reference snapshot to confirm visual truth."
    }
    return "This component is fully backed by exported truth."
}

private func nativeViewReviewReason(for view: StudioNativeDocument.ViewItem) -> String {
    if view.snapshot == nil {
        return "The screen has flow and component metadata, but no exported reference snapshot yet, so visual truth still needs review."
    }
    return "This view is fully backed by exported truth."
}

private func getComponentUsageCount(_ component: StudioNativeDocument.ComponentItem, in document: StudioNativeDocument) -> Int {
    document.views.filter { $0.components.contains(component.id) }.count
}

private struct FlexiblePillStack: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.55), in: Capsule())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StudioCountCard: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
            Text(title)
                .font(.headline)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct StudioMigrationCard: View {
    let title: String
    let message: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "arrow.triangle.branch")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }

    var body: some View { bodyView }
}

private struct StudioMacIconThumbnail: View {
    let url: URL?
    let symbol: String

    var body: some View {
        Group {
            if let url, url.isFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                    default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: symbol.isEmpty ? "questionmark.square.dashed" : symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(28)
    }
}

private struct StudioComponentSnapshotThumbnail: View {
    let url: URL?
    let appearance: StudioNativeAppearance

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(appearance == .light ? Color.white : Color(hex: "#11182B"))

            if let url, url.isFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary.opacity(0.7), lineWidth: 1)
        )
    }

    private var fallback: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .semibold))
            Text("No snapshot")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
    }
}

private struct StudioViewSnapshotThumbnail: View {
    let url: URL?
    let appearance: StudioNativeAppearance

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(appearance == .light ? Color.white : Color(hex: "#11182B"))

            if let url, url.isFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary.opacity(0.7), lineWidth: 1)
        )
    }

    private var fallback: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 28, weight: .semibold))
            Text("No snapshot")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
    }
}

private func grouped<Item>(_ items: [Item], by keyPath: KeyPath<Item, String>) -> [(String, [Item])] {
    let groupedItems = Dictionary(grouping: items) { $0[keyPath: keyPath] }
    return groupedItems.keys.sorted().map { key in
        (key, groupedItems[key] ?? [])
    }
}

private extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)

        let red, green, blue, alpha: Double
        switch trimmed.count {
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

private extension StudioNativeDocument.MetricToken {
    var kindLabel: String {
        kind == "cornerRadius" ? "Corner Radius" : "Spacing"
    }

    var scalarValue: CGFloat {
        let digits = value
            .filter { $0.isNumber || $0 == "." }
        guard let parsed = Double(digits), parsed.isFinite else {
            return 12
        }
        return CGFloat(parsed)
    }
}

private extension StudioNativeDocument.TypographyToken {
    var fontWeight: Font.Weight {
        switch weight {
        case ..<350: return .regular
        case ..<500: return .medium
        case ..<650: return .semibold
        case ..<800: return .bold
        default: return .black
        }
    }
}
