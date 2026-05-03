import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct StudioChangeProposalArtifact: Identifiable, Equatable {
    let url: URL
    let scope: String
    let evidenceItems: [String]
    let coverage: String
    let area: String
    let requestedChange: String
    let why: String
    let tokenCandidate: String
    let componentCandidate: String
    let viewCandidate: String
    let structuredTargets: String
    let acceptanceChecks: [String]
    let updatedAt: Date

    var id: String { url.path }
    var title: String { url.deletingPathExtension().lastPathComponent }
    var evidence: String { evidenceItems.joined(separator: ", ") }
    var sourceEvidenceSummary: String {
        if evidenceItems.isEmpty {
            return StudioStrings.notAvailableYet
        }
        if evidenceItems.count == 1 {
            return evidenceItems[0]
        }
        return StudioStrings.proposalEvidenceSummary(count: evidenceItems.count, firstItem: evidenceItems[0])
    }
    var diffContextSummary: String {
        let pieces = [area, tokenCandidate, componentCandidate, viewCandidate].filter { !$0.isEmpty }
        if pieces.isEmpty {
            return StudioStrings.notAvailableYet
        }
        return pieces.joined(separator: " · ")
    }
    fileprivate var status: StudioProposalArtifactStatus {
        let hasIntent = !requestedChange.isEmpty
        let hasTarget = !tokenCandidate.isEmpty || !componentCandidate.isEmpty || !viewCandidate.isEmpty || !structuredTargets.isEmpty
        let hasAcceptance = !acceptanceChecks.isEmpty

        if hasIntent, hasTarget, hasAcceptance {
            return .ready
        }
        if hasIntent, hasTarget {
            return .refine
        }
        return .draft
    }
    fileprivate var scopeConfidence: StudioProposalScopeConfidence {
        guard !scope.isEmpty else {
            return .low
        }
        if !evidenceItems.isEmpty, !coverage.isEmpty {
            return .high
        }
        if !requestedChange.isEmpty || !structuredTargets.isEmpty {
            return .medium
        }
        return .low
    }
    fileprivate var validationStatus: StudioProposalArtifactValidationStatus {
        validationFindings.isEmpty ? .healthy : .needsAttention
    }
    fileprivate var applyPreviewReadiness: StudioProposalApplyPreviewReadiness {
        if scope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || evidenceItems.isEmpty {
            return .blocked
        }
        if scopeConfidence == .low || !hasStructuredTargets || acceptanceChecks.isEmpty {
            return .review
        }
        return .ready
    }
    var hasStructuredTargets: Bool {
        !tokenCandidate.isEmpty || !componentCandidate.isEmpty || !viewCandidate.isEmpty || !structuredTargets.isEmpty
    }
    var validationFindings: [String] {
        var findings: [String] = []
        if scope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            findings.append(StudioStrings.proposalValidationMissingScope)
        }
        if evidenceItems.isEmpty {
            findings.append(StudioStrings.proposalValidationMissingEvidence)
        }
        if acceptanceChecks.isEmpty {
            findings.append(StudioStrings.proposalValidationMissingAcceptance)
        }
        if !hasStructuredTargets {
            findings.append(StudioStrings.proposalValidationMissingTargets)
        }
        if scopeConfidence == .low {
            findings.append(StudioStrings.proposalValidationWeakScopeConfidence)
        }
        return findings
    }
    var applyPreviewImpactSummary: String {
        switch applyPreviewReadiness {
        case .ready:
            return StudioStrings.proposalApplyPreviewImpactReady
        case .review:
            return StudioStrings.proposalApplyPreviewImpactReview
        case .blocked:
            return StudioStrings.proposalApplyPreviewImpactBlocked
        }
    }
    var applyPreviewTouchSummary: String {
        switch scopeKind {
        case "component":
            return StudioStrings.proposalApplyPreviewWouldTouchComponent
        case "view":
            return StudioStrings.proposalApplyPreviewWouldTouchView
        default:
            return StudioStrings.proposalApplyPreviewWouldTouchUnknown
        }
    }
    var applyPreviewNextStep: String {
        switch applyPreviewReadiness {
        case .ready:
            return StudioStrings.proposalApplyPreviewNextStepReady
        case .review:
            return StudioStrings.proposalApplyPreviewNextStepReview
        case .blocked:
            return StudioStrings.proposalApplyPreviewNextStepBlocked
        }
    }
    var applyPreviewChecklist: [String] {
        [
            StudioStrings.proposalApplyPreviewCheckEvidence,
            StudioStrings.proposalApplyPreviewCheckTargets,
            StudioStrings.proposalApplyPreviewCheckAcceptance
        ]
    }
    var applyPreviewConfiguration: StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration.viewDefault(presentation: previewPresentationHint)
        configuration.coverageLevel = previewCoverageLevel
        if evidenceItems.count > 1 {
            configuration.stackContext = .branched
        } else if scopeKind == "component" {
            configuration.stackContext = .single
        }
        return configuration
    }

    fileprivate func matches(selection: StudioMacReviewFocusSelection) -> Bool {
        switch selection {
        case let .component(component):
            return matchesComponent(id: component.id)
        case let .view(view):
            return matchesView(id: view.id)
        }
    }

    func matchesComponent(id: String) -> Bool {
        scope == "component:\(id)"
    }

    func matchesView(id: String) -> Bool {
        scope == "view:\(id)"
    }

    var scopeKind: String {
        if scope.hasPrefix("component:") {
            return "component"
        }
        if scope.hasPrefix("view:") {
            return "view"
        }
        return "unknown"
    }

    func matchesRelatedScope(_ preferredScope: String?) -> Bool {
        guard let preferredScope, !preferredScope.isEmpty else {
            return true
        }
        if scope == preferredScope {
            return true
        }
        return scopeKind == StudioChangeProposalArtifact.scopeKind(for: preferredScope)
    }

    func referencesEvidence(path: String?) -> Bool {
        guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        let normalizedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = URL(fileURLWithPath: normalizedPath).lastPathComponent

        return evidenceItems.contains { item in
            item == normalizedPath || item == fileName || item.contains(normalizedPath) || item.contains(fileName)
        }
    }

    static func scopeKind(for scope: String) -> String {
        if scope.hasPrefix("component:") {
            return "component"
        }
        if scope.hasPrefix("view:") {
            return "view"
        }
        return "unknown"
    }

    var scopeTargetID: String? {
        if scope.hasPrefix("component:") {
            return String(scope.dropFirst("component:".count))
        }
        if scope.hasPrefix("view:") {
            return String(scope.dropFirst("view:".count))
        }
        return nil
    }

    private var previewPresentationHint: String {
        [area, requestedChange, why, structuredTargets]
            .joined(separator: " ")
            .lowercased()
    }

    private var previewCoverageLevel: StudioPreviewCoverageLevel {
        StudioPreviewCoverageLevel.allCases.first(where: { $0.rawValue == coverage }) ?? .fallbackNeeded
    }

    static func loadResult(from repositoryRootURL: URL) -> StudioChangeProposalArtifactLoadResult {
        let directoryURL = repositoryRootURL.appendingPathComponent("docs/change-proposals", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) else {
            return StudioChangeProposalArtifactLoadResult(
                artifacts: [],
                issue: .missingDirectory(directoryURL)
            )
        }
        guard isDirectory.boolValue else {
            return StudioChangeProposalArtifactLoadResult(
                artifacts: [],
                issue: .unreadableDirectory(directoryURL, reason: StudioStrings.proposalArtifactsIssueDirectoryNotFolder)
            )
        }

        let fileURLs: [URL]
        do {
            fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return StudioChangeProposalArtifactLoadResult(
                artifacts: [],
                issue: .unreadableDirectory(directoryURL, reason: error.localizedDescription)
            )
        }

        var firstIssue: StudioProposalArtifactLoadIssue?
        let artifacts = fileURLs
            .filter { $0.pathExtension == "md" }
            .compactMap { fileURL -> StudioChangeProposalArtifact? in
                do {
                    return try parse(url: fileURL)
                } catch let parseIssue as StudioProposalArtifactLoadIssue {
                    firstIssue = firstIssue ?? parseIssue
                    return nil
                } catch {
                    firstIssue = firstIssue ?? .unreadableArtifact(fileURL, reason: error.localizedDescription)
                    return nil
                }
            }
            .sorted { $0.updatedAt > $1.updatedAt }

        return StudioChangeProposalArtifactLoadResult(artifacts: artifacts, issue: firstIssue)
    }

    private static func parse(url: URL) throws -> StudioChangeProposalArtifact {
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw StudioProposalArtifactLoadIssue.unreadableArtifact(url, reason: error.localizedDescription)
        }

        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        let updatedAt = resourceValues?.contentModificationDate ?? .distantPast

        return StudioChangeProposalArtifact(
            url: url,
            scope: lineValue(in: content, prefix: "- Surface: `", suffix: "`"),
            evidenceItems: codeSpanValues(in: content, linePrefix: "- Evidence: "),
            coverage: lineValue(in: content, prefix: "- Coverage: `", suffix: "`"),
            area: lineValue(in: content, prefix: "- Area: `", suffix: "`"),
            requestedChange: lineValue(in: content, prefix: "- Intent: "),
            why: lineValue(in: content, prefix: "- Why: "),
            tokenCandidate: lineValue(in: content, prefix: "- Token candidate: `", suffix: "`"),
            componentCandidate: lineValue(in: content, prefix: "- Component candidate: `", suffix: "`"),
            viewCandidate: lineValue(in: content, prefix: "- View candidate: `", suffix: "`"),
            structuredTargets: sectionLines(in: content, heading: "## Structured Targets").joined(separator: " · "),
            acceptanceChecks: sectionLines(in: content, heading: "## Acceptance Notes"),
            updatedAt: updatedAt
        )
    }

    private static func lineValue(in content: String, prefix: String, suffix: String = "") -> String {
        guard let line = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix(prefix) }) else {
            return ""
        }
        let trimmed = String(line.dropFirst(prefix.count))
        guard !suffix.isEmpty, let suffixRange = trimmed.range(of: suffix) else {
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(trimmed[..<suffixRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func sectionLines(in content: String, heading: String) -> [String] {
        let lines = content.components(separatedBy: .newlines)
        guard let headingIndex = lines.firstIndex(of: heading) else {
            return []
        }

        var values: [String] = []
        var index = headingIndex + 1
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("## ") {
                break
            }
            if line.hasPrefix("- ") {
                values.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines))
            }
            index += 1
        }
        return values
    }

    private static func codeSpanValues(in content: String, linePrefix: String) -> [String] {
        guard let line = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix(linePrefix) }) else {
            return []
        }
        let remainder = String(line.dropFirst(linePrefix.count))
        let segments = remainder.components(separatedBy: "`")
        return segments.enumerated()
            .compactMap { index, segment in
                index.isMultiple(of: 2) ? nil : segment.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }
}

