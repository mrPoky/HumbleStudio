import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct StudioMacWorkspaceView: View {
    private enum Destination: String, Hashable, CaseIterable {
        case overview
        case tokens
        case icons
        case typography
        case spacing
        case legacyWeb

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .tokens: return "Tokens"
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
            case .icons:
                return "Native icon catalog sourced from the imported bundle."
            case .typography:
                return "Type styles decoded from the export contract."
            case .spacing:
                return "Padding and corner radius tokens rendered natively."
            case .legacyWeb:
                return "Components, views, review queue, and navigation map stay here until they are migrated."
            }
        }

        var symbolName: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .tokens: return "paintpalette"
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
                        StudioCountCard(title: "Icons", value: "\(document.icons.count)", caption: "Resolved from the bundle")
                        StudioCountCard(title: "Typography", value: "\(document.typography.count)", caption: "Type roles")
                        StudioCountCard(title: "Spacing & Radius", value: "\(document.spacing.count + document.radius.count)", caption: "Spatial tokens")
                    }

                    StudioMigrationCard(
                        title: "Migration status",
                        message: "The macOS app now reads bundle truth natively for foundations. Components, views, review, and navigation still live in the legacy web inspector until their SwiftUI versions catch up."
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

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    StudioGroupedSection(title: "Colors", groups: grouped(document.colors, by: \.group)) { item in
                        StudioColorCard(token: item)
                    }

                    StudioGroupedSection(title: "Gradients", groups: grouped(document.gradients, by: \.group)) { item in
                        StudioGradientCard(token: item)
                    }
                }
                .padding(24)
            }
        }
    }
}

private struct StudioMacIconsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 16) {
                    ForEach(document.icons) { icon in
                        VStack(alignment: .leading, spacing: 14) {
                            StudioMacIconThumbnail(url: document.resolvedIconURL(for: icon), symbol: icon.symbol)
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(icon.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(icon.symbol)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if !icon.description.isEmpty {
                                    Text(icon.description)
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
                                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
                .padding(24)
            }
        }
    }
}

private struct StudioMacTypographyPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(document.typography) { token in
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
                                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
                .padding(24)
            }
        }
    }
}

private struct StudioMacSpacingPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    StudioGroupedSection(title: "Spacing", groups: grouped(document.spacing, by: \.group)) { item in
                        StudioMetricCard(token: item)
                    }

                    StudioGroupedSection(title: "Corner Radius", groups: grouped(document.radius, by: \.group)) { item in
                        StudioMetricCard(token: item)
                    }
                }
                .padding(24)
            }
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

private struct StudioColorCard: View {
    let token: StudioNativeDocument.ColorToken

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
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct StudioGradientCard: View {
    let token: StudioNativeDocument.GradientToken

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
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
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

private struct StudioMetricCard: View {
    let token: StudioNativeDocument.MetricToken

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
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
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
