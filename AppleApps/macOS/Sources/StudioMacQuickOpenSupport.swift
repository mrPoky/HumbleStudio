import SwiftUI

struct StudioMacQuickOpenContext {
    let document: StudioNativeDocument?
    let recentKeys: [String]
    let currentKey: String?
    let navigateToDestination: (StudioNativeDestination) -> Void
    let inspectToken: (StudioNativeTokenSelection) -> Void
    let inspectIcon: (String) -> Void
    let inspectTypography: (String) -> Void
    let inspectMetric: (StudioNativeMetricSelection) -> Void
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
}

struct StudioQuickOpenItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let section: String
    let keywords: [String]
    let isCurrent: Bool
    let isRecent: Bool
    let activate: () -> Void

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedQuery.isEmpty { return true }
        let haystack = ([title, subtitle, section] + keywords).joined(separator: " ").lowercased()
        return haystack.contains(normalizedQuery)
    }

    func score(for query: String, currentKey: String?, recentKeys: [String]) -> Int {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isCurrent = id == currentKey
        let recentRank = recentKeys.firstIndex(of: id)

        if normalizedQuery.isEmpty {
            if isCurrent { return -2 }
            if let recentRank { return recentRank }
            return 100
        }

        let titleValue = title.lowercased()
        let subtitleValue = subtitle.lowercased()
        let baseScore: Int
        if titleValue == normalizedQuery {
            baseScore = 0
        } else if titleValue.hasPrefix(normalizedQuery) {
            baseScore = 1
        } else if titleValue.contains(normalizedQuery) {
            baseScore = 2
        } else if subtitleValue.contains(normalizedQuery) {
            baseScore = 3
        } else {
            baseScore = 4
        }

        if isCurrent { return baseScore - 2 }
        if let recentRank { return baseScore + min(recentRank, 3) - 1 }
        return baseScore
    }

    var isPage: Bool {
        section == StudioStrings.pages
    }
}

