import SwiftUI
import AppKit

enum StudioNativeTokenSelection: Equatable {
    case color(String)
    case gradient(String)

    enum ResolvedSelection {
        case color(StudioNativeDocument.ColorToken)
        case gradient(StudioNativeDocument.GradientToken)
    }
}

enum StudioNativeMetricSelection: Equatable {
    case spacing(String)
    case radius(String)
}

struct StudioMacTokensPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var selection: StudioNativeTokenSelection?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

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
                    document: document,
                    inspectComponent: inspectComponent,
                    inspectView: inspectView
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

struct StudioMacIconsPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let inspectComponent: (String) -> Void
    @Binding var selection: String?

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
                    document: document,
                    inspectComponent: inspectComponent
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

struct StudioMacTypographyPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @Binding var selection: String?

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

                StudioTypographyDetailInspector(
                    token: selectedTypography(in: document),
                    document: document,
                    inspectComponent: inspectComponent,
                    inspectView: inspectView
                )
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

struct StudioMacSpacingPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @Binding var selection: StudioNativeMetricSelection?

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

                StudioMetricDetailInspector(
                    token: selectedMetric(in: document),
                    document: document,
                    inspectComponent: inspectComponent,
                    inspectView: inspectView
                )
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

struct StudioGroupedSection<Item: Identifiable, Card: View>: View {
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: token.lightHex))
                    .frame(height: 110)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: token.darkHex))
                    .frame(height: 110)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(token.group)
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
}

private struct StudioGradientCard: View {
    let token: StudioNativeDocument.GradientToken
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
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

private struct StudioTokenDetailInspector: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case relationships = "Relationships"
        case source = "Source"

        var id: String { rawValue }
    }

    let selection: StudioNativeTokenSelection.ResolvedSelection?
    let document: StudioNativeDocument
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var selectedTab: Tab = .preview

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

                            HStack(spacing: 8) {
                                StudioPillLabel(text: "\(token.referenceCount) references")
                                if token.lightHex == token.darkHex {
                                    StudioPillLabel(text: "Shared light/dark")
                                } else {
                                    StudioPillLabel(text: "Distinct variants")
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
                            HStack(spacing: 12) {
                                StudioTonePreviewCard(title: "Light", fill: Color(hex: token.lightHex), value: token.lightHex)
                                StudioTonePreviewCard(title: "Dark", fill: Color(hex: token.darkHex), value: token.darkHex)
                            }

                            StudioInspectorSection(title: "What This Is") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Token", value: token.id)
                                    StudioKeyValueRow(label: "Group", value: token.group)
                                    StudioKeyValueRow(label: "Variants", value: token.lightHex == token.darkHex ? "Shared light/dark value" : "Distinct light and dark values")
                                }
                            }

                        case .relationships:
                            StudioInspectorSection(title: "Relationships") {
                                VStack(alignment: .leading, spacing: 14) {
                                    if !token.derivedGradientIDs.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Derived gradients")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.derivedGradientIDs.map(resolvedGradientName(for:)))
                                        }
                                    }

                                    if !relatedComponents(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Used By Components",
                                            linkItems: relatedComponents(for: token).map { component in
                                                StudioInspectorLinkItem(id: component.id, title: component.name, subtitle: component.group)
                                            },
                                            actionTitle: "Inspect Component",
                                            action: inspectComponent
                                        )
                                    }

                                    if !relatedViews(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Used By Views",
                                            linkItems: relatedViews(for: token).map { view in
                                                StudioInspectorLinkItem(id: view.id, title: view.name, subtitle: view.presentation.capitalized)
                                            },
                                            actionTitle: "Inspect View",
                                            action: inspectView
                                        )
                                    }
                                }
                            }

                        case .source:
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
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

                            HStack(spacing: 8) {
                                StudioPillLabel(text: "\(token.referenceCount) references")
                                StudioPillLabel(text: token.kind.capitalized)
                                if !token.designComponentIDs.isEmpty {
                                    StudioPillLabel(text: "\(token.designComponentIDs.count) components")
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
                            VStack(spacing: 12) {
                                StudioGradientTonePreviewCard(title: "Light", colors: token.lightColors)
                                StudioGradientTonePreviewCard(title: "Dark", colors: token.darkColors)
                            }

                            StudioInspectorSection(title: "What This Is") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "Token", value: token.id)
                                    StudioKeyValueRow(label: "Type", value: token.kind.capitalized)
                                    if !token.swiftUI.isEmpty {
                                        StudioKeyValueRow(label: "SwiftUI", value: token.swiftUI)
                                    }
                                }
                            }

                        case .relationships:
                            StudioInspectorSection(title: "Relationships") {
                                VStack(alignment: .leading, spacing: 14) {
                                    if !token.tokenColors.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Token colors")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: token.tokenColors.map(resolvedColorName(for:)))
                                        }
                                    }

                                    if !relatedComponents(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Used By Components",
                                            linkItems: relatedComponents(for: token).map { component in
                                                StudioInspectorLinkItem(id: component.id, title: component.name, subtitle: component.group)
                                            },
                                            actionTitle: "Inspect Component",
                                            action: inspectComponent
                                        )
                                    }

                                    if !relatedViews(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Used By Views",
                                            linkItems: relatedViews(for: token).map { view in
                                                StudioInspectorLinkItem(id: view.id, title: view.name, subtitle: view.presentation.capitalized)
                                            },
                                            actionTitle: "Inspect View",
                                            action: inspectView
                                        )
                                    }
                                }
                            }

                        case .source:
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: "References", value: "\(token.referenceCount)")
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
        .onChange(of: selectionID) { _, _ in
            selectedTab = .preview
        }
    }

    private func resolvedGradientName(for gradientID: String) -> String {
        document.gradients.first(where: { $0.id == gradientID })?.name ?? humanizedFoundationLabel(gradientID)
    }

    private func resolvedColorName(for colorID: String) -> String {
        document.colors.first(where: { $0.id == colorID })?.name ?? humanizedFoundationLabel(colorID)
    }

    private func relatedComponents(for token: StudioNativeDocument.ColorToken) -> [StudioNativeDocument.ComponentItem] {
        let derivedGradientIDs = Set(token.derivedGradientIDs)
        return document.components.filter { component in
            component.designDependencies.colors.contains(token.id)
                || component.sourceDependencies.colors.contains(token.id)
                || !derivedGradientIDs.isDisjoint(with: component.designDependencies.gradients)
                || !derivedGradientIDs.isDisjoint(with: component.sourceDependencies.gradients)
        }
    }

    private func relatedViews(for token: StudioNativeDocument.ColorToken) -> [StudioNativeDocument.ViewItem] {
        let derivedGradientIDs = Set(token.derivedGradientIDs)
        return document.views.filter { view in
            view.designDependencies.colors.contains(token.id)
                || view.sourceDependencies.colors.contains(token.id)
                || !derivedGradientIDs.isDisjoint(with: view.designDependencies.gradients)
                || !derivedGradientIDs.isDisjoint(with: view.sourceDependencies.gradients)
        }
    }

    private func relatedComponents(for token: StudioNativeDocument.GradientToken) -> [StudioNativeDocument.ComponentItem] {
        document.components.filter { component in
            component.designDependencies.gradients.contains(token.id)
                || component.sourceDependencies.gradients.contains(token.id)
                || token.designComponentIDs.contains(component.id)
        }
    }

    private func relatedViews(for token: StudioNativeDocument.GradientToken) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { view in
            view.designDependencies.gradients.contains(token.id)
                || view.sourceDependencies.gradients.contains(token.id)
        }
    }

    private var selectionID: String? {
        switch selection {
        case let .color(token):
            return "color:\(token.id)"
        case let .gradient(token):
            return "gradient:\(token.id)"
        case .none:
            return nil
        }
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
    let inspectComponent: (String) -> Void

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

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(token.sourcePaths, id: \.self) { path in
                                        StudioKeyValueRow(label: "Source", value: path)
                                    }
                                }
                            }
                        }

                        if !relatedComponents(for: token).isEmpty {
                            StudioInspectorSection(title: "Used By") {
                                StudioInspectorLinkList(
                                    linkItems: relatedComponents(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                    actionTitle: "Inspect Component",
                                    action: inspectComponent
                                )
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

    private func relatedComponents(for token: StudioNativeDocument.IconToken) -> [StudioNativeDocument.ComponentItem] {
        document.components.filter { $0.designDependencies.preferredIcons.contains(token.id) }
    }
}

private struct StudioTypographyDetailInspector: View {
    let token: StudioNativeDocument.TypographyToken?
    let document: StudioNativeDocument
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

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

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(token.sourcePaths, id: \.self) { path in
                                        StudioKeyValueRow(label: "Source", value: path)
                                    }
                                }
                            }
                        }

                        if !relatedComponents(for: token).isEmpty || !relatedViews(for: token).isEmpty {
                            StudioInspectorSection(title: "Used By") {
                                VStack(alignment: .leading, spacing: 14) {
                                    if !relatedComponents(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Components",
                                            linkItems: relatedComponents(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                            actionTitle: "Inspect Component",
                                            action: inspectComponent
                                        )
                                    }
                                    if !relatedViews(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Views",
                                            linkItems: relatedViews(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.presentation.capitalized) },
                                            actionTitle: "Inspect View",
                                            action: inspectView
                                        )
                                    }
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

    private func relatedComponents(for token: StudioNativeDocument.TypographyToken) -> [StudioNativeDocument.ComponentItem] {
        document.components.filter { $0.sourceDependencies.typography.contains(token.id) }
    }

    private func relatedViews(for token: StudioNativeDocument.TypographyToken) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { $0.sourceDependencies.typography.contains(token.id) }
    }
}

