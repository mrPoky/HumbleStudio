import SwiftUI

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