enum StudioMacQuickOpenFactory {
    static func makeItems(context: StudioMacQuickOpenContext) -> [StudioQuickOpenItem] {
        var items: [StudioQuickOpenItem] = [
            pageItem(.overview, subtitle: StudioStrings.destinationSubtitle(.overview), context: context),
            pageItem(.tokens, subtitle: StudioStrings.destinationSubtitle(.tokens), context: context),
            pageItem(.components, subtitle: StudioStrings.destinationSubtitle(.components), context: context),
            pageItem(.views, subtitle: StudioStrings.destinationSubtitle(.views), context: context),
            pageItem(.review, subtitle: StudioStrings.destinationSubtitle(.review), context: context),
            pageItem(.navigation, subtitle: StudioStrings.destinationSubtitle(.navigation), context: context),
            pageItem(.proposals, subtitle: StudioStrings.destinationSubtitle(.proposals), context: context),
            pageItem(.icons, subtitle: StudioStrings.destinationSubtitle(.icons), context: context),
            pageItem(.typography, subtitle: StudioStrings.destinationSubtitle(.typography), context: context),
            pageItem(.spacing, subtitle: StudioStrings.destinationSubtitle(.spacing), context: context),
            pageItem(.legacyWeb, subtitle: StudioStrings.destinationSubtitle(.legacyWeb), context: context)
        ]

        guard let document = context.document else { return items }

        items.append(contentsOf: document.colors.map { token in
            StudioQuickOpenItem(
                id: "color:\(token.id)",
                title: token.name,
                subtitle: StudioStrings.colorTokenSummary(token.group),
                symbolName: "paintpalette",
                section: StudioStrings.colors,
                keywords: [token.id, token.group, token.lightHex, token.darkHex],
                isCurrent: context.currentKey == "color:\(token.id)",
                isRecent: context.recentKeys.contains("color:\(token.id)"),
                activate: { context.inspectToken(.color(token.id)) }
            )
        })
        items.append(contentsOf: document.gradients.map { token in
            StudioQuickOpenItem(
                id: "gradient:\(token.id)",
                title: token.name,
                subtitle: StudioStrings.gradientTokenSummary(token.group),
                symbolName: "sparkles",
                section: StudioStrings.gradients,
                keywords: [token.id, token.group, token.swiftUI, token.usage],
                isCurrent: context.currentKey == "gradient:\(token.id)",
                isRecent: context.recentKeys.contains("gradient:\(token.id)"),
                activate: { context.inspectToken(.gradient(token.id)) }
            )
        })
        items.append(contentsOf: document.icons.map { token in
            StudioQuickOpenItem(
                id: "icon:\(token.id)",
                title: token.name,
                subtitle: StudioStrings.iconSummary(token.symbol),
                symbolName: "app.gift",
                section: StudioStrings.iconsPageTitle,
                keywords: [token.id, token.symbol, token.description],
                isCurrent: context.currentKey == "icon:\(token.id)",
                isRecent: context.recentKeys.contains("icon:\(token.id)"),
                activate: { context.inspectIcon(token.id) }
            )
        })
        items.append(contentsOf: document.typography.map { token in
            StudioQuickOpenItem(
                id: "typography:\(token.id)",
                title: token.role,
                subtitle: StudioStrings.typographySummary(points: Int(token.size)),
                symbolName: "textformat",
                section: StudioStrings.typographyPageTitle,
                keywords: [token.id, token.swiftUI, token.preview],
                isCurrent: context.currentKey == "typography:\(token.id)",
                isRecent: context.recentKeys.contains("typography:\(token.id)"),
                activate: { context.inspectTypography(token.id) }
            )
        })
        items.append(contentsOf: document.spacing.map { token in
            StudioQuickOpenItem(
                id: "spacing:\(token.id)",
                title: token.name,
                subtitle: StudioStrings.spacingSummary(token.value),
                symbolName: "rectangle.inset.filled",
                section: StudioStrings.spacing,
                keywords: [token.id, token.group, token.usage],
                isCurrent: context.currentKey == "spacing:\(token.id)",
                isRecent: context.recentKeys.contains("spacing:\(token.id)"),
                activate: { context.inspectMetric(.spacing(token.id)) }
            )
        })
        items.append(contentsOf: document.radius.map { token in
            StudioQuickOpenItem(
                id: "radius:\(token.id)",
                title: token.name,
                subtitle: StudioStrings.cornerRadiusSummary(token.value),
                symbolName: "roundedcorner",
                section: StudioStrings.cornerRadius,
                keywords: [token.id, token.group, token.usage],
                isCurrent: context.currentKey == "radius:\(token.id)",
                isRecent: context.recentKeys.contains("radius:\(token.id)"),
                activate: { context.inspectMetric(.radius(token.id)) }
            )
        })
        items.append(contentsOf: document.components.map { component in
            StudioQuickOpenItem(
                id: "component:\(component.id)",
                title: component.name,
                subtitle: StudioStrings.componentSummary(component.group),
                symbolName: "square.grid.3x2",
                section: StudioStrings.components,
                keywords: [component.id, component.renderer, component.swiftUI, component.summary],
                isCurrent: context.currentKey == "component:\(component.id)",
                isRecent: context.recentKeys.contains("component:\(component.id)"),
                activate: { context.inspectComponent(component.id) }
            )
        })
        items.append(contentsOf: document.views.map { view in
            StudioQuickOpenItem(
                id: "view:\(view.id)",
                title: view.name,
                subtitle: StudioStrings.viewSummary(view.presentation),
                symbolName: "rectangle.on.rectangle",
                section: StudioStrings.views,
                keywords: [view.id, view.presentation, view.summary],
                isCurrent: context.currentKey == "view:\(view.id)",
                isRecent: context.recentKeys.contains("view:\(view.id)"),
                activate: { context.inspectView(view.id) }
            )
        })

        return items
    }