private struct StudioMetricDetailInspector: View {
    let token: StudioNativeDocument.MetricToken?
    let document: StudioNativeDocument
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

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

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: "Evidence") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(token.sourcePaths, id: \.self) { path in
                                        StudioKeyValueRow(label: "Source", value: path)
                                    }
                                }
                            }
                        }

                        if !relatedComponents(for: token).isEmpty || !relatedViews(for: token).isEmpty {
                            StudioInspectorSection(title: "Used By") {
                                VStack(alignment: .leading, spacing: 14) {
                                    if !relatedComponents(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Components",
                                            linkItems: relatedComponents(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                            actionTitle: "Inspect Component",
                                            action: inspectComponent
                                        )
                                    }
                                    if !relatedViews(for: token).isEmpty {
                                        StudioInspectorLinkGroup(
                                            title: "Views",
                                            linkItems: relatedViews(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.presentation.capitalized) },
                                            actionTitle: "Inspect View",
                                            action: inspectView
                                        )
                                    }
                                }
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

    private func relatedComponents(for token: StudioNativeDocument.MetricToken) -> [StudioNativeDocument.ComponentItem] {
        document.components.filter { component in
            metricDependencyIDs(from: component.sourceDependencies, kind: token.kind).contains(token.id)
        }
    }

    private func relatedViews(for token: StudioNativeDocument.MetricToken) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { view in
            metricDependencyIDs(from: view.sourceDependencies, kind: token.kind).contains(token.id)
        }
    }

    private func metricDependencyIDs(from dependencies: StudioNativeDocument.TokenDependencySet, kind: String) -> [String] {
        kind == "cornerRadius" ? dependencies.radius : dependencies.spacing
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
