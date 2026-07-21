import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct StudioChangeProposalArtifact: Identifiable, Equatable {
    let url: URL
    let scope: String
    let ticketIDs: [String]
    let evidenceItems: [String]
    let coverage: String
    let area: String
    let requestedChange: String
    let why: String
    let tokenCandidate: String
    let componentCandidate: String
    let viewCandidate: String
    let diffSignal: String
    let touchpoints: [String]
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
    var ticketSummary: String {
        if ticketIDs.isEmpty {
            return StudioStrings.proposalNoLinkedTickets
        }
        if ticketIDs.count == 1 {
            return ticketIDs[0]
        }
        return StudioStrings.proposalTicketSummary(count: ticketIDs.count, firstTicket: ticketIDs[0])
    }
    var diffContextSummary: String {
        let candidateSummary = [area, tokenCandidate, componentCandidate, viewCandidate]
            .filter { !$0.isEmpty && $0 != StudioStrings.notAvailableYet }
            .joined(separator: " · ")
        let pieces = [diffSignalSummary, touchpointSummary, candidateSummary]
            .filter { !$0.isEmpty && $0 != StudioStrings.notAvailableYet }
        if pieces.isEmpty {
            return StudioStrings.notAvailableYet
        }
        if pieces.count == 1 {
            return pieces[0]
        }
        return StudioStrings.proposalDiffContextSummary(pieces[0], pieces.dropFirst().joined(separator: " · "))
    }
    var diffSignalSummary: String {
        diffSignal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? StudioStrings.notAvailableYet : diffSignal
    }
    var touchpointSummary: String {
        if touchpoints.isEmpty {
            return StudioStrings.notAvailableYet
        }
        if touchpoints.count == 1 {
            return touchpoints[0]
        }
        return StudioStrings.proposalTouchpointSummary(count: touchpoints.count, firstItem: touchpoints[0])
    }
    var scopeDisplayLabel: String {
        StudioStrings.proposalScopeDisplay(kind: scopeKindLabel, identifier: scopeTargetID)
    }
    var coverageDisplayLabel: String {
        guard !coverage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return StudioStrings.notAvailableYet
        }
        return StudioStrings.previewCoverageLabel(previewCoverageLevel)
    }
    var scopeKindLabel: String {
        switch scopeKind {
        case "component":
            return StudioStrings.proposalScopeKindComponent
        case "view":
            return StudioStrings.proposalScopeKindView
        default:
            return StudioStrings.proposalScopeKindUnknown
        }
    }
    var status: StudioProposalArtifactStatus {
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
    var scopeConfidence: StudioProposalScopeConfidence {
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
    var validationStatus: StudioProposalArtifactValidationStatus {
        validationFindings.isEmpty ? .healthy : .needsAttention
    }
    var applyPreviewReadiness: StudioProposalApplyPreviewReadiness {
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
    var isReadyProposal: Bool {
        status == .ready
    }
    var isReadyForApplyPreview: Bool {
        applyPreviewReadiness == .ready
    }
    var applyPreviewConfiguration: StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration.viewDefault(presentation: previewPresentationHint)
        configuration.coverageLevel = previewCoverageLevel
        if evidenceItems.count > 1 {
            configuration.stackContext = .branched
        } else if scopeKind == "component" {
            configuration.stackContext = .single
        }
        configuration.breadcrumbTrail = [StudioStrings.proposalWorkspaceTitle, scopeDisplayLabel, StudioStrings.preview]
        configuration.currentStep = evidenceItems.isEmpty ? nil : 2
        configuration.totalSteps = acceptanceChecks.isEmpty ? 2 : 3
        configuration.modalDepth = configuration.presentationMode == .push ? 1 : 2
        configuration.contractNote = StudioStrings.previewProposalInferenceNote
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

    func referencesAnyEvidence(paths: [String]) -> Bool {
        paths.contains { referencesEvidence(path: $0) }
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
            ticketIDs: ticketIDs(in: content),
            evidenceItems: codeSpanValues(in: content, linePrefix: "- Evidence: "),
            coverage: lineValue(in: content, prefix: "- Coverage: `", suffix: "`"),
            area: lineValue(in: content, prefix: "- Area: `", suffix: "`"),
            requestedChange: lineValue(in: content, prefix: "- Intent: "),
            why: lineValue(in: content, prefix: "- Why: "),
            tokenCandidate: lineValue(in: content, prefix: "- Token candidate: `", suffix: "`"),
            componentCandidate: lineValue(in: content, prefix: "- Component candidate: `", suffix: "`"),
            viewCandidate: lineValue(in: content, prefix: "- View candidate: `", suffix: "`"),
            diffSignal: lineValue(in: content, prefix: "- Diff signal: "),
            touchpoints: codeSpanValues(in: content, linePrefix: "- Touchpoints: "),
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

    private static func ticketIDs(in content: String) -> [String] {
        let pattern = #"\bHS-\d{4}\b"#
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let fullRange = NSRange(content.startIndex..<content.endIndex, in: content)
        let identifiers = regularExpression.matches(in: content, range: fullRange).compactMap { match -> String? in
            guard let range = Range(match.range, in: content) else {
                return nil
            }
            return String(content[range])
        }
        return Array(Set(identifiers)).sorted()
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

enum StudioProposalArtifactStatus {
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

enum StudioProposalScopeConfidence {
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

enum StudioProposalArtifactValidationStatus {
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

enum StudioProposalApplyPreviewReadiness {
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

struct StudioMacReviewPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let nativeRecoveryIssue: StudioNativeRecoveryIssue?
    @Binding var selectedItem: StudioMacReviewSelection?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    @State private var inspectorLayoutMode: StudioPreviewLayoutMode = .focus
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        StudioNativePageContainer(
            document: document,
            nativeErrorMessage: nativeErrorMessage,
            nativeRecoveryIssue: nativeRecoveryIssue
        ) { document in
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
                                                ] + proposalTruth(for: component, document: document).reviewEvidenceRows,
                                                badges: proposalBadges(for: component, document: document),
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
                                                ] + proposalTruth(for: view, document: document).reviewEvidenceRows,
                                                badges: proposalBadges(for: view, document: document),
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
                    reloadProposals()
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

    private func proposalTruth(
        for component: StudioNativeDocument.ComponentItem,
        document: StudioNativeDocument
    ) -> StudioProposalScopeTruth {
        proposalScopeTruth(
            artifacts: proposalArtifacts,
            document: document,
            scope: "component:\(component.id)",
            evidencePaths: [component.sourcePath]
        )
    }

    private func proposalTruth(
        for view: StudioNativeDocument.ViewItem,
        document: StudioNativeDocument
    ) -> StudioProposalScopeTruth {
        proposalScopeTruth(
            artifacts: proposalArtifacts,
            document: document,
            scope: "view:\(view.id)",
            evidencePaths: [view.sourcePath]
        )
    }

    private func proposalBadges(
        for component: StudioNativeDocument.ComponentItem,
        document: StudioNativeDocument
    ) -> [StudioNativeReviewCard.Badge] {
        proposalTruth(for: component, document: document).badgeSignals.map {
            StudioNativeReviewCard.Badge(text: $0.text, color: $0.color)
        }
    }

    private func proposalBadges(
        for view: StudioNativeDocument.ViewItem,
        document: StudioNativeDocument
    ) -> [StudioNativeReviewCard.Badge] {
        proposalTruth(for: view, document: document).badgeSignals.map {
            StudioNativeReviewCard.Badge(text: $0.text, color: $0.color)
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
}

enum StudioMacReviewSelection: Equatable {
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
                                preferredEvidencePaths: [component.sourcePath],
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
                                preferredEvidencePaths: [view.sourcePath],
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

    private func proposalBadges(for component: StudioNativeDocument.ComponentItem) -> [StudioNativeReviewCard.Badge] {
        let matching = proposalArtifacts.filter {
            $0.matchesComponent(id: component.id) || $0.referencesEvidence(path: component.sourcePath)
        }
        return proposalBadges(matching: matching)
    }

    private func proposalBadges(for view: StudioNativeDocument.ViewItem) -> [StudioNativeReviewCard.Badge] {
        let matching = proposalArtifacts.filter {
            $0.matchesView(id: view.id) || $0.referencesEvidence(path: view.sourcePath)
        }
        return proposalBadges(matching: matching)
    }

    private func proposalBadges(matching: [StudioChangeProposalArtifact]) -> [StudioNativeReviewCard.Badge] {
        guard !matching.isEmpty else {
            return []
        }

        let readyCount = matching.filter(\.isReadyProposal).count
        let previewReadyCount = matching.filter(\.isReadyForApplyPreview).count
        var badges: [StudioNativeReviewCard.Badge] = [
            .init(text: StudioStrings.proposalCountSummary(matching.count), color: .accentColor)
        ]

        if readyCount > 0 {
            badges.append(.init(text: StudioStrings.proposalReadyCountSummary(readyCount), color: .green))
        }
        if previewReadyCount > 0 {
            badges.append(.init(text: StudioStrings.proposalPreviewReadyCountSummary(previewReadyCount), color: .blue))
        }

        return badges
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
        configuration.breadcrumbTrail = [StudioStrings.components, component.name]
        configuration.currentStep = 1
        configuration.totalSteps = getComponentUsageCount(component, in: document) > 0 ? 2 : 1
        configuration.contractNote = StudioStrings.previewComponentUsageInferenceNote
        return configuration
    }

    private func viewConfiguration(for view: StudioNativeDocument.ViewItem) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration.viewDefault(presentation: view.presentation)
        let graph = makeNativeNavigationGraph(document: document)
        configuration.coverageLevel = nativeViewPreviewCoverage(for: view)
        configuration.navigationDepth = view.root ? .root : (view.navigationCount > 1 ? .deep : .detail)
        configuration.stackContext = view.navigationCount > 1 || view.entryPoints.count > 1 ? .branched : (view.root ? .single : .stacked)
        let breadcrumb = graph.pathToRoot(view.id).compactMap { graph.viewByID[$0]?.name }
        configuration.breadcrumbTrail = breadcrumb.isEmpty ? configuration.stackContext.breadcrumbLabels : breadcrumb
        configuration.currentStep = max(configuration.breadcrumbTrail.count, 1)
        configuration.totalSteps = max(configuration.currentStep ?? 1, (graph.depths.values.max() ?? 0) + 1)
        configuration.modalDepth = StudioPreviewConfiguration.viewDefault(presentation: view.presentation).presentationMode == .push ? 1 : 2
        configuration.contractNote = nativeViewPreviewCoverage(for: view) == .exact
            ? StudioStrings.previewNavigationGraphNote
            : StudioStrings.previewNavigationGraphApproximationNote
        return configuration
    }
}

struct StudioMacNavigationPage: View {
    let document: StudioNativeDocument?
    let nativeErrorMessage: String?
    let nativeRecoveryIssue: StudioNativeRecoveryIssue?
    @Binding var selectedViewID: String?
    let inspectView: (String) -> Void
    @State private var inspectorLayoutMode: StudioPreviewLayoutMode = .focus
    @State private var proposalArtifacts: [StudioChangeProposalArtifact] = []
    @State private var proposalArtifactIssue: StudioProposalArtifactLoadIssue?

    var body: some View {
        StudioNativePageContainer(
            document: document,
            nativeErrorMessage: nativeErrorMessage,
            nativeRecoveryIssue: nativeRecoveryIssue
        ) { document in
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
                                                    incomingCount: graph.incoming[view.id]?.count ?? 0,
                                                    badges: proposalBadges(for: view, document: document)
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
                    document: document,
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
                reloadProposals()
            }
        }
    }

    private func selectedView(in graph: NativeNavigationGraph) -> StudioNativeDocument.ViewItem? {
        if let selectedViewID, let selected = graph.viewByID[selectedViewID] {
            return selected
        }
        return graph.viewByID[graph.rootViewID]
    }

    private func proposalBadges(
        for view: StudioNativeDocument.ViewItem,
        document: StudioNativeDocument
    ) -> [StudioNativeNavigationNodeCard.Badge] {
        proposalScopeTruth(
            artifacts: proposalArtifacts,
            document: document,
            scope: "view:\(view.id)",
            evidencePaths: [view.sourcePath]
        )
        .badgeSignals
        .map { StudioNativeNavigationNodeCard.Badge(text: $0.text, color: $0.color) }
    }

    private var repositoryRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func reloadProposals() {
        let result = StudioChangeProposalArtifact.loadResult(from: repositoryRootURL)
        proposalArtifacts = result.artifacts
        proposalArtifactIssue = result.issue
    }
}

private struct StudioNavigationDetailInspector: View {
    let document: StudioNativeDocument
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
                            let scopeTruth = proposalTruth(for: selectedView)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(scopeTruth.readOnlyGuidance)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                StudioInspectorSummaryGrid(items: proposalLinkageItems(for: selectedView))
                            }
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
                            preferredEvidencePaths: [selectedView.sourcePath],
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
        configuration.breadcrumbTrail = previewBreadcrumbTrail(for: view)
        configuration.currentStep = previewCurrentStep(for: view)
        configuration.totalSteps = previewTotalSteps(for: view)
        configuration.modalDepth = previewModalDepth(for: view)
        configuration.contractNote = previewContractNote(for: view)
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
        let scopeTruth = proposalTruth(for: view)

        return [
            StudioInspectorSummaryItem(label: StudioStrings.trigger, value: "\(uniqueTriggers.count)", tone: uniqueTriggers.isEmpty ? .neutral : .accent),
            StudioInspectorSummaryItem(label: StudioStrings.presentation, value: "\(modalTriggers)", tone: modalTriggers > 0 ? .warning : .neutral),
            StudioInspectorSummaryItem(label: StudioStrings.entryPoints, value: "\(view.entryPoints.count)", tone: view.entryPoints.isEmpty ? .neutral : .success),
            StudioInspectorSummaryItem(label: StudioStrings.actions, value: "\(view.primaryActions.count + view.secondaryActions.count)", tone: (view.primaryActions.count + view.secondaryActions.count) > 0 ? .success : .neutral),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalLinkageMatching,
                value: StudioStrings.resultsCount(scopeTruth.matchingArtifacts.count),
                tone: scopeTruth.hasMatchingProposals ? .accent : .neutral
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalLinkageTickets,
                value: StudioStrings.resultsCount(scopeTruth.linkedTicketIDs.count),
                tone: scopeTruth.linkedTicketIDs.isEmpty ? .neutral : .success
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalApplyPreviewSourceAudit,
                value: scopeTruth.sourceAuditLabel,
                tone: scopeTruth.sourceAuditTone
            ),
            StudioInspectorSummaryItem(
                label: StudioStrings.proposalApplyPreviewReadiness,
                value: StudioStrings.resultsCount(scopeTruth.previewReadyCount),
                tone: scopeTruth.previewReadyCount == 0 ? .neutral : .success
            )
        ]
    }

    private func proposalTruth(for view: StudioNativeDocument.ViewItem) -> StudioProposalScopeTruth {
        proposalScopeTruth(
            artifacts: proposalArtifacts,
            document: document,
            scope: "view:\(view.id)",
            evidencePaths: [view.sourcePath]
        )
    }

    private func proposalLinkageItems(for view: StudioNativeDocument.ViewItem) -> [StudioInspectorSummaryItem] {
        proposalTruth(for: view).summaryItems
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

    private func previewBreadcrumbTrail(for view: StudioNativeDocument.ViewItem) -> [String] {
        let path = graph.pathToRoot(view.id)
        let names = path.compactMap { graph.viewByID[$0]?.name }
        return names.isEmpty ? selectedViewStackContext(for: view).breadcrumbLabels : names
    }

    private func previewCurrentStep(for view: StudioNativeDocument.ViewItem) -> Int {
        max(previewBreadcrumbTrail(for: view).count, 1)
    }

    private func previewTotalSteps(for view: StudioNativeDocument.ViewItem) -> Int {
        let currentDepth = graph.depths[view.id] ?? 0
        let deepestDepth = furthestReachableDepth(from: view.id, visited: [])
        let remainingSteps = max(deepestDepth - currentDepth, 0)
        return max(previewCurrentStep(for: view) + remainingSteps, previewCurrentStep(for: view))
    }

    private func previewModalDepth(for view: StudioNativeDocument.ViewItem) -> Int {
        let path = graph.pathToRoot(view.id)
        guard path.count > 1 else {
            return configurationModalBaseDepth(for: view)
        }

        var modalTransitions = 0
        for pair in zip(path, path.dropFirst()) {
            let sourceID = pair.0
            let targetID = pair.1
            if let edge = graph.viewByID[sourceID]?.navigatesTo.first(where: {
                $0.targetID == targetID && ($0.type == "sheet" || $0.type == "replace")
            }) {
                modalTransitions += edge.type == "replace" ? 1 : 1
            }
        }

        return max(1 + modalTransitions, configurationModalBaseDepth(for: view))
    }

    private func configurationModalBaseDepth(for view: StudioNativeDocument.ViewItem) -> Int {
        let mode = StudioPreviewConfiguration.viewDefault(presentation: view.presentation).presentationMode
        return mode == .push ? 1 : 2
    }

    private func furthestReachableDepth(from viewID: String, visited: Set<String>) -> Int {
        guard visited.contains(viewID) == false else {
            return graph.depths[viewID] ?? 0
        }
        let currentDepth = graph.depths[viewID] ?? 0
        guard let view = graph.viewByID[viewID] else {
            return currentDepth
        }

        let nextVisited = visited.union([viewID])
        let childDepths = view.navigatesTo
            .filter { $0.type != "pop" }
            .map { furthestReachableDepth(from: $0.targetID, visited: nextVisited) }

        return ([currentDepth] + childDepths).max() ?? currentDepth
    }

    private func previewContractNote(for view: StudioNativeDocument.ViewItem) -> String {
        if nativeViewPreviewCoverage(for: view) == .exact {
            return StudioStrings.previewNavigationGraphNote
        }
        return StudioStrings.previewNavigationGraphApproximationNote
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

                StudioKeyValueRow(label: StudioStrings.proposalScope, value: scopeInspectorLabel)
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

    private var scopeInspectorLabel: String {
        switch selection {
        case let .component(component):
            return StudioStrings.proposalScopeDisplay(kind: StudioStrings.proposalScopeKindComponent, identifier: component.id)
        case let .view(view):
            return StudioStrings.proposalScopeDisplay(kind: StudioStrings.proposalScopeKindView, identifier: view.id)
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
        let diffSignal: String
        switch selection {
        case let .component(component):
            coverage = nativeComponentPreviewCoverage(for: component).rawValue
            sourcePath = component.sourcePath
            diffSignal = StudioStrings.proposalDiffSignalComponent
        case let .view(view):
            coverage = nativeViewPreviewCoverage(for: view).rawValue
            sourcePath = view.sourcePath
            diffSignal = StudioStrings.proposalDiffSignalView
        }
        let touchpoints = [
            sourcePath.isEmpty ? StudioStrings.notExportedYet : sourcePath,
            tokenCandidate ?? StudioStrings.notAvailableYet,
            componentCandidate ?? StudioStrings.notAvailableYet,
            viewCandidate ?? StudioStrings.notAvailableYet
        ].filter { !$0.isEmpty && $0 != StudioStrings.notAvailableYet }

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
        - \(StudioStrings.proposalMarkdownDiffSignalLabel): \(diffSignal)
        - \(StudioStrings.proposalMarkdownTouchpointsLabel): \(touchpoints.map { "`\($0)`" }.joined(separator: ", "))
        - Targets: \(structuredTargets.isEmpty ? StudioStrings.addPreciseTargetAfterInspection : structuredTargets)

        ## \(StudioStrings.proposalMarkdownAcceptanceHeading)
        \(acceptanceChecklist.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
}

private struct StudioPreviewCoveragePill: View {
    let level: StudioPreviewCoverageLevel
    let count: Int

    var body: some View {
        Text(StudioStrings.previewCoverageCount(count, level: level))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(level.color.opacity(0.12), in: Capsule())
            .foregroundStyle(level.color)
    }
}