struct StudioChangeProposalArtifactLoadResult {
    let artifacts: [StudioChangeProposalArtifact]
    let issue: StudioProposalArtifactLoadIssue?
}

enum StudioProposalArtifactLoadIssue: Error, Equatable {
    case missingDirectory(URL)
    case unreadableDirectory(URL, reason: String)
    case unreadableArtifact(URL, reason: String)

    var title: String {
        switch self {
        case .missingDirectory:
            return StudioStrings.proposalArtifactsIssueMissingDirectoryTitle
        case .unreadableDirectory:
            return StudioStrings.proposalArtifactsIssueUnreadableDirectoryTitle
        case .unreadableArtifact:
            return StudioStrings.proposalArtifactsIssueUnreadableArtifactTitle
        }
    }

    var detail: String {
        switch self {
        case let .missingDirectory(directoryURL):
            return StudioStrings.proposalArtifactsIssueMissingDirectoryDetail(directoryURL.path)
        case let .unreadableDirectory(directoryURL, reason):
            return StudioStrings.proposalArtifactsIssueUnreadableDirectoryDetail(directoryURL.path, reason)
        case let .unreadableArtifact(fileURL, reason):
            return StudioStrings.proposalArtifactsIssueUnreadableArtifactDetail(fileURL.lastPathComponent, reason)
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .missingDirectory:
            return StudioStrings.proposalArtifactsIssueMissingDirectoryRecovery
        case .unreadableDirectory:
            return StudioStrings.proposalArtifactsIssueUnreadableDirectoryRecovery
        case .unreadableArtifact:
            return StudioStrings.proposalArtifactsIssueUnreadableArtifactRecovery
        }
    }
}

private enum StudioProposalArtifactStatus {
    case ready
    case refine
    case draft

    var label: String {
        switch self {
        case .ready:
            return StudioStrings.proposalStatusReady
        case .refine:
            return StudioStrings.proposalStatusRefine
        case .draft:
            return StudioStrings.proposalStatusDraft
        }
    }

    var color: Color {
        switch self {
        case .ready:
            return .green
        case .refine:
            return .orange
        case .draft:
            return .secondary
        }
    }
}

private enum StudioProposalScopeConfidence {
    case high
    case medium
    case low

    var label: String {
        switch self {
        case .high:
            return StudioStrings.proposalScopeConfidenceHigh
        case .medium:
            return StudioStrings.proposalScopeConfidenceMedium
        case .low:
            return StudioStrings.proposalScopeConfidenceLow
        }
    }

    var color: Color {
        switch self {
        case .high:
            return .green
        case .medium:
            return .orange
        case .low:
            return .secondary
        }
    }
}

private enum StudioProposalArtifactValidationStatus {
    case healthy
    case needsAttention

    var label: String {
        switch self {
        case .healthy:
            return StudioStrings.proposalValidationHealthy
        case .needsAttention:
            return StudioStrings.proposalValidationNeedsAttention
        }
    }

    var color: Color {
        switch self {
        case .healthy:
            return .green
        case .needsAttention:
            return .orange
        }
    }
}

private enum StudioProposalApplyPreviewReadiness {
    case ready
    case review
    case blocked

    var label: String {
        switch self {
        case .ready:
            return StudioStrings.proposalApplyPreviewReadinessReady
        case .review:
            return StudioStrings.proposalApplyPreviewReadinessReview
        case .blocked:
            return StudioStrings.proposalApplyPreviewReadinessBlocked
        }
    }

    var color: Color {
        switch self {
        case .ready:
            return .green
        case .review:
            return .orange
        case .blocked:
            return .red
        }
    }
}

private enum StudioProposalArtifactScopeFilter: CaseIterable, Identifiable {
    case matchingScope
    case relatedScope
    case allArtifacts

    var id: Self { self }

    var label: String {
        switch self {
        case .matchingScope:
            return StudioStrings.proposalFilterMatchingScope
        case .relatedScope:
            return StudioStrings.proposalFilterRelatedScope
        case .allArtifacts:
            return StudioStrings.proposalFilterAllArtifacts
        }
    }
}

private enum StudioProposalArtifactStatusFilter: CaseIterable, Identifiable {
    case all
    case ready
    case refine
    case draft

    var id: Self { self }

    var label: String {
        switch self {
        case .all:
            return StudioStrings.proposalFilterAnyStatus
        case .ready:
            return StudioStrings.proposalStatusReady
        case .refine:
            return StudioStrings.proposalStatusRefine
        case .draft:
            return StudioStrings.proposalStatusDraft
        }
    }
}

private enum StudioProposalArtifactCoverageFilter: CaseIterable, Identifiable {
    case all
    case exact
    case contractDriven
    case fallbackNeeded

    var id: Self { self }

    var label: String {
        switch self {
        case .all:
            return StudioStrings.proposalFilterAnyCoverage
        case .exact:
            return StudioStrings.exact
        case .contractDriven:
            return StudioStrings.contractDriven
        case .fallbackNeeded:
            return StudioStrings.fallbackNeeded
        }
    }
}

private enum StudioProposalArtifactSortOrder: CaseIterable, Identifiable {
    case newest
    case status
    case confidence

    var id: Self { self }

