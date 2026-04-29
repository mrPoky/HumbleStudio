import SwiftUI

struct StudioMacReviewPage: View {
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

struct StudioMacNavigationPage: View {
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
