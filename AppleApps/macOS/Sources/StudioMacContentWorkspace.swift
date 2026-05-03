import SwiftUI
import AppKit

struct StudioMacComponentsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var appearance: StudioNativeAppearance
    @Binding var selectedComponentID: String?
    let inspectView: (String) -> Void

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StudioStrings.componentsPageTitle)
                                    .font(.system(size: 26, weight: .bold))
                                Text(StudioStrings.componentsPageSubtitle)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 16)

                            Picker(StudioStrings.appearance, selection: $appearance) {
                                Text(StudioStrings.dark).tag(StudioNativeAppearance.dark)
                                Text(StudioStrings.light).tag(StudioNativeAppearance.light)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        StudioGroupedSection(title: StudioStrings.componentCatalog, groups: grouped(document.components, by: \.group)) { item in
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
                    appearance: appearance,
                    inspectView: inspectView
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

struct StudioMacViewsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var appearance: StudioNativeAppearance
    @Binding var selectedViewID: String?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StudioStrings.viewsPageTitle)
                                    .font(.system(size: 26, weight: .bold))
                                Text(StudioStrings.viewsPageSubtitle)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 16)

                            Picker(StudioStrings.appearance, selection: $appearance) {
                                Text(StudioStrings.dark).tag(StudioNativeAppearance.dark)
                                Text(StudioStrings.light).tag(StudioNativeAppearance.light)
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
                    appearance: appearance,
                    inspectComponent: inspectComponent,
                    inspectView: inspectView
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
                    Text(token.snapshot == nil ? StudioStrings.catalog : StudioStrings.snapshot)
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
                        StudioPillLabel(text: StudioStrings.statesCount(token.statesCount))
                    }
                    if !token.defaultState.isEmpty {
                        StudioPillLabel(text: StudioStrings.defaultStateValue(token.defaultState))
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
    private enum Tab: CaseIterable, Identifiable {
        case preview
        case relationships
        case contract
        case source

        var id: Self { self }

        var title: String {
            switch self {
            case .preview: return StudioStrings.preview
            case .relationships: return StudioStrings.relationships
            case .contract: return StudioStrings.contract
            case .source: return StudioStrings.source
            }
        }
    }

    let token: StudioNativeDocument.ComponentItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let inspectView: (String) -> Void
    @State private var selectedTab: Tab = .preview
    @State private var previewConfiguration = StudioPreviewConfiguration()
    @State private var previewLayoutMode: StudioPreviewLayoutMode = .regular
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        Group {
            if let token {
                componentScrollView(token)
            } else {
                ContentUnavailableView(
                    StudioStrings.selectComponent,
                    systemImage: "square.grid.3x2",
                    description: Text(StudioStrings.selectComponentDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onChange(of: token?.id) { _, _ in
            selectedTab = .preview
            previewConfiguration = StudioPreviewConfiguration()
            if let token {
                previewConfiguration.coverageLevel = nativeComponentPreviewCoverage(for: token)
            }
            previewLayoutMode = .regular
            reloadProposals()
        }
        .onAppear(perform: reloadProposals)
    }

    @ViewBuilder
    private func componentScrollView(_ token: StudioNativeDocument.ComponentItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(StudioStrings.componentDetail)
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

                    HStack(spacing: 8) {
                        StudioPillLabel(text: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot)
                        if token.statesCount > 0 {
                            StudioPillLabel(text: StudioStrings.statesCount(token.statesCount))
                        }
                        let usedInViewsCount = relatedViews(for: token).count
                        if usedInViewsCount > 0 {
                            StudioPillLabel(text: StudioStrings.viewsCount(usedInViewsCount))
                        }
                    }
                }

                StudioInspectorSummaryGrid(items: [
                    StudioInspectorSummaryItem(
                        label: StudioStrings.truth,
                        value: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot,
                        tone: token.snapshot == nil ? .warning : .success
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.renderer,
                        value: token.renderer.capitalized,
                        tone: .neutral
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.defaultState,
                        value: token.defaultState.isEmpty ? "—" : token.defaultState,
                        tone: .accent
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.usedIn,
                        value: StudioStrings.viewsCount(relatedViews(for: token).count),
                        tone: .neutral
                    )
                ])

                Picker(StudioStrings.inspectorSection, selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .preview:
                    StudioInspectorSection(title: StudioStrings.previewSurface) {
                        VStack(alignment: .leading, spacing: 14) {
                            StudioPreviewControls(configuration: $previewConfiguration)
                            StudioPreviewLayoutPicker(layoutMode: $previewLayoutMode)

                            StudioPreviewHero(
                                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                                appearance: appearance,
                                configuration: previewConfiguration,
                                layoutMode: previewLayoutMode,
                                emptyTitle: StudioStrings.noSnapshot,
                                emptySymbolName: "photo"
                            )
                        }
                    }

                    StudioInspectorSection(title: StudioStrings.whatThisIs) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.truth, value: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot)
                            StudioKeyValueRow(label: StudioStrings.group, value: token.group)
                            StudioKeyValueRow(label: StudioStrings.renderer, value: token.renderer)
                            StudioKeyValueRow(label: StudioStrings.defaultState, value: token.defaultState.isEmpty ? "—" : token.defaultState)
                            StudioPreviewContractPanel(configuration: previewConfiguration)
                        }
                    }

                case .relationships:
                    if !relatedViews(for: token).isEmpty || !token.designTokenCategories.isEmpty {
                        StudioInspectorSection(title: StudioStrings.whereItAppears) {
                            VStack(alignment: .leading, spacing: 14) {
                                if !relatedViews(for: token).isEmpty {
                                    StudioInspectorLinkGroup(
                                        title: StudioStrings.usedInViews,
                                        linkItems: relatedViews(for: token).map {
                                            StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: StudioStrings.navigationKindLabel($0.presentation))
                                        },
                                        actionTitle: StudioStrings.inspectView,
                                        action: inspectView
                                    )
                                }
                                if !token.designTokenCategories.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.foundationCategories)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                    }
                                }
                            }
                        }
                    }

                case .contract:
                    StudioInspectorSection(title: StudioStrings.contract) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.renderer, value: token.renderer)
                            StudioKeyValueRow(label: StudioStrings.swiftUILabel, value: token.swiftUI)
                            StudioKeyValueRow(label: StudioStrings.defaultState, value: token.defaultState.isEmpty ? "—" : token.defaultState)
                            StudioKeyValueRow(label: StudioStrings.states, value: "\(token.statesCount)")
                            StudioKeyValueRow(label: StudioStrings.designTokens, value: "\(token.designTokenCount)")
                            StudioKeyValueRow(label: StudioStrings.sourceTokens, value: "\(token.sourceTokenCount)")
                        }
                    }

                    StudioMacProposalArtifactSection(
                        artifacts: proposalArtifacts,
                        preferredScope: "component:\(token.id)",
                        preferredEvidencePath: token.sourcePath,
                        loadIssue: proposalArtifactIssue,
                        reloadProposals: reloadProposals,
                        inspectComponent: nil,
                        inspectView: inspectView,
                        artifactLimit: 6,
                        selectedArtifactID: nil,
                        selectArtifact: nil
                    )

                    if !token.states.isEmpty {
                        StudioInspectorSection(title: StudioStrings.stateCatalog) {
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

                case .source:
                    StudioInspectorSection(title: StudioStrings.source) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.file, value: token.sourcePath)
                            if !token.sourceSnippetSymbol.isEmpty {
                                StudioKeyValueRow(
                                    label: StudioStrings.symbol,
                                    value: token.sourceSnippetRange.isEmpty
                                        ? token.sourceSnippetSymbol
                                        : "\(token.sourceSnippetSymbol) · \(token.sourceSnippetRange)"
                                )
                            }
                        }
                    }

                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.designTokens, value: "\(token.designTokenCount)")
                            StudioKeyValueRow(label: StudioStrings.sourceTokens, value: "\(token.sourceTokenCount)")
                            if !token.designTokenCategories.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(StudioStrings.categories)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func relatedViews(for token: StudioNativeDocument.ComponentItem) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { $0.components.contains(token.id) }
    }

    private func reloadProposals() {
        let result = StudioChangeProposalArtifact.loadResult(from: repositoryRootURL)
        proposalArtifacts = result.artifacts
        proposalArtifactIssue = result.issue
    }

    private var repositoryRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
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
                        Text(StudioStrings.navigationKindLabel(token.presentation))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if token.root {
                        Text(StudioStrings.root)
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
                    StudioPillLabel(text: StudioStrings.componentsCount(token.componentsCount))
                    StudioPillLabel(text: StudioStrings.linksCount(token.navigationCount))
                    if !token.defaultState.isEmpty {
                        StudioPillLabel(text: StudioStrings.stateValue(token.defaultState))
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
    private enum Tab: CaseIterable, Identifiable {
        case preview
        case flow
        case relationships
        case source

        var id: Self { self }

        var title: String {
            switch self {
            case .preview: return StudioStrings.preview
            case .flow: return StudioStrings.flow
            case .relationships: return StudioStrings.relationships
            case .source: return StudioStrings.source
            }
        }
    }

    let token: StudioNativeDocument.ViewItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var selectedTab: Tab = .preview
    @State private var previewConfiguration = StudioPreviewConfiguration()
    @State private var previewLayoutMode: StudioPreviewLayoutMode = .focus
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        Group {
            if let token {
                viewScrollView(token)
            } else {
                ContentUnavailableView(
                    StudioStrings.selectView,
                    systemImage: "rectangle.stack",
                    description: Text(StudioStrings.selectViewDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onChange(of: token?.id) { _, _ in
            selectedTab = .preview
            previewConfiguration = StudioPreviewConfiguration.viewDefault(presentation: token?.presentation ?? "")
            if let token {
                previewConfiguration.coverageLevel = nativeViewPreviewCoverage(for: token)
            }
            previewLayoutMode = .focus
            reloadProposals()
        }
        .onAppear(perform: reloadProposals)
    }

    @ViewBuilder
    private func viewScrollView(_ token: StudioNativeDocument.ViewItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(StudioStrings.viewDetail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(token.name)
                        .font(.system(size: 28, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Text(StudioStrings.navigationKindLabel(token.presentation))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.55), in: Capsule())
                            .foregroundStyle(.secondary)
                        if token.root {
                            Text(StudioStrings.root)
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

                    HStack(spacing: 8) {
                        StudioPillLabel(text: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot)
                        if token.componentsCount > 0 {
                            StudioPillLabel(text: StudioStrings.componentsCount(token.componentsCount))
                        }
                        if token.navigationCount > 0 {
                            StudioPillLabel(text: StudioStrings.linksCount(token.navigationCount))
                        }
                    }
                }

                StudioInspectorSummaryGrid(items: [
                    StudioInspectorSummaryItem(
                        label: StudioStrings.truth,
                        value: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot,
                        tone: token.snapshot == nil ? .warning : .success
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.presentation,
                        value: StudioStrings.navigationKindLabel(token.presentation),
                        tone: .neutral
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.linkedComponents,
                        value: "\(token.componentsCount)",
                        tone: .accent
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.nextSteps,
                        value: StudioStrings.linksCount(token.navigationCount),
                        tone: .neutral
                    )
                ])

                Picker(StudioStrings.inspectorSection, selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .preview:
                    StudioInspectorSection(title: StudioStrings.previewSurface) {
                        VStack(alignment: .leading, spacing: 14) {
                            StudioPreviewControls(configuration: $previewConfiguration)
                            StudioPreviewLayoutPicker(layoutMode: $previewLayoutMode)

                            StudioPreviewHero(
                                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                                appearance: appearance,
                                configuration: previewConfiguration,
                                layoutMode: previewLayoutMode,
                                emptyTitle: StudioStrings.noSnapshot,
                                emptySymbolName: "rectangle.on.rectangle"
                            )
                        }
                    }

                    StudioInspectorSection(title: StudioStrings.whatThisIs) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.truth, value: token.snapshot == nil ? StudioStrings.catalogOnly : StudioStrings.referenceSnapshot)
                            StudioKeyValueRow(label: StudioStrings.presentation, value: token.presentation)
                            StudioKeyValueRow(label: StudioStrings.defaultState, value: token.defaultState.isEmpty ? "—" : token.defaultState)
                            StudioKeyValueRow(label: StudioStrings.linkedComponents, value: "\(token.componentsCount)")
                            StudioPreviewContractPanel(configuration: previewConfiguration)
                        }
                    }

                case .flow:
                    if !token.entryPoints.isEmpty || !token.primaryActions.isEmpty || !token.secondaryActions.isEmpty || !token.navigatesTo.isEmpty {
                        StudioInspectorSection(title: StudioStrings.flow) {
                            VStack(alignment: .leading, spacing: 12) {
                                if !token.entryPoints.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.entryPoints)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.entryPoints.map(humanizedLabel))
                                    }
                                }

                                if !token.primaryActions.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.primaryActions)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.primaryActions)
                                    }
                                }

                                if !token.secondaryActions.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.secondaryActions)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: token.secondaryActions)
                                    }
                                }

                                if !token.navigatesTo.isEmpty {
                                    StudioInspectorLinkGroup(
                                        title: StudioStrings.whatUsersCanDoNext,
                                        linkItems: token.navigatesTo.prefix(5).map { navigation in
                                            StudioInspectorLinkItem(
                                                id: navigation.targetID,
                                                title: resolvedViewName(for: navigation.targetID),
                                                subtitle: StudioStrings.navigationEdgeLabel(type: navigation.type, trigger: navigation.trigger)
                                            )
                                        },
                                        actionTitle: StudioStrings.inspectView,
                                        action: inspectView
                                    )
                                }
                            }
                        }
                    }

                case .relationships:
                    StudioInspectorSection(title: StudioStrings.relationships) {
                        VStack(alignment: .leading, spacing: 12) {
                            if !token.components.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.linkedComponents,
                                    linkItems: token.components.map { componentID in
                                        StudioInspectorLinkItem(
                                            id: componentID,
                                            title: resolvedComponentName(for: componentID),
                                            subtitle: resolvedComponentSubtitle(for: componentID)
                                        )
                                    },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }

                            if !token.states.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(StudioStrings.states)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.states.map(humanizedLabel))
                                }
                            }

                            if !token.designTokenCategories.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(StudioStrings.foundationCategories)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                }
                            }
                        }
                    }

                case .source:
                    StudioInspectorSection(title: StudioStrings.source) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.file, value: token.sourcePath)
                            if !token.sourceSnippetSymbol.isEmpty {
                                StudioKeyValueRow(
                                    label: StudioStrings.symbol,
                                    value: token.sourceSnippetRange.isEmpty
                                        ? token.sourceSnippetSymbol
                                        : "\(token.sourceSnippetSymbol) · \(token.sourceSnippetRange)"
                                )
                            }
                        }
                    }

                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.designTokens, value: "\(token.designTokenCount)")
                            StudioKeyValueRow(label: StudioStrings.sourceTokens, value: "\(token.sourceTokenCount)")
                            StudioKeyValueRow(label: StudioStrings.sheets, value: "\(token.sheetPatternsCount)")
                            StudioKeyValueRow(label: StudioStrings.overlays, value: "\(token.overlayPatternsCount)")
                        }
                    }

                    StudioMacProposalArtifactSection(
                        artifacts: proposalArtifacts,
                        preferredScope: "view:\(token.id)",
                        preferredEvidencePath: token.sourcePath,
                        loadIssue: proposalArtifactIssue,
                        reloadProposals: reloadProposals,
                        inspectComponent: inspectComponent,
                        inspectView: inspectView,
                        artifactLimit: 6,
                        selectedArtifactID: nil,
                        selectArtifact: nil
                    )
                }
            }
            .padding(20)
        }
    }

    private func resolvedComponentName(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.name ?? humanizedLabel(componentID)
    }

    private func resolvedComponentSubtitle(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.group ?? StudioStrings.componentFallbackSubtitle
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

    private func reloadProposals() {
        let result = StudioChangeProposalArtifact.loadResult(from: repositoryRootURL)
        proposalArtifacts = result.artifacts
        proposalArtifactIssue = result.issue
    }

    private var repositoryRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
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
            Text(StudioStrings.noSnapshot)
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
            Text(StudioStrings.noSnapshot)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
    }
}