    var label: String {
        switch self {
        case .newest:
            return StudioStrings.proposalSortNewest
        case .status:
            return StudioStrings.proposalSortStatus
        case .confidence:
            return StudioStrings.proposalSortConfidence
        }
    }
}

struct StudioMacReviewPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var selectedItem: StudioMacReviewSelection?
    @State private var inspectorLayoutMode: StudioPreviewLayoutMode = .focus

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            let components = document.components.filter { nativeComponentTruthStatus(for: $0).needsAttention }
            let views = document.views.filter { nativeViewTruthStatus(for: $0).needsAttention }
            let coverage = nativePreviewCoverageSummary(for: document)

            if components.isEmpty && views.isEmpty {
                ContentUnavailableView(
                    StudioStrings.nothingNeedsReview,
                    systemImage: "checkmark.circle",
                    description: Text(StudioStrings.nothingNeedsReviewDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(StudioStrings.reviewQueueTitle)
                                    .font(.system(size: 28, weight: .bold))
                                Text(StudioStrings.reviewQueueSubtitle)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            HStack(alignment: .top, spacing: 16) {
                                HStack(spacing: 16) {
                                    StudioCountCard(title: StudioStrings.needsReview, value: "\(components.count + views.count)", caption: StudioStrings.totalTruthGapsCaption)
                                    StudioCountCard(title: StudioStrings.components, value: "\(components.count)", caption: StudioStrings.componentTruthGapsCaption)
                                    StudioCountCard(title: StudioStrings.views, value: "\(views.count)", caption: StudioStrings.viewTruthGapsCaption)
                                }

                                Spacer(minLength: 16)

                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        StudioPreviewCoveragePill(level: .exact, count: coverage.exact)
                                        StudioPreviewCoveragePill(level: .contractDriven, count: coverage.contractDriven)
                                        StudioPreviewCoveragePill(level: .fallbackNeeded, count: coverage.fallbackNeeded)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.inspectorFocus)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        StudioPreviewLayoutPicker(layoutMode: $inspectorLayoutMode)
                                            .frame(width: 180)
                                    }
                                }
                            }

                            if !components.isEmpty {
                                StudioInspectorSection(title: StudioStrings.components) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ForEach(components) { component in
                                            StudioNativeReviewCard(
                                                title: component.name,
                                                subtitle: [component.group, StudioStrings.viewsCount(getComponentUsageCount(component, in: document))].filter { !$0.isEmpty }.joined(separator: " · "),
                                                status: nativeComponentTruthStatus(for: component),
                                                coverageLevel: nativeComponentPreviewCoverage(for: component),
                                                reason: nativeComponentReviewReason(for: component),
                                                evidence: [
                                                    (StudioStrings.snapshot, component.snapshot == nil ? StudioStrings.missing : StudioStrings.present),
                                                    (StudioStrings.states, "\(component.statesCount)"),
                                                    (StudioStrings.source, component.sourcePath.isEmpty ? StudioStrings.missing : StudioStrings.present),
                                                ],
                                                actionTitle: StudioStrings.open + " " + StudioStrings.componentDetail,
                                                isSelected: selectedItem == .component(component.id)
                                            ) {
                                                selectedItem = .component(component.id)
                                                inspectComponent(component.id)
                                            }
                                            .onTapGesture {
                                                selectedItem = .component(component.id)
                                            }
                                        }
                                    }
                                }
                            }

                            if !views.isEmpty {
                                StudioInspectorSection(title: StudioStrings.views) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ForEach(views) { view in
                                            StudioNativeReviewCard(
                                                title: view.name,
                                                subtitle: [view.root ? StudioStrings.rootScreen : StudioStrings.navigationKindLabel(view.presentation), StudioStrings.linksCount(view.navigationCount)].joined(separator: " · "),
                                                status: nativeViewTruthStatus(for: view),
                                                coverageLevel: nativeViewPreviewCoverage(for: view),
                                                reason: nativeViewReviewReason(for: view),
                                                evidence: [
                                                    (StudioStrings.snapshot, view.snapshot == nil ? StudioStrings.missing : StudioStrings.present),
                                                    (StudioStrings.components, "\(view.componentsCount)"),
                                                    (StudioStrings.source, view.sourcePath.isEmpty ? StudioStrings.missing : StudioStrings.present),
                                                ],
                                                actionTitle: StudioStrings.open + " " + StudioStrings.viewDetail,
                                                isSelected: selectedItem == .view(view.id)
                                            ) {
                                                selectedItem = .view(view.id)
                                                inspectView(view.id)
                                            }
                                            .onTapGesture {
                                                selectedItem = .view(view.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }

                    Divider()
                        .opacity(0.35)

                    StudioMacReviewFocusInspector(
                        document: document,
                        selection: resolvedSelection(components: components, views: views),
                        inspectComponent: inspectComponent,
                        inspectView: inspectView
                    )
                    .frame(
                        minWidth: inspectorLayoutMode == .focus ? 400 : 340,
                        idealWidth: inspectorLayoutMode == .focus ? 460 : 380,
                        maxWidth: inspectorLayoutMode == .focus ? 520 : 420,
                        maxHeight: .infinity
                    )
                }
                .onAppear {
                    if selectedItem == nil {
                        selectedItem = components.first.map { .component($0.id) } ?? views.first.map { .view($0.id) }
                    }
                }
            }
        }
    }

    private func resolvedSelection(
        components: [StudioNativeDocument.ComponentItem],
        views: [StudioNativeDocument.ViewItem]
    ) -> StudioMacReviewFocusSelection? {
        let fallback = components.first.map { StudioMacReviewFocusSelection.component($0) }
            ?? views.first.map { StudioMacReviewFocusSelection.view($0) }

        guard let selectedItem else {
            return fallback
        }

        switch selectedItem {
        case let .component(id):
            return components.first(where: { $0.id == id }).map(StudioMacReviewFocusSelection.component) ?? fallback
        case let .view(id):
            return views.first(where: { $0.id == id }).map(StudioMacReviewFocusSelection.view) ?? fallback
        }
    }
}

private enum StudioMacReviewSelection: Equatable {
    case component(String)
    case view(String)
}

private enum StudioMacReviewFocusSelection {
    case component(StudioNativeDocument.ComponentItem)
    case view(StudioNativeDocument.ViewItem)
}

