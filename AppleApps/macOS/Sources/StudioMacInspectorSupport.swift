import SwiftUI

struct StudioNativePageContainer<Content: View>: View {
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

struct StudioCountCard: View {
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

struct StudioMigrationCard: View {
    let title: String
    let message: String

    var body: some View {
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
}

struct StudioPillLabel: View {
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

struct StudioInspectorSection<Content: View>: View {
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

struct StudioInspectorLinkItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
}

struct StudioInspectorLinkGroup: View {
    let title: String
    let linkItems: [StudioInspectorLinkItem]
    let actionTitle: String
    let action: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            StudioInspectorLinkList(linkItems: linkItems, actionTitle: actionTitle, action: action)
        }
    }
}

struct StudioInspectorLinkList: View {
    let linkItems: [StudioInspectorLinkItem]
    let actionTitle: String
    let action: (String) -> Void

    var body: some View {
        let items = linkItems
        VStack(alignment: .leading, spacing: 10) {
            SwiftUI.ForEach(items, id: \.id) { item in
                Button {
                    action(item.id)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 12)
                        Text(actionTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StudioKeyValueRow: View {
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

struct FlexiblePillStack: View {
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

struct StudioNativeReviewCard: View {
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

struct StudioNativeNavigationNodeCard: View {
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

func grouped<Item>(_ items: [Item], by keyPath: KeyPath<Item, String>) -> [(String, [Item])] {
    let groupedItems = Dictionary(grouping: items) { $0[keyPath: keyPath] }
    return groupedItems.keys.sorted().map { key in
        (key, groupedItems[key] ?? [])
    }
}

extension Color {
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

extension StudioNativeDocument.MetricToken {
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

extension StudioNativeDocument.TypographyToken {
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

struct StudioNativeTruthStatus {
    let label: String
    let color: Color
    let needsAttention: Bool
}

struct NativeNavigationIncomingEdge: Identifiable {
    let id: String
    let sourceID: String
    let targetID: String
    let trigger: String
    let type: String
}

struct NativeNavigationLevel: Identifiable {
    let depth: Int
    let views: [StudioNativeDocument.ViewItem]

    var id: Int { depth }
}

struct NativeNavigationGraph {
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

func makeNativeNavigationGraph(document: StudioNativeDocument) -> NativeNavigationGraph {
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

    let groupedViews = Dictionary(grouping: document.views) { depths[$0.id] ?? 0 }
    let levels = groupedViews.keys.sorted().map { depth in
        NativeNavigationLevel(
            depth: depth,
            views: (groupedViews[depth] ?? []).sorted { lhs, rhs in
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

func nativeComponentTruthStatus(for component: StudioNativeDocument.ComponentItem) -> StudioNativeTruthStatus {
    if component.snapshot != nil {
        return StudioNativeTruthStatus(label: "Reference snapshot", color: .green, needsAttention: false)
    }
    if component.statesCount > 0 {
        return StudioNativeTruthStatus(label: "Catalog only", color: .orange, needsAttention: true)
    }
    return StudioNativeTruthStatus(label: "Approximation only", color: .red, needsAttention: true)
}

func nativeViewTruthStatus(for view: StudioNativeDocument.ViewItem) -> StudioNativeTruthStatus {
    if view.snapshot != nil {
        return StudioNativeTruthStatus(label: "Reference snapshot", color: .green, needsAttention: false)
    }
    return StudioNativeTruthStatus(label: "Catalog only", color: .orange, needsAttention: true)
}

func nativeComponentReviewReason(for component: StudioNativeDocument.ComponentItem) -> String {
    if component.snapshot == nil && component.statesCount == 0 {
        return "No reference snapshot is exported and the native inspector also has no declared state catalog to lean on yet."
    }
    if component.snapshot == nil {
        return "The component has declared states, but there is still no exported reference snapshot to confirm visual truth."
    }
    return "This component is fully backed by exported truth."
}

func nativeViewReviewReason(for view: StudioNativeDocument.ViewItem) -> String {
    if view.snapshot == nil {
        return "The screen has flow and component metadata, but no exported reference snapshot yet, so visual truth still needs review."
    }
    return "This view is fully backed by exported truth."
}

func getComponentUsageCount(_ component: StudioNativeDocument.ComponentItem, in document: StudioNativeDocument) -> Int {
    document.views.filter { $0.components.contains(component.id) }.count
}
