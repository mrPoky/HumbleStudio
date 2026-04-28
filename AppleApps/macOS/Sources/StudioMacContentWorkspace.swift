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
    private enum Tab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case relationships = "Relationships"
        case contract = "Contract"
        case source = "Source"

        var id: String { rawValue }
    }

    let token: StudioNativeDocument.ComponentItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let inspectView: (String) -> Void
    @State private var selectedTab: Tab = .preview

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

                            HStack(spacing: 8) {
                                StudioPillLabel(text: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                                if token.statesCount > 0 {
                                    StudioPillLabel(text: "\(token.statesCount) states")
                                }
                                let usedInViewsCount = relatedViews(for: token).count
                                if usedInViewsCount > 0 {
                                    StudioPillLabel(text: "\(usedInViewsCount) views")
                                }
                            }
                        }

                        Picker("Inspector section", selection: $selectedTab) {
                            ForEach(Tab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch selectedTab {
                        case .preview:
                            StudioComponentSnapshotThumbnail(
                                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                                appearance: appearance
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)

                            StudioInspectorSection(title: "What This Is") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Truth", value: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                                    StudioKeyValueRow(label: "Group", value: token.group)
                                    StudioKeyValueRow(label: "Renderer", value: token.renderer)
                                    StudioKeyValueRow(label: "Default state", value: token.defaultState.isEmpty ? "—" : token.defaultState)
                                }
                            }

                        case .relationships:
                            if !relatedViews(for: token).isEmpty || !token.designTokenCategories.isEmpty {
                                StudioInspectorSection(title: "Where It Appears") {
                                    VStack(alignment: .leading, spacing: 14) {
                                        if !relatedViews(for: token).isEmpty {
                                            StudioInspectorLinkGroup(
                                                title: "Used In Views",
                                                linkItems: relatedViews(for: token).map {
                                                    StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.presentation.capitalized)
                                                },
                                                actionTitle: "Inspect View",
                                                action: inspectView
                                            )
                                        }
                                        if !token.designTokenCategories.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Foundation categories")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                            }
                                        }
                                    }
                                }
                            }

                        case .contract:
                            StudioInspectorSection(title: "Contract") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Renderer", value: token.renderer)
                                    StudioKeyValueRow(label: "SwiftUI", value: token.swiftUI)
                                    StudioKeyValueRow(label: "Default state", value: token.defaultState.isEmpty ? "—" : token.defaultState)
                                    StudioKeyValueRow(label: "States", value: "\(token.statesCount)")
                                    StudioKeyValueRow(label: "Design tokens", value: "\(token.designTokenCount)")
                                    StudioKeyValueRow(label: "Source tokens", value: "\(token.sourceTokenCount)")
                                }
                            }

                            if !token.states.isEmpty {
                                StudioInspectorSection(title: "State Catalog") {
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
        .onChange(of: token?.id) { _, _ in
            selectedTab = .preview
        }
    }

    private func relatedViews(for token: StudioNativeDocument.ComponentItem) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { $0.components.contains(token.id) }
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
    private enum Tab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case flow = "Flow"
        case relationships = "Relationships"
        case source = "Source"

        var id: String { rawValue }
    }

    let token: StudioNativeDocument.ViewItem?
    let document: StudioNativeDocument
    let appearance: StudioNativeAppearance
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var selectedTab: Tab = .preview

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

                            HStack(spacing: 8) {
                                StudioPillLabel(text: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                                if token.componentsCount > 0 {
                                    StudioPillLabel(text: "\(token.componentsCount) components")
                                }
                                if token.navigationCount > 0 {
                                    StudioPillLabel(text: "\(token.navigationCount) links")
                                }
                            }
                        }

                        Picker("Inspector section", selection: $selectedTab) {
                            ForEach(Tab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch selectedTab {
                        case .preview:
                            StudioViewSnapshotThumbnail(
                                url: document.resolvedSnapshotURL(for: token.snapshot, appearance: appearance),
                                appearance: appearance
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)

                            StudioInspectorSection(title: "What This Is") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Truth", value: token.snapshot == nil ? "Catalog only" : "Reference snapshot")
                                    StudioKeyValueRow(label: "Presentation", value: token.presentation)
                                    StudioKeyValueRow(label: "Default state", value: token.defaultState.isEmpty ? "—" : token.defaultState)
                                    StudioKeyValueRow(label: "Linked components", value: "\(token.componentsCount)")
                                }
                            }

                        case .flow:
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
                                            StudioInspectorLinkGroup(
                                                title: "What Users Can Do Next",
                                                linkItems: token.navigatesTo.prefix(5).map { navigation in
                                                    StudioInspectorLinkItem(
                                                        id: navigation.targetID,
                                                        title: resolvedViewName(for: navigation.targetID),
                                                        subtitle: navigation.trigger.isEmpty ? navigation.type.capitalized : "\(navigation.type.capitalized) via \(navigation.trigger)"
                                                    )
                                                },
                                                actionTitle: "Inspect View",
                                                action: inspectView
                                            )
                                        }
                                    }
                                }
                            }

                        case .relationships:
                            StudioInspectorSection(title: "Relationships") {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !token.components.isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Linked Components",
                                            linkItems: token.components.map { componentID in
                                                StudioInspectorLinkItem(
                                                    id: componentID,
                                                    title: resolvedComponentName(for: componentID),
                                                    subtitle: resolvedComponentSubtitle(for: componentID)
                                                )
                                            },
                                            actionTitle: "Inspect Component",
                                            action: inspectComponent
                                        )
                                    }

                                    if !token.states.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("States")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.states.map(humanizedLabel))
                                        }
                                    }

                                    if !token.designTokenCategories.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Foundation categories")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.designTokenCategories.map { $0.capitalized })
                                        }
                                    }
                                }
                            }

                        case .source:
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

                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Design tokens", value: "\(token.designTokenCount)")
                                    StudioKeyValueRow(label: "Source tokens", value: "\(token.sourceTokenCount)")
                                    StudioKeyValueRow(label: "Sheets", value: "\(token.sheetPatternsCount)")
                                    StudioKeyValueRow(label: "Overlays", value: "\(token.overlayPatternsCount)")
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
        .onChange(of: token?.id) { _, _ in
            selectedTab = .preview
        }
    }

    private func resolvedComponentName(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.name ?? humanizedLabel(componentID)
    }

    private func resolvedComponentSubtitle(for componentID: String) -> String {
        document.components.first(where: { $0.id == componentID })?.group ?? "Component"
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