private struct StudioMacReviewFocusInspector: View {
    let document: StudioNativeDocument
    let selection: StudioMacReviewFocusSelection?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var exportStatusMessage: String?
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        Group {
            if let selection {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(StudioStrings.reviewFocus)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        switch selection {
                        case let .component(component):
                            Text(component.name)
                                .font(.system(size: 28, weight: .bold))
                            StudioPreviewContractPanel(configuration: componentConfiguration(for: component))
                            StudioInspectorSection(title: StudioStrings.whyStillNeedsReview) {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: StudioStrings.truthStatus, value: nativeComponentTruthStatus(for: component).label)
                                    StudioKeyValueRow(label: StudioStrings.gap, value: nativeComponentReviewReason(for: component))
                                    StudioKeyValueRow(label: StudioStrings.usage, value: StudioStrings.viewsCount(getComponentUsageCount(component, in: document)))
                                    StudioKeyValueRow(label: StudioStrings.source, value: component.sourcePath.isEmpty ? StudioStrings.notExportedYet : component.sourcePath)
                                }
                            }

                            StudioMacChangeProposalCard(
                                selection: .component(component),
                                document: document,
                                exportStatusMessage: $exportStatusMessage,
                                onProposalSaved: reloadProposals
                            )

                            StudioMacProposalArtifactSection(
                                artifacts: proposalArtifacts,
                                preferredScope: selectionID,
                                preferredEvidencePath: component.sourcePath,
                                loadIssue: proposalArtifactIssue,
                                reloadProposals: reloadProposals,
                                inspectComponent: inspectComponent,
                                inspectView: inspectView,
                                artifactLimit: 6,
                                selectedArtifactID: nil,
                                selectArtifact: nil
                            )

                            Button(StudioStrings.open + " " + StudioStrings.componentDetail) {
                                inspectComponent(component.id)
                            }
                            .buttonStyle(.borderedProminent)

                        case let .view(view):
                            Text(view.name)
                                .font(.system(size: 28, weight: .bold))
                            StudioPreviewContractPanel(configuration: viewConfiguration(for: view))
                            StudioInspectorSection(title: StudioStrings.whyStillNeedsReview) {
                                VStack(alignment: .leading, spacing: 10) {
                                    StudioKeyValueRow(label: StudioStrings.truthStatus, value: nativeViewTruthStatus(for: view).label)
                                    StudioKeyValueRow(label: StudioStrings.gap, value: nativeViewReviewReason(for: view))
                                    StudioKeyValueRow(label: StudioStrings.navigation, value: StudioStrings.linksCount(view.navigationCount))
                                    StudioKeyValueRow(label: StudioStrings.source, value: view.sourcePath.isEmpty ? StudioStrings.notExportedYet : view.sourcePath)
                                }
                            }

                            StudioMacChangeProposalCard(
                                selection: .view(view),
                                document: document,
                                exportStatusMessage: $exportStatusMessage,
                                onProposalSaved: reloadProposals
                            )

                            StudioMacProposalArtifactSection(
                                artifacts: proposalArtifacts,
                                preferredScope: selectionID,
                                preferredEvidencePath: view.sourcePath,
                                loadIssue: proposalArtifactIssue,
                                reloadProposals: reloadProposals,
                                inspectComponent: inspectComponent,
                                inspectView: inspectView,
                                artifactLimit: 6,
                                selectedArtifactID: nil,
                                selectArtifact: nil
                            )

                            Button(StudioStrings.open + " " + StudioStrings.viewDetail) {
                                inspectView(view.id)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    StudioStrings.chooseReviewItem,
                    systemImage: "checklist",
                    description: Text(StudioStrings.chooseReviewItemDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onAppear(perform: reloadProposals)
        .onChange(of: selectionID) { _, _ in
            reloadProposals()
        }
    }

    private var selectionID: String {
        guard let selection else { return "none" }
        switch selection {
        case let .component(component):
            return "component:\(component.id)"
        case let .view(view):
            return "view:\(view.id)"
        }
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

    private func componentConfiguration(for component: StudioNativeDocument.ComponentItem) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration()
        configuration.coverageLevel = nativeComponentPreviewCoverage(for: component)
        configuration.navigationChrome = .none
        configuration.navigationDepth = .root
        configuration.stackContext = getComponentUsageCount(component, in: document) > 0 ? .stacked : .single
        return configuration
    }

    private func viewConfiguration(for view: StudioNativeDocument.ViewItem) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration.viewDefault(presentation: view.presentation)
        configuration.coverageLevel = nativeViewPreviewCoverage(for: view)
        configuration.navigationDepth = view.root ? .root : (view.navigationCount > 1 ? .deep : .detail)
        configuration.stackContext = view.navigationCount > 1 || view.entryPoints.count > 1 ? .branched : (view.root ? .single : .stacked)
        return configuration
    }
}

struct StudioMacNavigationPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    @Binding var selectedViewID: String?
    let inspectView: (String) -> Void
    @State private var inspectorLayoutMode: StudioPreviewLayoutMode = .focus

    var body: some View {
        StudioNativePageContainer(document: document, nativeErrorMessage: nativeErrorMessage) { document in
            let graph = makeNativeNavigationGraph(document: document)
            let coverage = nativePreviewCoverageSummary(for: document)

            HStack(spacing: 0) {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StudioStrings.navigationMap)
                                    .font(.system(size: 26, weight: .bold))
                                Text(StudioStrings.navigationSubtitle)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 24)

                            HStack(spacing: 16) {
                                StudioCountCard(title: StudioStrings.viewCountLabel, value: "\(document.views.count)", caption: StudioStrings.graphNodesCaption)
                                StudioCountCard(title: StudioStrings.edgeCountLabel, value: "\(graph.edgeCount)", caption: StudioStrings.graphEdgesCaption)
                                StudioCountCard(title: StudioStrings.rootLabel, value: graph.rootViewName, caption: StudioStrings.graphRootCaption)
                            }
                            .frame(maxWidth: 680)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    StudioPreviewCoveragePill(level: .exact, count: coverage.exact)
                                    StudioPreviewCoveragePill(level: .contractDriven, count: coverage.contractDriven)
                                    StudioPreviewCoveragePill(level: .fallbackNeeded, count: coverage.fallbackNeeded)
                                }

