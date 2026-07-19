import AppKit
import SwiftUI

enum StudioProposalArtifactScopeFilter: CaseIterable, Identifiable {
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

enum StudioProposalArtifactStatusFilter: CaseIterable, Identifiable {
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

enum StudioProposalArtifactCoverageFilter: CaseIterable, Identifiable {
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

enum StudioProposalArtifactReadinessFilter: CaseIterable, Identifiable {
    case all
    case ready
    case review
    case blocked

    var id: Self { self }

    var label: String {
        switch self {
        case .all:
            return StudioStrings.proposalFilterAnyReadiness
        case .ready:
            return StudioStrings.proposalApplyPreviewReadinessReady
        case .review:
            return StudioStrings.proposalApplyPreviewReadinessReview
        case .blocked:
            return StudioStrings.proposalApplyPreviewReadinessBlocked
        }
    }
}

enum StudioProposalArtifactValidationFilter: CaseIterable, Identifiable {
    case all
    case healthy
    case needsAttention

    var id: Self { self }

    var label: String {
        switch self {
        case .all:
            return StudioStrings.proposalFilterAnyValidation
        case .healthy:
            return StudioStrings.proposalValidationHealthy
        case .needsAttention:
            return StudioStrings.proposalValidationNeedsAttention
        }
    }
}

enum StudioProposalArtifactSortOrder: CaseIterable, Identifiable {
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

struct StudioMacProposalArtifactSection: View {
    let artifacts: [StudioChangeProposalArtifact]
    let preferredScope: String?
    let preferredEvidencePaths: [String]
    let loadIssue: StudioProposalArtifactLoadIssue?
    let reloadProposals: () -> Void
    let inspectComponent: ((String) -> Void)?
    let inspectView: ((String) -> Void)?
    let openComponentReviewFocus: ((String) -> Void)?
    let openViewNavigationFocus: ((String) -> Void)?
    let artifactLimit: Int?
    let selectedArtifactID: String?
    let selectArtifact: ((StudioChangeProposalArtifact?) -> Void)?
    @State private var scopeFilter: StudioProposalArtifactScopeFilter = .matchingScope
    @State private var statusFilter: StudioProposalArtifactStatusFilter = .all
    @State private var coverageFilter: StudioProposalArtifactCoverageFilter = .all
    @State private var readinessFilter: StudioProposalArtifactReadinessFilter = .all
    @State private var validationFilter: StudioProposalArtifactValidationFilter = .all
    @State private var sortOrder: StudioProposalArtifactSortOrder = .newest

