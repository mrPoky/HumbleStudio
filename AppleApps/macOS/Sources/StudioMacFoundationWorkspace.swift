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
                            Text(StudioStrings.tokensPageTitle)
                                .font(.system(size: 26, weight: .bold))
                            Text(StudioStrings.tokensPageSubtitle)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        StudioGroupedSection(title: StudioStrings.colors, groups: grouped(document.colors, by: \.group)) { item in
                            StudioColorCard(
                                token: item,
                                isSelected: selection == .color(item.id)
                            )
                            .onTapGesture {
                                selection = .color(item.id)
                            }
                        }

                        StudioGroupedSection(title: StudioStrings.gradients, groups: grouped(document.gradients, by: \.group)) { item in
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
                            Text(StudioStrings.iconsPageTitle)
                                .font(.system(size: 26, weight: .bold))
                            Text(StudioStrings.iconsPageSubtitle)
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
                            Text(StudioStrings.typographyPageTitle)
                                .font(.system(size: 26, weight: .bold))
                            Text(StudioStrings.typographyPageSubtitle)
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
                            Text(StudioStrings.spacingPageTitle)
                                .font(.system(size: 26, weight: .bold))
                            Text(StudioStrings.spacingPageSubtitle)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        StudioGroupedSection(title: StudioStrings.spacing, groups: grouped(document.spacing, by: \.group)) { item in
                            StudioMetricCard(
                                token: item,
                                isSelected: selectedMetric(in: document)?.id == item.id && selectedMetric(in: document)?.kind == item.kind
                            )
                            .onTapGesture {
                                selection = .spacing(item.id)
                            }
                        }

                        StudioGroupedSection(title: StudioStrings.cornerRadius, groups: grouped(document.radius, by: \.group)) { item in
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
                Text("\(StudioStrings.points(Int(token.size))) · \(token.weight)")
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
                    Text(StudioStrings.referencesCount(token.referenceCount))
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
                    Text(StudioStrings.referencesCount(token.referenceCount))
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
    private enum Tab: CaseIterable, Identifiable {
        case preview
        case relationships
        case source

        var id: Self { self }

        var title: String {
            switch self {
            case .preview:
                return StudioStrings.preview
            case .relationships:
                return StudioStrings.relationships
            case .source:
                return StudioStrings.source
            }
        }
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
                colorDetail(token)

            case let .gradient(token):
                gradientDetail(token)

            case .none:
                ContentUnavailableView(
                    StudioStrings.selectToken,
                    systemImage: "paintpalette",
                    description: Text(StudioStrings.selectTokenDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onChange(of: selectionID) { _, _ in
            selectedTab = .preview
        }
    }

    @ViewBuilder
    private func colorDetail(_ token: StudioNativeDocument.ColorToken) -> some View {
        let componentLinks = relatedComponents(for: token)
        let viewLinks = relatedViews(for: token)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(StudioStrings.colorDetail)
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
                        StudioPillLabel(text: StudioStrings.referencesCount(token.referenceCount))
                        StudioPillLabel(text: token.lightHex == token.darkHex ? StudioStrings.sharedLightDark : StudioStrings.distinctVariants)
                    }
                }

                StudioInspectorSummaryGrid(items: colorSummaryItems(for: token))

                Picker(StudioStrings.inspectorSection, selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .preview:
                    HStack(spacing: 12) {
                        StudioTonePreviewCard(title: StudioStrings.light, fill: Color(hex: token.lightHex), value: token.lightHex)
                        StudioTonePreviewCard(title: StudioStrings.dark, fill: Color(hex: token.darkHex), value: token.darkHex)
                    }

                    StudioInspectorSection(title: StudioStrings.whatThisIs) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.token, value: token.id)
                            StudioKeyValueRow(label: StudioStrings.group, value: token.group)
                            StudioKeyValueRow(label: StudioStrings.variants, value: token.lightHex == token.darkHex ? StudioStrings.sharedLightDarkValue : StudioStrings.distinctLightDarkValues)
                        }
                    }

                case .relationships:
                    StudioInspectorSection(title: StudioStrings.relationships) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !token.derivedGradientIDs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(StudioStrings.derivedGradients)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.derivedGradientIDs.map(resolvedGradientName(for:)))
                                }
                            }

                            if !componentLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.usedByComponents,
                                    linkItems: componentLinks.map { component in
                                        StudioInspectorLinkItem(id: component.id, title: component.name, subtitle: component.group)
                                    },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }

                            if !viewLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.usedByViews,
                                    linkItems: viewLinks.map { view in
                                        StudioInspectorLinkItem(id: view.id, title: view.name, subtitle: StudioStrings.navigationKindLabel(view.presentation))
                                    },
                                    actionTitle: StudioStrings.inspectView,
                                    action: inspectView
                                )
                            }
                        }
                    }

                case .source:
                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.references, value: "\(token.referenceCount)")
                            ForEach(Array(token.sourcePaths.prefix(6)), id: \.self) { path in
                                StudioKeyValueRow(label: StudioStrings.source, value: path)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func gradientDetail(_ token: StudioNativeDocument.GradientToken) -> some View {
        let componentLinks = relatedComponents(for: token)
        let viewLinks = relatedViews(for: token)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(StudioStrings.gradientDetail)
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
                        StudioPillLabel(text: StudioStrings.referencesCount(token.referenceCount))
                        StudioPillLabel(text: token.kind.capitalized)
                        if !token.designComponentIDs.isEmpty {
                            StudioPillLabel(text: StudioStrings.componentsCount(token.designComponentIDs.count))
                        }
                    }
                }

                StudioInspectorSummaryGrid(items: gradientSummaryItems(for: token))

                Picker(StudioStrings.inspectorSection, selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .preview:
                    VStack(spacing: 12) {
                        StudioGradientTonePreviewCard(title: StudioStrings.light, colors: token.lightColors)
                        StudioGradientTonePreviewCard(title: StudioStrings.dark, colors: token.darkColors)
                    }

                    StudioInspectorSection(title: StudioStrings.whatThisIs) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.token, value: token.id)
                            StudioKeyValueRow(label: StudioStrings.type, value: token.kind.capitalized)
                            if !token.swiftUI.isEmpty {
                                StudioKeyValueRow(label: StudioStrings.swiftUILabel, value: token.swiftUI)
                            }
                        }
                    }

                case .relationships:
                    StudioInspectorSection(title: StudioStrings.relationships) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !token.tokenColors.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(StudioStrings.tokenColors)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    FlexiblePillStack(items: token.tokenColors.map(resolvedColorName(for:)))
                                }
                            }

                            if !componentLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.usedByComponents,
                                    linkItems: componentLinks.map { component in
                                        StudioInspectorLinkItem(id: component.id, title: component.name, subtitle: component.group)
                                    },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }

                            if !viewLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.usedByViews,
                                    linkItems: viewLinks.map { view in
                                        StudioInspectorLinkItem(id: view.id, title: view.name, subtitle: StudioStrings.navigationKindLabel(view.presentation))
                                    },
                                    actionTitle: StudioStrings.inspectView,
                                    action: inspectView
                                )
                            }
                        }
                    }

                case .source:
                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioKeyValueRow(label: StudioStrings.references, value: "\(token.referenceCount)")
                            ForEach(Array(token.sourcePaths.prefix(6)), id: \.self) { path in
                                StudioKeyValueRow(label: StudioStrings.source, value: path)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func colorSummaryItems(for token: StudioNativeDocument.ColorToken) -> [StudioInspectorSummaryItem] {
        [
            StudioInspectorSummaryItem(label: StudioStrings.group, value: token.group.capitalized, tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.references, value: "\(token.referenceCount)", tone: .accent),
            StudioInspectorSummaryItem(
                label: StudioStrings.variants,
                value: token.lightHex == token.darkHex ? StudioStrings.sharedLightDark : StudioStrings.distinctLightDarkValues,
                tone: token.lightHex == token.darkHex ? .neutral : .success
            ),
            StudioInspectorSummaryItem(label: StudioStrings.derivedGradients, value: "\(token.derivedGradientIDs.count)", tone: .neutral)
        ]
    }

    private func gradientSummaryItems(for token: StudioNativeDocument.GradientToken) -> [StudioInspectorSummaryItem] {
        [
            StudioInspectorSummaryItem(label: StudioStrings.group, value: token.group.capitalized, tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.type, value: token.kind.capitalized, tone: .accent),
            StudioInspectorSummaryItem(label: StudioStrings.references, value: "\(token.referenceCount)", tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.components, value: "\(token.designComponentIDs.count)", tone: .success)
        ]
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
                        Text(StudioStrings.iconDetail)
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

                        StudioInspectorSummaryGrid(items: [
                            StudioInspectorSummaryItem(
                                label: StudioStrings.symbol,
                                value: token.symbol,
                                tone: .accent
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.references,
                                value: "\(token.referenceCount)",
                                tone: .neutral
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.truth,
                                value: StudioStrings.bundledAsset,
                                tone: .success
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.usedBy,
                                value: StudioStrings.componentsCount(relatedComponents(for: token).count),
                                tone: .neutral
                            )
                        ])

                        StudioMacIconThumbnail(url: document.resolvedIconURL(for: token), symbol: token.symbol)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                        StudioInspectorSection(title: StudioStrings.contract) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: StudioStrings.symbol, value: token.symbol)
                                StudioKeyValueRow(label: StudioStrings.references, value: "\(token.referenceCount)")
                                StudioKeyValueRow(label: StudioStrings.truth, value: StudioStrings.bundledAsset)
                            }
                        }

                        StudioInspectorSection(title: StudioStrings.asset) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: StudioStrings.path, value: token.assetPath.isEmpty ? "—" : token.assetPath)
                                StudioKeyValueRow(label: StudioStrings.identifier, value: token.id)
                            }
                        }

                        if !token.sourcePaths.isEmpty {
                            StudioInspectorSection(title: StudioStrings.evidence) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(token.sourcePaths, id: \.self) { path in
                                        StudioKeyValueRow(label: StudioStrings.source, value: path)
                                    }
                                }
                            }
                        }

                        if !relatedComponents(for: token).isEmpty {
                            StudioInspectorSection(title: StudioStrings.usedBy) {
                                StudioInspectorLinkList(
                                    linkItems: relatedComponents(for: token).map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    StudioStrings.selectIcon,
                    systemImage: "app.dashed",
                    description: Text(StudioStrings.selectIconDescription)
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
    @State private var previewConfiguration = StudioPreviewConfiguration()

    var body: some View {
        Group {
            if let token {
                typographyDetail(token)
            } else {
                ContentUnavailableView(
                    StudioStrings.selectTypographyRole,
                    systemImage: "textformat",
                    description: Text(StudioStrings.selectTypographyRoleDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onAppear {
            if let token {
                previewConfiguration = typographyPreviewConfiguration(for: token)
            }
        }
        .onChange(of: token?.id) { _, _ in
            if let token {
                previewConfiguration = typographyPreviewConfiguration(for: token)
            } else {
                previewConfiguration = StudioPreviewConfiguration()
            }
        }
    }

    @ViewBuilder
    private func typographyDetail(_ token: StudioNativeDocument.TypographyToken) -> some View {
        let componentLinks = relatedComponents(for: token)
        let viewLinks = relatedViews(for: token)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(StudioStrings.typographyDetail)
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

                StudioInspectorSummaryGrid(items: typographySummaryItems(for: token, componentCount: componentLinks.count, viewCount: viewLinks.count))

                StudioInspectorSection(title: StudioStrings.previewSurface) {
                    VStack(alignment: .leading, spacing: 14) {
                        StudioPreviewControls(configuration: $previewConfiguration)

                        StudioPreviewSurface(appearance: .light, configuration: previewConfiguration) {
                            StudioTypographyPreviewContent(token: token)
                        }
                    }
                }

                StudioInspectorSection(title: StudioStrings.contract) {
                    VStack(alignment: .leading, spacing: 10) {
                        StudioKeyValueRow(label: StudioStrings.size, value: StudioStrings.points(Int(token.size)))
                        StudioKeyValueRow(label: StudioStrings.weight, value: "\(token.weight)")
                        StudioKeyValueRow(label: StudioStrings.references, value: "\(token.referenceCount)")
                        StudioPreviewContractPanel(configuration: previewConfiguration)
                        if !token.swiftUI.isEmpty {
                            StudioKeyValueRow(label: StudioStrings.swiftUILabel, value: token.swiftUI)
                        }
                    }
                }

                StudioInspectorSection(title: StudioStrings.contextPreview) {
                    VStack(alignment: .leading, spacing: 10) {
                        StudioKeyValueRow(label: StudioStrings.coverageStatus, value: StudioStrings.previewCoverageLabel(nativeTypographyPreviewCoverage(for: token)))
                        StudioKeyValueRow(label: StudioStrings.flowContext, value: StudioStrings.previewStackContextLabel(previewConfiguration.stackContext))
                        StudioKeyValueRow(label: StudioStrings.usageSignal, value: viewLinks.isEmpty ? StudioStrings.mostlyComponentScoped : StudioStrings.visibleInViewLevelFlows)
                    }
                }

                if !token.sourcePaths.isEmpty {
                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(token.sourcePaths, id: \.self) { path in
                                StudioKeyValueRow(label: StudioStrings.source, value: path)
                            }
                        }
                    }
                }

                if !componentLinks.isEmpty || !viewLinks.isEmpty {
                    StudioInspectorSection(title: StudioStrings.usedBy) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !componentLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.components,
                                    linkItems: componentLinks.map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }
                            if !viewLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.views,
                                    linkItems: viewLinks.map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: StudioStrings.navigationKindLabel($0.presentation)) },
                                    actionTitle: StudioStrings.inspectView,
                                    action: inspectView
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func typographySummaryItems(for token: StudioNativeDocument.TypographyToken, componentCount: Int, viewCount: Int) -> [StudioInspectorSummaryItem] {
        [
            StudioInspectorSummaryItem(label: StudioStrings.size, value: StudioStrings.points(Int(token.size)), tone: .accent),
            StudioInspectorSummaryItem(label: StudioStrings.weight, value: "\(token.weight)", tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.references, value: "\(token.referenceCount)", tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.usedBy, value: StudioStrings.itemsCount(componentCount + viewCount), tone: .success)
        ]
    }

    private func relatedComponents(for token: StudioNativeDocument.TypographyToken) -> [StudioNativeDocument.ComponentItem] {
        document.components.filter { $0.sourceDependencies.typography.contains(token.id) }
    }

    private func relatedViews(for token: StudioNativeDocument.TypographyToken) -> [StudioNativeDocument.ViewItem] {
        document.views.filter { $0.sourceDependencies.typography.contains(token.id) }
    }

    private func typographyPreviewConfiguration(for token: StudioNativeDocument.TypographyToken) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration()
        if token.size >= 28 {
            configuration.device = StudioPreviewCatalog.devices.first(where: { $0.id == "ipad-portrait" }) ?? configuration.device
        }
        configuration.navigationChrome = .none
        configuration.stackContext = relatedViews(for: token).isEmpty ? .single : .stacked
        configuration.coverageLevel = nativeTypographyPreviewCoverage(for: token)
        return configuration
    }
}

private struct StudioMetricDetailInspector: View {
    let token: StudioNativeDocument.MetricToken?
    let document: StudioNativeDocument
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var previewConfiguration = StudioPreviewConfiguration()

    var body: some View {
        Group {
            if let token {
                metricDetail(token)
            } else {
                ContentUnavailableView(
                    StudioStrings.selectSpatialToken,
                    systemImage: "rectangle.inset.filled",
                    description: Text(StudioStrings.selectSpatialTokenDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onAppear {
            if let token {
                previewConfiguration = metricPreviewConfiguration(for: token)
            }
        }
        .onChange(of: token?.id) { _, _ in
            if let token {
                previewConfiguration = metricPreviewConfiguration(for: token)
            } else {
                previewConfiguration = StudioPreviewConfiguration()
            }
        }
    }

    @ViewBuilder
    private func metricDetail(_ token: StudioNativeDocument.MetricToken) -> some View {
        let componentLinks = relatedComponents(for: token)
        let viewLinks = relatedViews(for: token)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(token.kind == "cornerRadius" ? StudioStrings.cornerRadiusDetail : StudioStrings.spacingDetail)
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

                StudioInspectorSummaryGrid(items: metricSummaryItems(for: token, componentCount: componentLinks.count, viewCount: viewLinks.count))

                StudioInspectorSection(title: StudioStrings.previewSurface) {
                    VStack(alignment: .leading, spacing: 14) {
                        StudioPreviewControls(configuration: $previewConfiguration)

                        StudioPreviewSurface(appearance: .light, configuration: previewConfiguration) {
                            StudioMetricPreviewContent(token: token)
                        }
                    }
                }

                StudioInspectorSection(title: StudioStrings.contract) {
                    VStack(alignment: .leading, spacing: 10) {
                        StudioKeyValueRow(label: StudioStrings.group, value: token.group)
                        StudioKeyValueRow(label: StudioStrings.value, value: token.value)
                        StudioKeyValueRow(label: StudioStrings.type, value: token.kindLabel)
                        StudioKeyValueRow(label: StudioStrings.references, value: "\(token.referenceCount)")
                        StudioPreviewContractPanel(configuration: previewConfiguration)
                    }
                }

                StudioInspectorSection(title: StudioStrings.contextPreview) {
                    VStack(alignment: .leading, spacing: 10) {
                        StudioKeyValueRow(label: StudioStrings.coverageStatus, value: StudioStrings.previewCoverageLabel(nativeMetricPreviewCoverage(for: token)))
                        StudioKeyValueRow(label: StudioStrings.flowContext, value: StudioStrings.previewStackContextLabel(previewConfiguration.stackContext))
                        StudioKeyValueRow(label: StudioStrings.usageSignal, value: token.usage.isEmpty ? StudioStrings.noExportedUsageGuidanceYet : token.usage)
                    }
                }

                if !token.usage.isEmpty {
                    StudioInspectorSection(title: StudioStrings.usage) {
                        Text(token.usage)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !token.sourcePaths.isEmpty {
                    StudioInspectorSection(title: StudioStrings.evidence) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(token.sourcePaths, id: \.self) { path in
                                StudioKeyValueRow(label: StudioStrings.source, value: path)
                            }
                        }
                    }
                }

                if !componentLinks.isEmpty || !viewLinks.isEmpty {
                    StudioInspectorSection(title: StudioStrings.usedBy) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !componentLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.components,
                                    linkItems: componentLinks.map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: $0.group) },
                                    actionTitle: StudioStrings.inspectComponent,
                                    action: inspectComponent
                                )
                            }
                            if !viewLinks.isEmpty {
                                StudioInspectorLinkGroup(
                                    title: StudioStrings.views,
                                    linkItems: viewLinks.map { StudioInspectorLinkItem(id: $0.id, title: $0.name, subtitle: StudioStrings.navigationKindLabel($0.presentation)) },
                                    actionTitle: StudioStrings.inspectView,
                                    action: inspectView
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func metricSummaryItems(for token: StudioNativeDocument.MetricToken, componentCount: Int, viewCount: Int) -> [StudioInspectorSummaryItem] {
        [
            StudioInspectorSummaryItem(label: StudioStrings.type, value: token.kindLabel, tone: .accent),
            StudioInspectorSummaryItem(label: StudioStrings.value, value: token.value, tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.references, value: "\(token.referenceCount)", tone: .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.usedBy, value: StudioStrings.itemsCount(componentCount + viewCount), tone: .success)
        ]
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

    private func metricPreviewConfiguration(for token: StudioNativeDocument.MetricToken) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration()
        configuration.navigationChrome = .none
        if token.kind == "cornerRadius" {
            configuration.presentationMode = .sheet
        }
        configuration.stackContext = relatedViews(for: token).isEmpty ? .single : .stacked
        configuration.coverageLevel = nativeMetricPreviewCoverage(for: token)
        return configuration
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

private struct StudioMetricPreviewContent: View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct StudioTypographyPreviewContent: View {
    let token: StudioNativeDocument.TypographyToken

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(token.preview)
                    .font(.system(size: max(24, min(token.size, 52)), weight: token.fontWeight))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .opacity(0.35)

                Text(StudioStrings.typographyPreviewSample)
                    .font(.system(size: max(15, min(token.size * 0.72, 28)), weight: token.fontWeight))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                Text("\(StudioStrings.points(Int(token.size))) · \(token.weight)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.42), in: Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
