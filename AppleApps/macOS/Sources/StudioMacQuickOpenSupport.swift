import SwiftUI

struct StudioMacQuickOpenContext {
    let document: StudioNativeDocument?
    let navigateToDestination: (StudioNativeDestination) -> Void
    let inspectToken: (StudioNativeTokenSelection) -> Void
    let inspectIcon: (String) -> Void
    let inspectTypography: (String) -> Void
    let inspectMetric: (StudioNativeMetricSelection) -> Void
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
}

struct StudioQuickOpenItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbolName: String
    let section: String
    let keywords: [String]
    let activate: () -> Void

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedQuery.isEmpty { return true }
        let haystack = ([title, subtitle, section] + keywords).joined(separator: " ").lowercased()
        return haystack.contains(normalizedQuery)
    }

    func score(for query: String) -> Int {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedQuery.isEmpty { return 0 }
        let titleValue = title.lowercased()
        let subtitleValue = subtitle.lowercased()
        if titleValue == normalizedQuery { return 0 }
        if titleValue.hasPrefix(normalizedQuery) { return 1 }
        if titleValue.contains(normalizedQuery) { return 2 }
        if subtitleValue.contains(normalizedQuery) { return 3 }
        return 4
    }
}

enum StudioMacQuickOpenFactory {
    static func makeItems(context: StudioMacQuickOpenContext) -> [StudioQuickOpenItem] {
        var items: [StudioQuickOpenItem] = [
            pageItem(.overview, subtitle: "Native app overview and migration status", context: context),
            pageItem(.tokens, subtitle: "Colors and gradients", context: context),
            pageItem(.components, subtitle: "Snapshot-first component catalog", context: context),
            pageItem(.views, subtitle: "Screen catalog and flow truth", context: context),
            pageItem(.review, subtitle: "Truth gaps and review queue", context: context),
            pageItem(.navigation, subtitle: "Native navigation graph", context: context),
            pageItem(.icons, subtitle: "Bundled icon catalog", context: context),
            pageItem(.typography, subtitle: "Typography roles", context: context),
            pageItem(.spacing, subtitle: "Spacing and corner radius", context: context),
            pageItem(.legacyWeb, subtitle: "Fallback web inspector", context: context)
        ]

        guard let document = context.document else { return items }

        items.append(contentsOf: document.colors.map { token in
            StudioQuickOpenItem(
                title: token.name,
                subtitle: "Color token · \(token.group)",
                symbolName: "paintpalette",
                section: "Colors",
                keywords: [token.id, token.group, token.lightHex, token.darkHex],
                activate: { context.inspectToken(.color(token.id)) }
            )
        })
        items.append(contentsOf: document.gradients.map { token in
            StudioQuickOpenItem(
                title: token.name,
                subtitle: "Gradient token · \(token.group)",
                symbolName: "sparkles",
                section: "Gradients",
                keywords: [token.id, token.group, token.swiftUI, token.usage],
                activate: { context.inspectToken(.gradient(token.id)) }
            )
        })
        items.append(contentsOf: document.icons.map { token in
            StudioQuickOpenItem(
                title: token.name,
                subtitle: "Icon · \(token.symbol)",
                symbolName: "app.gift",
                section: "Icons",
                keywords: [token.id, token.symbol, token.description],
                activate: { context.inspectIcon(token.id) }
            )
        })
        items.append(contentsOf: document.typography.map { token in
            StudioQuickOpenItem(
                title: token.role,
                subtitle: "Typography · \(Int(token.size)) pt",
                symbolName: "textformat",
                section: "Typography",
                keywords: [token.id, token.swiftUI, token.preview],
                activate: { context.inspectTypography(token.id) }
            )
        })
        items.append(contentsOf: document.spacing.map { token in
            StudioQuickOpenItem(
                title: token.name,
                subtitle: "Spacing · \(token.value)",
                symbolName: "rectangle.inset.filled",
                section: "Spacing",
                keywords: [token.id, token.group, token.usage],
                activate: { context.inspectMetric(.spacing(token.id)) }
            )
        })
        items.append(contentsOf: document.radius.map { token in
            StudioQuickOpenItem(
                title: token.name,
                subtitle: "Corner radius · \(token.value)",
                symbolName: "roundedcorner",
                section: "Corner Radius",
                keywords: [token.id, token.group, token.usage],
                activate: { context.inspectMetric(.radius(token.id)) }
            )
        })
        items.append(contentsOf: document.components.map { component in
            StudioQuickOpenItem(
                title: component.name,
                subtitle: "Component · \(component.group)",
                symbolName: "square.grid.3x2",
                section: "Components",
                keywords: [component.id, component.renderer, component.swiftUI, component.summary],
                activate: { context.inspectComponent(component.id) }
            )
        })
        items.append(contentsOf: document.views.map { view in
            StudioQuickOpenItem(
                title: view.name,
                subtitle: "View · \(view.presentation.capitalized)",
                symbolName: "rectangle.on.rectangle",
                section: "Views",
                keywords: [view.id, view.presentation, view.summary],
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
            title: destination.title,
            subtitle: subtitle,
            symbolName: destination.symbolName,
            section: "Pages",
            keywords: [destination.rawValue, destination.subtitle],
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

    private var filteredItems: [StudioQuickOpenItem] {
        items
            .filter { $0.matches(query) }
            .sorted { lhs, rhs in
                let lhsScore = lhs.score(for: query)
                let rhsScore = rhs.score(for: query)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                if lhs.section != rhs.section { return lhs.section < rhs.section }
                return lhs.title < rhs.title
            }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Quick Open")
                            .font(.system(size: 24, weight: .bold))
                        Spacer()
                        Text("\(filteredItems.count) results")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.45), in: Capsule())
                            .foregroundStyle(.secondary)
                    }

                    TextField("Search pages, foundations, components, and views…", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .focused($isSearchFocused)
                        .onSubmit {
                            guard let first = filteredItems.first else { return }
                            onSelect(first)
                            dismiss()
                        }
                }
                .padding(20)

                Divider()
                    .opacity(0.35)

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching by token name, component, view, or page.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
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
                                                Text(item.title)
                                                    .foregroundStyle(.primary)
                                                Text(item.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Quick Open")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func groupedQuickOpenItems(_ items: [StudioQuickOpenItem]) -> [(String, [StudioQuickOpenItem])] {
        let grouped = Dictionary(grouping: items, by: \.section)
        return grouped.keys.sorted().map { key in
            (key, grouped[key] ?? [])
        }
    }
}