    init(
        artifacts: [StudioChangeProposalArtifact],
        preferredScope: String?,
        preferredEvidencePaths: [String],
        loadIssue: StudioProposalArtifactLoadIssue?,
        reloadProposals: @escaping () -> Void,
        inspectComponent: ((String) -> Void)?,
        inspectView: ((String) -> Void)?,
        openComponentReviewFocus: ((String) -> Void)? = nil,
        openViewNavigationFocus: ((String) -> Void)? = nil,
        artifactLimit: Int?,
        selectedArtifactID: String?,
        selectArtifact: ((StudioChangeProposalArtifact?) -> Void)?
    ) {
        self.artifacts = artifacts
        self.preferredScope = preferredScope
        self.preferredEvidencePaths = preferredEvidencePaths
        self.loadIssue = loadIssue
        self.reloadProposals = reloadProposals
        self.inspectComponent = inspectComponent
        self.inspectView = inspectView
        self.openComponentReviewFocus = openComponentReviewFocus
        self.openViewNavigationFocus = openViewNavigationFocus
        self.artifactLimit = artifactLimit
        self.selectedArtifactID = selectedArtifactID
        self.selectArtifact = selectArtifact
    }

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
        .onAppear(perform: synchronizeSelectionWithVisibleArtifacts)
        .onChange(of: filteredArtifacts.map(\.id)) { _, _ in
            synchronizeSelectionWithVisibleArtifacts()
        }
        .onChange(of: selectedArtifactID) { _, _ in
            synchronizeSelectionWithVisibleArtifacts()
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
                return matchesPreferredContext(artifact, exactOnly: true)
            case .relatedScope:
                return matchesPreferredContext(artifact, exactOnly: false)
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

        let readinessScoped = coverageScoped.filter { artifact in
            switch readinessFilter {
            case .all:
                return true
            case .ready:
                return artifact.applyPreviewReadiness == .ready
            case .review:
                return artifact.applyPreviewReadiness == .review
            case .blocked:
                return artifact.applyPreviewReadiness == .blocked
            }
        }

        let validationScoped = readinessScoped.filter { artifact in
            switch validationFilter {
            case .all:
                return true
            case .healthy:
                return artifact.validationStatus == .healthy
            case .needsAttention:
                return artifact.validationStatus == .needsAttention
            }
        }

        switch sortOrder {
        case .newest:
            return validationScoped.sorted { $0.updatedAt > $1.updatedAt }
        case .status:
            return validationScoped.sorted {
                statusRank(for: $0.status) == statusRank(for: $1.status)
                    ? $0.updatedAt > $1.updatedAt
                    : statusRank(for: $0.status) < statusRank(for: $1.status)
            }
        case .confidence:
            return validationScoped.sorted {
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

            HStack(spacing: 12) {
                Picker(StudioStrings.proposalFilterReadinessLabel, selection: $readinessFilter) {
                    ForEach(StudioProposalArtifactReadinessFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Picker(StudioStrings.proposalFilterValidationLabel, selection: $validationFilter) {
                    ForEach(StudioProposalArtifactValidationFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
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

    private func matchesPreferredContext(_ artifact: StudioChangeProposalArtifact, exactOnly: Bool) -> Bool {
        let evidenceMatch = artifact.referencesAnyEvidence(paths: preferredEvidencePaths)
        if let preferredScope, !preferredScope.isEmpty {
            if artifact.scope == preferredScope || evidenceMatch {
                return true
            }
            return exactOnly ? false : artifact.matchesRelatedScope(preferredScope)
        }
        if !preferredEvidencePaths.isEmpty {
            return evidenceMatch
        }
        return true
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

    private func focusAction(for artifact: StudioChangeProposalArtifact) -> ((String) -> Void)? {
        switch artifact.scopeKind {
        case "component":
            return openComponentReviewFocus
        case "view":
            return openViewNavigationFocus
        default:
            return nil
        }
    }

    private func focusActionTitle(for artifact: StudioChangeProposalArtifact) -> String {
        switch artifact.scopeKind {
        case "component":
            return StudioStrings.openProposalReviewFocus
        case "view":
            return StudioStrings.openProposalNavigationFocus
        default:
            return StudioStrings.inspectProposalScope
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
                } else if artifact.referencesAnyEvidence(paths: preferredEvidencePaths) {
                    StudioProposalArtifactBadge(text: StudioStrings.proposalEvidenceLinked, color: .green)
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

        StudioKeyValueRow(label: StudioStrings.proposalScope, value: artifact.scopeDisplayLabel)
        StudioKeyValueRow(label: StudioStrings.proposalStatus, value: artifact.status.label)
        StudioKeyValueRow(label: StudioStrings.proposalValidation, value: artifact.validationStatus.label)
        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewReadiness, value: artifact.applyPreviewReadiness.label)
        StudioKeyValueRow(label: StudioStrings.proposalScopeConfidence, value: artifact.scopeConfidence.label)
        StudioKeyValueRow(label: StudioStrings.proposalCoverage, value: artifact.coverageDisplayLabel)
        StudioKeyValueRow(label: StudioStrings.proposalEvidence, value: artifact.sourceEvidenceSummary)
        StudioKeyValueRow(label: StudioStrings.proposalTouchpoints, value: artifact.touchpointSummary)
        StudioKeyValueRow(label: StudioStrings.proposalTickets, value: artifact.ticketSummary)
        if !artifact.area.isEmpty {
            StudioKeyValueRow(label: StudioStrings.proposalArea, value: artifact.area)
        }
        if !artifact.requestedChange.isEmpty {
            StudioKeyValueRow(label: StudioStrings.requestedChange, value: artifact.requestedChange)
        }
        if !artifact.why.isEmpty {
            StudioKeyValueRow(label: StudioStrings.proposalWhy, value: artifact.why)
        }
        StudioKeyValueRow(label: StudioStrings.proposalDiffSignal, value: artifact.diffSignalSummary)
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

            if let focusAction = focusAction(for: artifact), let targetID = artifact.scopeTargetID {
                Button(focusActionTitle(for: artifact)) {
                    focusAction(targetID)
                }
                .buttonStyle(.bordered)
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

    private func synchronizeSelectionWithVisibleArtifacts() {
        guard let selectArtifact else {
            return
        }
        if let selectedArtifactID,
           visibleArtifacts.contains(where: { $0.id == selectedArtifactID }) {
            return
        }
        selectArtifact(visibleArtifacts.first)
    }
}

struct StudioMacProposalArtifactRecoveryCard: View {
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