                                Text(StudioStrings.inspectorFocus)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                StudioPreviewLayoutPicker(layoutMode: $inspectorLayoutMode)
                                    .frame(width: 180)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 22) {
                                ForEach(graph.levels, id: \.depth) { level in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(StudioStrings.depthValue(level.depth))
                                            .font(.headline)
                                        Text(StudioStrings.viewCountSummary(level.views.count))
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
                    layoutMode: inspectorLayoutMode,
                    inspectView: inspectView
                )
                .frame(
                    minWidth: inspectorLayoutMode == .focus ? 400 : 350,
                    idealWidth: inspectorLayoutMode == .focus ? 470 : 390,
                    maxWidth: inspectorLayoutMode == .focus ? 540 : 430,
                    maxHeight: .infinity
                )
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
    let layoutMode: StudioPreviewLayoutMode
    let inspectView: (String) -> Void
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        Group {
            if let selectedView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(StudioStrings.flowDetail)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedView.name)
                                .font(.system(size: 28, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Text(StudioStrings.navigationKindLabel(selectedView.presentation))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary.opacity(0.55), in: Capsule())
                                    .foregroundStyle(.secondary)
                                if selectedView.id == graph.rootViewID {
                                    Text(StudioStrings.root)
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

                        StudioPreviewContractPanel(configuration: previewConfiguration(for: selectedView))

                        StudioInspectorSection(title: StudioStrings.route) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioKeyValueRow(label: StudioStrings.coverageStatus, value: StudioStrings.previewCoverageLabel(previewConfiguration(for: selectedView).coverageLevel))
                                StudioKeyValueRow(label: StudioStrings.depth, value: "\(graph.depths[selectedView.id] ?? 0)")
                                StudioKeyValueRow(label: StudioStrings.incoming, value: "\(graph.incoming[selectedView.id]?.count ?? 0)")
                                StudioKeyValueRow(label: StudioStrings.outgoing, value: "\(selectedView.navigatesTo.count)")
                                if !graph.pathToRoot(selectedView.id).isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(StudioStrings.pathFromRoot)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        FlexiblePillStack(items: graph.pathToRoot(selectedView.id).map { graph.viewByID[$0]?.name ?? $0 })
                                    }
                                }
                            }
                        }

                        if !selectedView.navigatesTo.isEmpty {
                            StudioInspectorSection(title: StudioStrings.transitionProfile) {
                                StudioInspectorSummaryGrid(items: transitionProfileItems(for: selectedView))
                            }
                        }

                        StudioInspectorSection(title: StudioStrings.triggerAudit) {
                            StudioInspectorSummaryGrid(items: triggerAuditItems(for: selectedView))
                        }

                        StudioInspectorSection(title: StudioStrings.proposalLinkageTitle) {
                            StudioInspectorSummaryGrid(items: proposalLinkageItems(for: selectedView))
                        }

                        if let incoming = graph.incoming[selectedView.id], !incoming.isEmpty {
                            StudioInspectorSection(title: StudioStrings.howUsersGetHere) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(incoming) { edge in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(graph.viewByID[edge.sourceID]?.name ?? edge.sourceID)
                                                .font(.subheadline.weight(.semibold))
                                            Text(StudioStrings.navigationEdgeLabel(type: edge.type, trigger: edge.trigger))
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
                            StudioInspectorSection(title: StudioStrings.whatUsersCanDoNext) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(selectedView.navigatesTo) { edge in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(graph.viewByID[edge.targetID]?.name ?? edge.targetID)
                                                .font(.subheadline.weight(.semibold))
                                            Text(StudioStrings.navigationEdgeLabel(type: edge.type, trigger: edge.trigger))
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
                            StudioInspectorSection(title: StudioStrings.interactionModel) {
                                VStack(alignment: .leading, spacing: 10) {
                                    if !selectedView.entryPoints.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(StudioStrings.entryPoints)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.entryPoints.map(humanizedFlowLabel))
                                        }
                                    }
                                    if !selectedView.primaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(StudioStrings.primaryActions)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.primaryActions)
                                        }
                                    }
                                    if !selectedView.secondaryActions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(StudioStrings.secondaryActions)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            FlexiblePillStack(items: selectedView.secondaryActions)
                                        }
                                    }
                                }
                            }
                        }

                        Button(StudioStrings.open + " " + StudioStrings.viewDetail) {
                            inspectView(selectedView.id)
                        }
                        .buttonStyle(.borderedProminent)

                        StudioMacProposalArtifactSection(
                            artifacts: proposalArtifacts,
                            preferredScope: "view:\(selectedView.id)",
                            preferredEvidencePath: selectedView.sourcePath,
                            loadIssue: proposalArtifactIssue,
                            reloadProposals: reloadProposals,
                            inspectComponent: nil,
                            inspectView: inspectView,
                            artifactLimit: 6,
                            selectedArtifactID: nil,
                            selectArtifact: nil
                        )
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    StudioStrings.selectRouteNode,
                    systemImage: "arrow.triangle.branch",
                    description: Text(StudioStrings.selectRouteNodeDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .onAppear(perform: reloadProposals)
        .onChange(of: selectedView?.id) { _, _ in
            reloadProposals()
        }
    }

    private func humanizedFlowLabel(_ value: String) -> String {
        StudioStrings.navigationKindLabel(value)
    }

    private func previewConfiguration(for view: StudioNativeDocument.ViewItem) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration.viewDefault(presentation: view.presentation)
        configuration.coverageLevel = nativeViewPreviewCoverage(for: view)
        configuration.navigationDepth = (graph.depths[view.id] ?? 0) > 1 ? .deep : (view.id == graph.rootViewID ? .root : .detail)
        configuration.navigationChrome = view.root ? .both : configuration.navigationChrome
        configuration.stackContext = selectedViewStackContext(for: view)
        return configuration
    }

    private func transitionProfileItems(for view: StudioNativeDocument.ViewItem) -> [StudioInspectorSummaryItem] {
        let pushes = view.navigatesTo.filter { $0.type == "push" }.count
        let sheets = view.navigatesTo.filter { $0.type == "sheet" }.count
        let replaces = view.navigatesTo.filter { $0.type == "replace" }.count
        let others = view.navigatesTo.count - pushes - sheets - replaces

        return [
            StudioInspectorSummaryItem(label: StudioStrings.push, value: "\(pushes)", tone: pushes > 0 ? .accent : .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.sheet, value: "\(sheets)", tone: sheets > 0 ? .warning : .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.replace, value: "\(replaces)", tone: replaces > 0 ? .success : .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.other, value: "\(max(others, 0))", tone: others > 0 ? .warning : .neutral)
        ]
    }

    private func triggerAuditItems(for view: StudioNativeDocument.ViewItem) -> [StudioInspectorSummaryItem] {
        let nonEmptyTriggers = view.navigatesTo.compactMap {
            $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.trigger
        }
        let modalTriggers = view.navigatesTo.filter { $0.type == "sheet" || $0.type == "replace" }.count
        let uniqueTriggers = Set(nonEmptyTriggers)

        return [
            StudioInspectorSummaryItem(label: StudioStrings.trigger, value: "\(uniqueTriggers.count)", tone: uniqueTriggers.isEmpty ? .neutral : .accent),
            StudioInspectorSummaryItem(label: StudioStrings.presentation, value: "\(modalTriggers)", tone: modalTriggers > 0 ? .warning : .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.entryPoints, value: "\(view.entryPoints.count)", tone: view.entryPoints.isEmpty ? .neutral : .success),
            StudioInspectorSummaryItem(label: StudioStrings.actions, value: "\(view.primaryActions.count + view.secondaryActions.count)", tone: (view.primaryActions.count + view.secondaryActions.count) > 0 ? .success : .neutral)
        ]
    }

    private func proposalLinkageItems(for view: StudioNativeDocument.ViewItem) -> [StudioInspectorSummaryItem] {
        let matching = proposalArtifacts.filter { $0.scope == "view:\(view.id)" }
        let ready = matching.filter { $0.status == .ready }
        let evidenceMatched = matching.filter { $0.referencesEvidence(path: view.sourcePath) }

        return [
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalLinkageMatching,
                value: StudioStrings.resultsCount(matching.count),
                tone: matching.isEmpty ? .warning : .accent
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalLinkageReady,
                value: StudioStrings.resultsCount(ready.count),
                tone: ready.isEmpty ? .neutral : .success
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalLinkageEvidence,
                value: StudioStrings.resultsCount(evidenceMatched.count),
                tone: evidenceMatched.isEmpty ? .warning : .success
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalScopeConfidence,
                value: matching.first?.scopeConfidence.label ?? StudioStrings.notAvailableYet,
                tone: matching.first == nil ? .neutral : .accent
            )
        ]
    }

    private func selectedViewStackContext(for view: StudioNativeDocument.ViewItem) -> StudioPreviewStackContext {
        if view.navigatesTo.count > 1 || (graph.incoming[view.id]?.count ?? 0) > 1 {
            return .branched
        }
        if view.id == graph.rootViewID {
            return .single
        }
        return .stacked
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

private struct StudioMacChangeProposalCard: View {
    let selection: StudioMacReviewFocusSelection
    let document: StudioNativeDocument
    @Binding var exportStatusMessage: String?
    let onProposalSaved: () -> Void

    var body: some View {
        StudioInspectorSection(title: StudioStrings.changeProposalTitle) {
            VStack(alignment: .leading, spacing: 12) {
                Text(StudioStrings.changeProposalDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                StudioKeyValueRow(label: StudioStrings.proposalScope, value: scopeLabel)
                StudioKeyValueRow(label: StudioStrings.proposalArea, value: proposalArea)
                StudioKeyValueRow(label: StudioStrings.requestedChange, value: requestedChange)
                StudioKeyValueRow(label: StudioStrings.proposalWhy, value: proposalWhy)
                StudioKeyValueRow(label: StudioStrings.structuredTargets, value: structuredTargets)
                StudioKeyValueRow(label: StudioStrings.acceptanceNotes, value: acceptanceNotes)

                Button(StudioStrings.exportChangeProposal) {
                    exportProposal()
                }
                .buttonStyle(.bordered)

                Button(StudioStrings.saveProposalToRepo) {
                    saveProposalToRepository()
                }
                .buttonStyle(.borderedProminent)

                if let exportStatusMessage {
                    Text(exportStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var scopeLabel: String {
        switch selection {
        case let .component(component):
            return "component:\(component.id)"
        case let .view(view):
            return "view:\(view.id)"
        }
    }

    private var requestedChange: String {
        switch selection {
        case let .component(component):
            return StudioStrings.proposalIntentComponent(component.name)
        case let .view(view):
            return StudioStrings.proposalIntentView(view.name)
        }
    }

    private var structuredTargets: String {
        switch selection {
        case let .component(component):
            return [component.group, component.sourcePath.isEmpty ? nil : component.sourcePath].compactMap { $0 }.joined(separator: " · ")
        case let .view(view):
            return [view.presentation, view.sourcePath.isEmpty ? nil : view.sourcePath].compactMap { $0 }.joined(separator: " · ")
        }
    }

    private var proposalArea: String {
        switch selection {
        case let .component(component):
            return component.name
        case let .view(view):
            return view.name
        }
    }

    private var proposalWhy: String {
        switch selection {
        case let .component(component):
            return nativeComponentReviewReason(for: component)
        case let .view(view):
            return nativeViewReviewReason(for: view)
        }
    }

    private var tokenCandidate: String? {
        switch selection {
        case .component:
            return nil
        case let .view(view):
            return view.designTokenCategories.first
        }
    }

    private var componentCandidate: String? {
        switch selection {
        case let .component(component):
            return component.id
        case let .view(view):
            return view.components.first
        }
    }

    private var viewCandidate: String? {
        switch selection {
        case .component:
            return nil
        case let .view(view):
            return view.id
        }
    }

    private var acceptanceChecklist: [String] {
        switch selection {
        case let .component(component):
            return [
                StudioStrings.proposalAcceptanceComponent(StudioStrings.previewCoverageLabel(nativeComponentPreviewCoverage(for: component))),
                StudioStrings.proposalMarkdownRecheckNote
            ]
        case let .view(view):
            return [
                StudioStrings.proposalAcceptanceView(view.presentation),
                StudioStrings.proposalNavigationChecklist(
                    StudioStrings.navigationKindLabel(view.presentation),
                    StudioStrings.previewStackContextLabel(view.navigationCount > 1 || view.entryPoints.count > 1 ? .branched : (view.root ? .single : .stacked))
                )
            ]
        }
    }

    private var acceptanceNotes: String {
        switch selection {
        case let .component(component):
            return StudioStrings.proposalAcceptanceComponent(StudioStrings.previewCoverageLabel(nativeComponentPreviewCoverage(for: component)))
        case let .view(view):
            return StudioStrings.proposalAcceptanceView(view.presentation)
        }
    }

    private func exportProposal() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultFileName
        panel.title = StudioStrings.exportChangeProposal
        panel.message = StudioStrings.changeProposalDescription

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try proposalMarkdown.write(to: url, atomically: true, encoding: .utf8)
            exportStatusMessage = StudioStrings.proposalExportedFile(url.lastPathComponent)
        } catch {
            exportStatusMessage = error.localizedDescription
        }
    }

    private func saveProposalToRepository() {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let directoryURL = rootURL.appendingPathComponent("docs/change-proposals", isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent(defaultFileName)

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try proposalMarkdown.write(to: fileURL, atomically: true, encoding: .utf8)
            exportStatusMessage = StudioStrings.repoProposalSavedFile(fileURL.lastPathComponent)
            onProposalSaved()
        } catch {
            exportStatusMessage = StudioStrings.repoProposalFailedReason(error.localizedDescription)
        }
    }

    private var defaultFileName: String {
        switch selection {
        case let .component(component):
            return "change-proposal-\(component.id).md"
        case let .view(view):
            return "change-proposal-\(view.id).md"
        }
    }

    private var proposalMarkdown: String {
        let coverage: String
        let sourcePath: String
        switch selection {
        case let .component(component):
            coverage = nativeComponentPreviewCoverage(for: component).rawValue
            sourcePath = component.sourcePath
        case let .view(view):
            coverage = nativeViewPreviewCoverage(for: view).rawValue
            sourcePath = view.sourcePath
        }

        return """
        # \(StudioStrings.proposalMarkdownTitle)

        ## \(StudioStrings.proposalMarkdownScopeHeading)
        - Surface: `\(scopeLabel)`
        - Evidence: `\(sourcePath.isEmpty ? StudioStrings.notExportedYet : sourcePath)`, `design.json`
        - Coverage: `\(coverage)`

        ## \(StudioStrings.proposalMarkdownRequestedHeading)
        - Area: `\(proposalArea)`
        - Intent: \(requestedChange)
        - Why: \(proposalWhy)

        ## \(StudioStrings.proposalMarkdownStructuredTargetsHeading)
        - Token candidate: `\(tokenCandidate ?? StudioStrings.notAvailableYet)`
        - Component candidate: `\(componentCandidate ?? StudioStrings.notAvailableYet)`
        - View candidate: `\(viewCandidate ?? StudioStrings.notAvailableYet)`
        - Targets: \(structuredTargets.isEmpty ? StudioStrings.addPreciseTargetAfterInspection : structuredTargets)

        ## \(StudioStrings.proposalMarkdownAcceptanceHeading)
        \(acceptanceChecklist.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
}

struct StudioMacProposalArtifactSection: View {
    let artifacts: [StudioChangeProposalArtifact]
    let preferredScope: String?
    let preferredEvidencePath: String?
    let loadIssue: StudioProposalArtifactLoadIssue?
    let reloadProposals: () -> Void
    let inspectComponent: ((String) -> Void)?
    let inspectView: ((String) -> Void)?
    let artifactLimit: Int?
    let selectedArtifactID: String?
    let selectArtifact: ((StudioChangeProposalArtifact) -> Void)?
    @State private var scopeFilter: StudioProposalArtifactScopeFilter = .matchingScope
    @State private var statusFilter: StudioProposalArtifactStatusFilter = .all
    @State private var coverageFilter: StudioProposalArtifactCoverageFilter = .all
    @State private var sortOrder: StudioProposalArtifactSortOrder = .newest

    var body: some View {
        StudioInspectorSection(title: StudioStrings.proposalArtifactsTitle) {
            artifactSectionContent
        }
    }

    private var artifactSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(StudioStrings.proposalArtifactsDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                Button(StudioStrings.refreshProposals, action: reloadProposals)
                    .buttonStyle(.bordered)
            }

            proposalControls

            if !filteredArtifacts.isEmpty {
                Text(StudioStrings.resultsCount(filteredArtifacts.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if filteredArtifacts.isEmpty {
                Text(emptyStateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                artifactList
            }

            if let loadIssue {
                StudioMacProposalArtifactRecoveryCard(issue: loadIssue)
            }
        }
    }

    private var artifactList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(visibleArtifacts) { artifact in
                artifactCard(artifact)
            }
        }
    }

    private var filteredArtifacts: [StudioChangeProposalArtifact] {
        let scoped = artifacts.filter { artifact in
            switch scopeFilter {
            case .matchingScope:
                return preferredScope == nil || artifact.scope == preferredScope
            case .relatedScope:
                return artifact.matchesRelatedScope(preferredScope)
            case .allArtifacts:
                return true
            }
        }

        let statusScoped = scoped.filter { artifact in
            switch statusFilter {
            case .all:
                return true
            case .ready:
                return artifact.status == .ready
            case .refine:
                return artifact.status == .refine
            case .draft:
                return artifact.status == .draft
            }
        }

        let coverageScoped = statusScoped.filter { artifact in
            switch coverageFilter {
            case .all:
                return true
            case .exact:
                return artifact.coverage == StudioPreviewCoverageLevel.exact.rawValue
            case .contractDriven:
                return artifact.coverage == StudioPreviewCoverageLevel.contractDriven.rawValue
            case .fallbackNeeded:
                return artifact.coverage == StudioPreviewCoverageLevel.fallbackNeeded.rawValue
            }
        }

        switch sortOrder {
        case .newest:
            return coverageScoped.sorted { $0.updatedAt > $1.updatedAt }
        case .status:
            return coverageScoped.sorted {
                statusRank(for: $0.status) == statusRank(for: $1.status)
                    ? $0.updatedAt > $1.updatedAt
                    : statusRank(for: $0.status) < statusRank(for: $1.status)
            }
        case .confidence:
            return coverageScoped.sorted {
                confidenceRank(for: $0.scopeConfidence) == confidenceRank(for: $1.scopeConfidence)
                    ? $0.updatedAt > $1.updatedAt
                    : confidenceRank(for: $0.scopeConfidence) < confidenceRank(for: $1.scopeConfidence)
            }
        }
    }

    private var visibleArtifacts: [StudioChangeProposalArtifact] {
        guard let artifactLimit else {
            return filteredArtifacts
        }
        return Array(filteredArtifacts.prefix(artifactLimit))
    }

    private var proposalControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Picker(StudioStrings.proposalFilterScopeLabel, selection: $scopeFilter) {
                    ForEach(StudioProposalArtifactScopeFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Picker(StudioStrings.proposalFilterStatusLabel, selection: $statusFilter) {
                    ForEach(StudioProposalArtifactStatusFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack(spacing: 12) {
                Picker(StudioStrings.proposalFilterCoverageLabel, selection: $coverageFilter) {
                    ForEach(StudioProposalArtifactCoverageFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Picker(StudioStrings.proposalSortLabel, selection: $sortOrder) {
                    ForEach(StudioProposalArtifactSortOrder.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var emptyStateMessage: String {
        if artifacts.isEmpty {
            return loadIssue == nil ? StudioStrings.noSavedProposals : StudioStrings.noMatchingProposals
        }
        return StudioStrings.noFilteredProposals
    }

    private func statusRank(for status: StudioProposalArtifactStatus) -> Int {
        switch status {
        case .ready:
            return 0
        case .refine:
            return 1
        case .draft:
            return 2
        }
    }

    private func confidenceRank(for confidence: StudioProposalScopeConfidence) -> Int {
        switch confidence {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }

    private func inspectAction(for artifact: StudioChangeProposalArtifact) -> ((String) -> Void)? {
        switch artifact.scopeKind {
        case "component":
            return inspectComponent
        case "view":
            return inspectView
        default:
            return nil
        }
    }

    @ViewBuilder
    private func artifactRow(_ artifact: StudioChangeProposalArtifact) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(artifact.title)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                if artifact.scope == preferredScope {
                    StudioProposalArtifactBadge(text: StudioStrings.proposalFilterMatchingScope, color: .accentColor)
                } else if artifact.matchesRelatedScope(preferredScope) {
                    StudioProposalArtifactBadge(text: StudioStrings.proposalFilterRelatedScope, color: .orange)
                }
                if isSelected(artifact) {
                    StudioProposalArtifactBadge(text: StudioStrings.proposalWorkspaceSelected, color: .accentColor)
                }
                StudioProposalArtifactBadge(text: artifact.applyPreviewReadiness.label, color: artifact.applyPreviewReadiness.color)
                StudioProposalArtifactBadge(text: artifact.validationStatus.label, color: artifact.validationStatus.color)
                StudioProposalArtifactBadge(text: artifact.status.label, color: artifact.status.color)
            }
        }

        StudioKeyValueRow(label: StudioStrings.proposalScope, value: artifact.scope)
        StudioKeyValueRow(label: StudioStrings.proposalStatus, value: artifact.status.label)
        StudioKeyValueRow(label: StudioStrings.proposalValidation, value: artifact.validationStatus.label)
        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewReadiness, value: artifact.applyPreviewReadiness.label)
        StudioKeyValueRow(label: StudioStrings.proposalScopeConfidence, value: artifact.scopeConfidence.label)
        StudioKeyValueRow(label: StudioStrings.proposalCoverage, value: artifact.coverage.isEmpty ? StudioStrings.notAvailableYet : artifact.coverage)
        StudioKeyValueRow(label: StudioStrings.proposalEvidence, value: artifact.sourceEvidenceSummary)
        if !artifact.area.isEmpty {
            StudioKeyValueRow(label: StudioStrings.proposalArea, value: artifact.area)
        }
        if !artifact.requestedChange.isEmpty {
            StudioKeyValueRow(label: StudioStrings.requestedChange, value: artifact.requestedChange)
        }
        if !artifact.why.isEmpty {
            StudioKeyValueRow(label: StudioStrings.proposalWhy, value: artifact.why)
        }
        StudioKeyValueRow(label: StudioStrings.proposalDiffContext, value: artifact.diffContextSummary)
        if !artifact.structuredTargets.isEmpty {
            StudioKeyValueRow(label: StudioStrings.structuredTargets, value: artifact.structuredTargets)
        }
        if !artifact.acceptanceChecks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(StudioStrings.acceptanceNotes)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(artifact.acceptanceChecks.prefix(3)), id: \.self) { note in
                    Text("• \(note)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        if !artifact.validationFindings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(StudioStrings.proposalValidation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(artifact.validationFindings, id: \.self) { finding in
                    Text("• \(finding)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        StudioKeyValueRow(label: StudioStrings.proposalUpdated, value: proposalDateFormatter.string(from: artifact.updatedAt))

        HStack(spacing: 10) {
            if let selectArtifact {
                if isSelected(artifact) {
                    Button(StudioStrings.proposalWorkspaceSelected) {
                        selectArtifact(artifact)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(StudioStrings.proposalWorkspaceChooseArtifact) {
                        selectArtifact(artifact)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button(StudioStrings.openProposal) {
                NSWorkspace.shared.open(artifact.url)
            }
            .buttonStyle(.bordered)

            Button(StudioStrings.revealProposal) {
                NSWorkspace.shared.activateFileViewerSelecting([artifact.url])
            }
            .buttonStyle(.bordered)

            if let inspectAction = inspectAction(for: artifact), let targetID = artifact.scopeTargetID {
                Button(StudioStrings.inspectProposalScope) {
                    inspectAction(targetID)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func isSelected(_ artifact: StudioChangeProposalArtifact) -> Bool {
        selectedArtifactID == artifact.id
    }

    @ViewBuilder
    private func artifactCard(_ artifact: StudioChangeProposalArtifact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            artifactRow(artifact)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected(artifact) ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected(artifact) ? Color.accentColor.opacity(0.35) : Color.secondary.opacity(0.18), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            selectArtifact?(artifact)
        }

        if artifact.id != visibleArtifacts.last?.id {
            Divider()
        }
    }

    private var proposalDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

private struct StudioMacProposalArtifactRecoveryCard: View {
    let issue: StudioProposalArtifactLoadIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(issue.title, systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            Text(issue.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StudioKeyValueRow(label: StudioStrings.recommendedNextStep, value: issue.recoverySuggestion)
        }
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.28), lineWidth: 1)
        )
    }
}

struct StudioMacProposalArtifactsPage: View {
    let document: StudioNativeDocument?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?
    @State private var selectedArtifactID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(StudioStrings.proposalWorkspaceTitle)
                        .font(.system(size: 26, weight: .bold))
                    Text(StudioStrings.proposalWorkspaceSubtitle)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 16) {
                    StudioCountCard(
                        title: StudioStrings.proposalWorkspaceAllArtifacts,
                        value: "\(proposalArtifacts.count)",
                        caption: StudioStrings.proposalArtifactsDescription
                    )
                    StudioCountCard(
                        title: StudioStrings.proposalWorkspaceReady,
                        value: "\(proposalArtifacts.filter { $0.status == .ready }.count)",
                        caption: StudioStrings.proposalStatusReady
                    )
                    StudioCountCard(
                        title: StudioStrings.proposalWorkspaceNeedsRefinement,
                        value: "\(proposalArtifacts.filter { $0.status != .ready }.count)",
                        caption: StudioStrings.proposalStatusRefine
                    )
                    StudioCountCard(
                        title: StudioStrings.proposalWorkspaceValidationSignal,
                        value: metadataHealthCount,
                        caption: metadataHealthCaption
                    )
                }

                if document != nil {
                    StudioInspectorSection(title: StudioStrings.proposalLinkageTitle) {
                        StudioInspectorSummaryGrid(items: [
                            StudioInspectorSummaryItem(
                                label: StudioStrings.components,
                                value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.scopeKind == "component" }.count),
                                tone: .accent
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.views,
                                value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.scopeKind == "view" }.count),
                                tone: .accent
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalLinkageEvidence,
                                value: StudioStrings.resultsCount(linkedEvidenceCount),
                                tone: linkedEvidenceCount == 0 ? .warning : .success
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalWorkspaceValidationSignal,
                                value: metadataHealthCount,
                                tone: metadataGapCount == 0 ? .success : .warning
                            )
                        ])
                    }
                }

                StudioInspectorSection(title: StudioStrings.proposalValidation) {
                    StudioInspectorSummaryGrid(items: [
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationHealthy,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.validationStatus == .healthy }.count),
                            tone: .success
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationNeedsAttention,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.validationStatus == .needsAttention }.count),
                            tone: metadataGapCount == 0 ? .neutral : .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationMissingScope,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter {
                                $0.validationFindings.contains(StudioStrings.proposalValidationMissingScope)
                            }.count),
                            tone: .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationMissingEvidence,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter {
                                $0.validationFindings.contains(StudioStrings.proposalValidationMissingEvidence)
                            }.count),
                            tone: .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationMissingAcceptance,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter {
                                $0.validationFindings.contains(StudioStrings.proposalValidationMissingAcceptance)
                            }.count),
                            tone: .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationMissingTargets,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter {
                                $0.validationFindings.contains(StudioStrings.proposalValidationMissingTargets)
                            }.count),
                            tone: .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalValidationWeakScopeConfidence,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter {
                                $0.validationFindings.contains(StudioStrings.proposalValidationWeakScopeConfidence)
                            }.count),
                            tone: .warning
                        )
                    ])
                }

                HStack(alignment: .top, spacing: 16) {
                    StudioMacProposalArtifactSection(
                        artifacts: proposalArtifacts,
                        preferredScope: nil,
                        preferredEvidencePath: nil,
                        loadIssue: proposalArtifactIssue,
                        reloadProposals: reloadProposals,
                        inspectComponent: inspectComponent,
                        inspectView: inspectView,
                        artifactLimit: nil,
                        selectedArtifactID: selectedArtifactID,
                        selectArtifact: { artifact in
                            selectedArtifactID = artifact.id
                        }
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    StudioMacProposalArtifactDetailPanel(
                        artifact: selectedArtifact,
                        document: document,
                        inspectComponent: inspectComponent,
                        inspectView: inspectView
                    )
                    .frame(width: 360, alignment: .topLeading)
                }
            }
            .padding(24)
        }
        .background(.thinMaterial)
        .onAppear(perform: reloadProposals)
    }

    private var metadataGapCount: Int {
        proposalArtifacts.filter { artifact in
            artifact.validationStatus == .needsAttention
        }.count
    }

    private var selectedArtifact: StudioChangeProposalArtifact? {
        if let selectedArtifactID,
           let artifact = proposalArtifacts.first(where: { $0.id == selectedArtifactID }) {
            return artifact
        }
        return proposalArtifacts.first
    }

    private var metadataHealthCount: String {
        StudioStrings.resultsCount(max(proposalArtifacts.count - metadataGapCount, 0))
    }

    private var metadataHealthCaption: String {
        metadataGapCount == 0
            ? StudioStrings.proposalWorkspaceValidationHealthy
            : StudioStrings.proposalWorkspaceValidationGaps
    }

    private var linkedEvidenceCount: Int {
        guard let document else { return 0 }
        return proposalArtifacts.filter { artifact in
            switch artifact.scopeKind {
            case "component":
                return artifact.referencesEvidence(path: document.components.first(where: { "component:\($0.id)" == artifact.scope })?.sourcePath)
            case "view":
                return artifact.referencesEvidence(path: document.views.first(where: { "view:\($0.id)" == artifact.scope })?.sourcePath)
            default:
                return false
            }
        }.count
    }

    private func reloadProposals() {
        let result = StudioChangeProposalArtifact.loadResult(from: repositoryRootURL)
        proposalArtifacts = result.artifacts
        proposalArtifactIssue = result.issue
        if proposalArtifacts.contains(where: { $0.id == selectedArtifactID }) == false {
            selectedArtifactID = proposalArtifacts.first?.id
        }
    }

    private var repositoryRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct StudioMacProposalArtifactDetailPanel: View {
    let artifact: StudioChangeProposalArtifact?
    let document: StudioNativeDocument?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioInspectorSection(title: StudioStrings.proposalWorkspaceSelectedArtifact) {
                if let artifact {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(artifact.title)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            StudioProposalArtifactBadge(text: artifact.applyPreviewReadiness.label, color: artifact.applyPreviewReadiness.color)
                            StudioProposalArtifactBadge(text: artifact.validationStatus.label, color: artifact.validationStatus.color)
                            StudioProposalArtifactBadge(text: artifact.status.label, color: artifact.status.color)
                        }

                        StudioKeyValueRow(label: StudioStrings.proposalScope, value: artifact.scope)
                        StudioKeyValueRow(label: StudioStrings.proposalCoverage, value: artifact.coverage.isEmpty ? StudioStrings.notAvailableYet : artifact.coverage)
                        StudioKeyValueRow(label: StudioStrings.proposalEvidence, value: artifact.sourceEvidenceSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalDiffContext, value: artifact.diffContextSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewEvidenceMatch, value: evidenceMatchLabel(for: artifact))

                        if !artifact.validationFindings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(StudioStrings.proposalValidation)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(artifact.validationFindings, id: \.self) { finding in
                                    Text("• \(finding)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        if let inspectAction = inspectAction(for: artifact), let targetID = artifact.scopeTargetID {
                            Button(StudioStrings.inspectProposalScope) {
                                inspectAction(targetID)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Text(StudioStrings.proposalWorkspaceSelectArtifactPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            StudioInspectorSection(title: StudioStrings.proposalApplyPreview) {
                if let artifact {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(StudioStrings.proposalApplyPreviewDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        StudioInspectorSummaryGrid(items: [
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalApplyPreviewReadiness,
                                value: artifact.applyPreviewReadiness.label,
                                tone: tone(for: artifact.applyPreviewReadiness)
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalCoverage,
                                value: artifact.coverage.isEmpty ? StudioStrings.notAvailableYet : artifact.coverage,
                                tone: tone(for: artifact.applyPreviewConfiguration.coverageLevel)
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalApplyPreviewEvidenceMatch,
                                value: evidenceMatchLabel(for: artifact),
                                tone: evidenceMatchTone(for: artifact)
                            )
                        ])

                        StudioPreviewContractPanel(configuration: artifact.applyPreviewConfiguration)

                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewExpectedImpact, value: artifact.applyPreviewImpactSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewWouldTouch, value: artifact.applyPreviewTouchSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewNextStep, value: artifact.applyPreviewNextStep)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(StudioStrings.recommendedNextStep)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(artifact.applyPreviewChecklist, id: \.self) { step in
                                Text("• \(step)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    Text(StudioStrings.proposalWorkspaceSelectArtifactPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func inspectAction(for artifact: StudioChangeProposalArtifact) -> ((String) -> Void)? {
        switch artifact.scopeKind {
        case "component":
            return inspectComponent
        case "view":
            return inspectView
        default:
            return nil
        }
    }

    private func evidenceMatchLabel(for artifact: StudioChangeProposalArtifact) -> String {
        isEvidenceMatched(for: artifact)
            ? StudioStrings.proposalApplyPreviewEvidenceMatched
            : StudioStrings.proposalApplyPreviewEvidenceNeedsCheck
    }

    private func isEvidenceMatched(for artifact: StudioChangeProposalArtifact) -> Bool {
        guard let document else { return false }
        switch artifact.scopeKind {
        case "component":
            return artifact.referencesEvidence(path: document.components.first(where: { "component:\($0.id)" == artifact.scope })?.sourcePath)
        case "view":
            return artifact.referencesEvidence(path: document.views.first(where: { "view:\($0.id)" == artifact.scope })?.sourcePath)
        default:
            return false
        }
    }

    private func evidenceMatchTone(for artifact: StudioChangeProposalArtifact) -> StudioInspectorSummaryTone {
        isEvidenceMatched(for: artifact) ? .success : .warning
    }

    private func tone(for readiness: StudioProposalApplyPreviewReadiness) -> StudioInspectorSummaryTone {
        switch readiness {
        case .ready:
            return .success
        case .review:
            return .warning
        case .blocked:
            return .warning
        }
    }

    private func tone(for coverage: StudioPreviewCoverageLevel) -> StudioInspectorSummaryTone {
        switch coverage {
        case .exact:
            return .success
        case .contractDriven:
            return .accent
        case .fallbackNeeded:
            return .warning
        }
    }
}

private struct StudioProposalArtifactBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }
}

private struct StudioPreviewCoveragePill: View {
    let level: StudioPreviewCoverageLevel
    let count: Int

    var body: some View {
        Text("\(count) \(level.rawValue)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(level.color.opacity(0.12), in: Capsule())
            .foregroundStyle(level.color)
    }
}