    private static func pageItem(
        _ destination: StudioNativeDestination,
        subtitle: String,
        context: StudioMacQuickOpenContext
    ) -> StudioQuickOpenItem {
        StudioQuickOpenItem(
            id: "page:\(destination.rawValue)",
            title: destination.title,
            subtitle: subtitle,
            symbolName: destination.symbolName,
            section: StudioStrings.pages,
            keywords: [destination.rawValue, destination.subtitle],
            isCurrent: context.currentKey == "page:\(destination.rawValue)",
            isRecent: context.recentKeys.contains("page:\(destination.rawValue)"),
            activate: { context.navigateToDestination(destination) }
        )
    }
}

struct StudioNativeQuickOpenSheet: View {
    let items: [StudioQuickOpenItem]
    let onSelect: (StudioQuickOpenItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var selectedItemID: String?

    private var filteredItems: [StudioQuickOpenItem] {
        items
            .filter { $0.matches(query) }
            .sorted { lhs, rhs in
                let lhsScore = lhs.score(for: query, currentKey: currentItemID, recentKeys: recentItemIDs)
                let rhsScore = rhs.score(for: query, currentKey: currentItemID, recentKeys: recentItemIDs)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                if lhs.section != rhs.section { return lhs.section < rhs.section }
                return lhs.title < rhs.title
            }
    }

    private var currentItemID: String? {
        items.first(where: \.isCurrent)?.id
    }

    private var recentItemIDs: [String] {
        items.filter(\.isRecent).map(\.id)
    }

    private var selectedItem: StudioQuickOpenItem? {
        if let selectedItemID {
            return filteredItems.first(where: { $0.id == selectedItemID })
        }
        return filteredItems.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(StudioStrings.quickOpen)
                            .font(.system(size: 24, weight: .bold))
                        Spacer()
                        Text(StudioStrings.resultsCount(filteredItems.count))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.45), in: Capsule())
                            .foregroundStyle(.secondary)
                    }

                        TextField(StudioStrings.quickOpenSearchPlaceholder, text: $query)
                        .textFieldStyle(.roundedBorder)
                        .focused($isSearchFocused)
                        .onSubmit {
                            guard let selectedItem else { return }
                            onSelect(selectedItem)
                            dismiss()
                        }
                }
                .padding(20)

                Divider()
                    .opacity(0.35)

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        StudioStrings.quickOpenNoMatches,
                        systemImage: "magnifyingglass",
                        description: Text(StudioStrings.quickOpenNoMatchesDescription)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedItemID) {
                        ForEach(groupedQuickOpenItems(filteredItems), id: \.0) { section, sectionItems in
                            Section(section) {
                                ForEach(sectionItems) { item in
                                    Button {
                                        onSelect(item)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: item.symbolName)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 18)
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 8) {
                                                    Text(item.title)
                                                        .foregroundStyle(.primary)
                                                    if item.isCurrent {
                                                        quickOpenBadge(StudioStrings.current)
                                                    } else if item.isRecent {
                                                        quickOpenBadge(StudioStrings.recent)
                                                    }
                                                }
                                                Text(item.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .tag(item.id)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle(StudioStrings.quickOpen)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(StudioStrings.close) {
                        dismiss()
                    }
                }
            }
        }
        .onMoveCommand { direction in
            switch direction {
            case .down:
                moveSelection(by: 1)
            case .up:
                moveSelection(by: -1)
            default:
                break
            }
        }
        .onAppear {
            isSearchFocused = true
            selectedItemID = filteredItems.first?.id
        }
        .onChange(of: query) { _, _ in
            selectedItemID = filteredItems.first?.id
        }
    }

    private func groupedQuickOpenItems(_ items: [StudioQuickOpenItem]) -> [(String, [StudioQuickOpenItem])] {
        let grouped = Dictionary(grouping: items, by: \.section)
        return grouped.keys.sorted().map { key in
            (key, grouped[key] ?? [])
        }
    }

    private func moveSelection(by offset: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), filteredItems.count - 1)
        selectedItemID = filteredItems[nextIndex].id
    }

    @ViewBuilder
    private func quickOpenBadge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.55), in: Capsule())
            .foregroundStyle(.secondary)
    }
}
