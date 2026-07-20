import AppKit
import SwiftUI

func proposalMatchedScopeSourcePath(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> String {
    guard let document else { return "" }
    switch artifact.scopeKind {
    case "component":
        return document.components.first(where: { "component:\($0.id)" == artifact.scope })?.sourcePath ?? ""
    case "view":
        return document.views.first(where: { "view:\($0.id)" == artifact.scope })?.sourcePath ?? ""
    default:
        return ""
    }
}

func proposalEvidenceMatched(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> Bool {
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

func proposalSnapshotCompare(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> StudioProposalSnapshotCompare? {
    guard let document else { return nil }
    guard let targetID = artifact.scopeTargetID else { return nil }

    switch artifact.scopeKind {
    case "component":
        guard let component = document.components.first(where: { $0.id == targetID }) else {
            return nil
        }
        return StudioProposalSnapshotCompare(
            scopeLabel: StudioStrings.proposalScopeDisplay(kind: artifact.scopeKindLabel, identifier: component.name),
            truthStatus: nativeComponentTruthStatus(for: component),
            coverageLevel: nativeComponentPreviewCoverage(for: component),
            sourcePath: component.sourcePath,
            primaryStructureLabel: StudioStrings.states,
            primaryStructureValue: StudioStrings.statesCount(component.statesCount),
            secondaryStructureLabel: StudioStrings.sourceTokens,
            secondaryStructureValue: StudioStrings.resultsCount(component.sourceTokenCount),
            snapshotURL: document.resolvedSnapshotURL(for: component.snapshot, appearance: .dark),
            snapshotAvailable: component.snapshot != nil,
            placeholderSystemImage: "photo"
        )
    case "view":
        guard let view = document.views.first(where: { $0.id == targetID }) else {
            return nil
        }
        return StudioProposalSnapshotCompare(
            scopeLabel: StudioStrings.proposalScopeDisplay(kind: artifact.scopeKindLabel, identifier: view.name),
            truthStatus: nativeViewTruthStatus(for: view),
            coverageLevel: nativeViewPreviewCoverage(for: view),
            sourcePath: view.sourcePath,
            primaryStructureLabel: StudioStrings.components,
            primaryStructureValue: StudioStrings.componentsCount(view.componentsCount),
            secondaryStructureLabel: StudioStrings.navigation,
            secondaryStructureValue: StudioStrings.linksCount(view.navigationCount),
            snapshotURL: document.resolvedSnapshotURL(for: view.snapshot, appearance: .dark),
            snapshotAvailable: view.snapshot != nil,
            placeholderSystemImage: "rectangle.on.rectangle"
        )
    default:
        return nil
    }
}

func proposalCurrentDeltaSummary(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> StudioProposalCurrentDeltaSummary {
    guard let compare = proposalSnapshotCompare(for: artifact, document: document) else {
        return StudioProposalCurrentDeltaSummary(
            postureLabel: StudioStrings.proposalApplyPreviewCurrentDeltaPostureBlocked,
            postureTone: .warning,
            alignedSignals: [],
            gaps: [StudioStrings.proposalApplyPreviewCurrentDeltaCompareUnavailable]
        )
    }

    var alignedSignals: [String] = []
    var gaps: [String] = []

    if compare.snapshotAvailable {
        alignedSignals.append(StudioStrings.proposalApplyPreviewCurrentDeltaAlignedSnapshot)
    } else {
        gaps.append(StudioStrings.proposalApplyPreviewCurrentDeltaNoSnapshotGap)
    }

    if proposalEvidenceMatched(for: artifact, document: document) {
        alignedSignals.append(StudioStrings.proposalApplyPreviewCurrentDeltaAlignedEvidence)
    } else {
        gaps.append(StudioStrings.proposalApplyPreviewCurrentDeltaEvidenceGap)
    }

    if compare.sourcePath.isEmpty {
        gaps.append(StudioStrings.proposalApplyPreviewCurrentDeltaNoSourceGap)
    }

    if compare.coverageLevel.rawValue != artifact.applyPreviewConfiguration.coverageLevel.rawValue {
        gaps.append(
            StudioStrings.proposalApplyPreviewCurrentDeltaCoverageGap(
                expected: artifact.applyPreviewConfiguration.coverageLevel.label,
                current: compare.coverageLevel.label
            )
        )
    }

    let postureLabel: String
    let postureTone: StudioInspectorSummaryTone
    if gaps.isEmpty {
        postureLabel = StudioStrings.proposalApplyPreviewCurrentDeltaPostureAligned
        postureTone = .success
    } else if compare.truthStatus.needsAttention || artifact.applyPreviewReadiness == .blocked {
        postureLabel = StudioStrings.proposalApplyPreviewCurrentDeltaPostureBlocked
        postureTone = .warning
    } else {
        postureLabel = StudioStrings.proposalApplyPreviewCurrentDeltaPostureReview
        postureTone = .accent
    }

    return StudioProposalCurrentDeltaSummary(
        postureLabel: postureLabel,
        postureTone: postureTone,
        alignedSignals: uniqueProposalItems(alignedSignals),
        gaps: uniqueProposalItems(gaps)
    )
}

func proposalSourceAuditStatus(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> StudioProposalSourceAuditStatus {
    let matchedEvidence = proposalEvidenceMatched(for: artifact, document: document)
    if matchedEvidence, artifact.scopeTargetID != nil, !artifact.ticketIDs.isEmpty {
        return .exact
    }
    if matchedEvidence || artifact.scopeTargetID != nil || !artifact.ticketIDs.isEmpty {
        return .related
    }
    return .needsMetadata
}

func uniqueProposalItems(_ items: [String]) -> [String] {
    var seen: Set<String> = []
    return items.filter { seen.insert($0).inserted }
}

func proposalSharedTone(for readiness: StudioProposalApplyPreviewReadiness) -> StudioInspectorSummaryTone {
    switch readiness {
    case .ready:
        return .success
    case .review:
        return .warning
    case .blocked:
        return .warning
    }
}

func proposalSharedTone(for coverage: StudioPreviewCoverageLevel) -> StudioInspectorSummaryTone {
    switch coverage {
    case .exact:
        return .success
    case .contractDriven:
        return .accent
    case .fallbackNeeded:
        return .warning
    }
}

func proposalSourceAuditLabel(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> String {
    switch proposalSourceAuditStatus(for: artifact, document: document) {
    case .exact:
        return StudioStrings.proposalApplyPreviewSourceAuditExact
    case .related:
        return StudioStrings.proposalApplyPreviewSourceAuditRelated
    case .needsMetadata:
        return StudioStrings.proposalApplyPreviewSourceAuditNeedsMetadata
    }
}

func proposalSourceAuditSummary(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> String {
    switch proposalSourceAuditStatus(for: artifact, document: document) {
    case .exact:
        return StudioStrings.proposalApplyPreviewSourceAuditSummaryExact
    case .related:
        return StudioStrings.proposalApplyPreviewSourceAuditSummaryRelated
    case .needsMetadata:
        return StudioStrings.proposalApplyPreviewSourceAuditSummaryNeedsMetadata
    }
}

func proposalSourceAuditTone(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> StudioInspectorSummaryTone {
    switch proposalSourceAuditStatus(for: artifact, document: document) {
    case .exact:
        return .success
    case .related:
        return .accent
    case .needsMetadata:
        return .warning
    }
}

func proposalInspectorLinkageItems(
    artifacts: [StudioChangeProposalArtifact],
    document: StudioNativeDocument?,
    scope: String? = nil,
    evidencePaths: [String]
) -> [StudioInspectorSummaryItem] {
    let normalizedEvidencePaths = evidencePaths.filter { !$0.isEmpty }
    let matching = artifacts.filter { artifact in
        let scopeMatches = scope.map { artifact.scope == $0 } ?? true
        let evidenceMatches = normalizedEvidencePaths.isEmpty ? false : artifact.referencesAnyEvidence(paths: normalizedEvidencePaths)
        return scopeMatches || evidenceMatches
    }
    let ready = matching.filter(\.isReadyProposal)
    let evidenceMatched = matching.filter { artifact in
        normalizedEvidencePaths.contains { artifact.referencesEvidence(path: $0) }
    }
    let linkedTickets = Set(matching.flatMap(\.ticketIDs))
    let previewReady = matching.filter(\.isReadyForApplyPreview)
    let sourceAuditExact = matching.filter { proposalSourceAuditStatus(for: $0, document: document) == .exact }
    let deltaAligned = matching.filter { proposalCurrentDeltaSummary(for: $0, document: document).gaps.isEmpty }
    let deltaGaps = matching.filter { !proposalCurrentDeltaSummary(for: $0, document: document).gaps.isEmpty }

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
            label: StudioStrings.proposalApplyPreviewSourceAudit,
            value: StudioStrings.resultsCount(sourceAuditExact.count),
            tone: sourceAuditExact.isEmpty ? .warning : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewCurrentDeltaAligned,
            value: StudioStrings.resultsCount(deltaAligned.count),
            tone: deltaAligned.isEmpty ? .neutral : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewCurrentDeltaGaps,
            value: StudioStrings.resultsCount(deltaGaps.count),
            tone: deltaGaps.isEmpty ? .success : .warning
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalLinkageTickets,
            value: StudioStrings.resultsCount(linkedTickets.count),
            tone: linkedTickets.isEmpty ? .warning : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewReadiness,
            value: StudioStrings.resultsCount(previewReady.count),
            tone: previewReady.isEmpty ? .neutral : .success
        )
    ]
}

func proposalInferenceQualityStatus(
    for artifact: StudioChangeProposalArtifact,
    document: StudioNativeDocument?
) -> StudioProposalInferenceQuality {
    let sourceAudit = proposalSourceAuditStatus(for: artifact, document: document)
    let deltaSummary = proposalCurrentDeltaSummary(for: artifact, document: document)

    if artifact.applyPreviewReadiness == .blocked || artifact.scopeConfidence == .low || sourceAudit == .needsMetadata {
        return .weak
    }

    if artifact.applyPreviewReadiness == .ready,
       artifact.scopeConfidence == .high,
       sourceAudit == .exact,
       deltaSummary.gaps.count <= 1 {
        return .strong
    }

    return .review
}

func proposalWorkspaceQualityItems(
    artifacts: [StudioChangeProposalArtifact],
    document: StudioNativeDocument?
) -> [StudioInspectorSummaryItem] {
    let exactSourceAudit = artifacts.filter { proposalSourceAuditStatus(for: $0, document: document) == .exact }.count
    let relatedSourceAudit = artifacts.filter { proposalSourceAuditStatus(for: $0, document: document) == .related }.count
    let missingSourceAudit = artifacts.filter { proposalSourceAuditStatus(for: $0, document: document) == .needsMetadata }.count
    let highConfidence = artifacts.filter { $0.scopeConfidence == .high }.count
    let mediumConfidence = artifacts.filter { $0.scopeConfidence == .medium }.count
    let lowConfidence = artifacts.filter { $0.scopeConfidence == .low }.count
    let strongInference = artifacts.filter { proposalInferenceQualityStatus(for: $0, document: document) == .strong }.count
    let reviewInference = artifacts.filter { proposalInferenceQualityStatus(for: $0, document: document) == .review }.count
    let weakInference = artifacts.filter { proposalInferenceQualityStatus(for: $0, document: document) == .weak }.count

    return [
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewSourceAuditExact,
            value: StudioStrings.resultsCount(exactSourceAudit),
            tone: exactSourceAudit == 0 ? .neutral : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewSourceAuditRelated,
            value: StudioStrings.resultsCount(relatedSourceAudit),
            tone: relatedSourceAudit == 0 ? .neutral : .accent
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalApplyPreviewSourceAuditNeedsMetadata,
            value: StudioStrings.resultsCount(missingSourceAudit),
            tone: missingSourceAudit == 0 ? .success : .warning
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalScopeConfidenceHigh,
            value: StudioStrings.resultsCount(highConfidence),
            tone: highConfidence == 0 ? .neutral : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalScopeConfidenceMedium,
            value: StudioStrings.resultsCount(mediumConfidence),
            tone: mediumConfidence == 0 ? .neutral : .accent
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalScopeConfidenceLow,
            value: StudioStrings.resultsCount(lowConfidence),
            tone: lowConfidence == 0 ? .success : .warning
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalInferenceQualityStrong,
            value: StudioStrings.resultsCount(strongInference),
            tone: strongInference == 0 ? .neutral : .success
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalInferenceQualityReview,
            value: StudioStrings.resultsCount(reviewInference),
            tone: reviewInference == 0 ? .neutral : .accent
        ),
        StudioInspectorSummaryItem(
            label: StudioStrings.proposalInferenceQualityWeak,
            value: StudioStrings.resultsCount(weakInference),
            tone: weakInference == 0 ? .success : .warning
        )
    ]
}

extension StudioMacProposalArtifactDetailPanel {
    func matchedScopeSourcePath(for artifact: StudioChangeProposalArtifact) -> String {
        proposalMatchedScopeSourcePath(for: artifact, document: document)
    }

    func repositoryAuditEntries(for artifact: StudioChangeProposalArtifact) -> [StudioProposalRepoAuditEntry] {
        var candidates: [String] = []
        let currentSourcePath = matchedScopeSourcePath(for: artifact)
        if !currentSourcePath.isEmpty {
            candidates.append(currentSourcePath)
        }
        candidates.append(contentsOf: artifact.evidenceItems)

        var seen: Set<String> = []
        return candidates.compactMap { rawCandidate in
            guard let resolved = resolveRepositoryCandidate(rawCandidate) else {
                return nil
            }
            guard seen.insert(resolved.displayPath).inserted else {
                return nil
            }
            return resolved
        }
    }

    func resolveRepositoryCandidate(_ rawCandidate: String) -> StudioProposalRepoAuditEntry? {
        let trimmed = rawCandidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let candidateURL: URL
        let displayPath: String

        if trimmed.hasPrefix("/") {
            candidateURL = URL(fileURLWithPath: trimmed)
            displayPath = trimmed
        } else {
            candidateURL = repositoryRootURL.appendingPathComponent(trimmed)
            displayPath = trimmed
        }

        let looksLikeAPath = trimmed.contains("/") || trimmed.contains(".")
        guard looksLikeAPath else {
            return nil
        }

        return StudioProposalRepoAuditEntry(
            displayPath: displayPath,
            exists: FileManager.default.fileExists(atPath: candidateURL.path)
        )
    }

    @ViewBuilder
    func snapshotCompareSection(for artifact: StudioChangeProposalArtifact) -> some View {
        if let compare = snapshotCompare(for: artifact) {
            VStack(alignment: .leading, spacing: 12) {
                Text(StudioStrings.proposalApplyPreviewSnapshotCompareDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                StudioInspectorSummaryGrid(items: [
                    StudioInspectorSummaryItem(
                        label: StudioStrings.truth,
                        value: compare.truthStatus.label,
                        tone: compare.truthStatus.needsAttention ? .warning : .success
                    ),
                    StudioInspectorSummaryItem(
                        label: StudioStrings.proposalCoverage,
                        value: compare.coverageLevel.label,
                        tone: tone(for: compare.coverageLevel)
                    ),
                    StudioInspectorSummaryItem(
                        label: compare.primaryStructureLabel,
                        value: compare.primaryStructureValue,
                        tone: .accent
                    ),
                    StudioInspectorSummaryItem(
                        label: compare.secondaryStructureLabel,
                        value: compare.secondaryStructureValue,
                        tone: .neutral
                    )
                ])

                StudioProposalSnapshotCompareThumbnail(
                    url: compare.snapshotURL,
                    appearance: .dark,
                    systemImage: compare.placeholderSystemImage
                )
                .frame(height: 190)

                StudioKeyValueRow(label: StudioStrings.proposalScope, value: compare.scopeLabel)
                StudioKeyValueRow(label: StudioStrings.snapshot, value: compare.snapshotAvailable ? StudioStrings.present : StudioStrings.missing)
                StudioKeyValueRow(label: StudioStrings.source, value: compare.sourcePath.isEmpty ? StudioStrings.notAvailableYet : compare.sourcePath)
                StudioKeyValueRow(label: compare.primaryStructureLabel, value: compare.primaryStructureValue)
                StudioKeyValueRow(label: compare.secondaryStructureLabel, value: compare.secondaryStructureValue)
                StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewEvidenceMatch, value: evidenceMatchLabel(for: artifact))
            }
        } else {
            Text(snapshotCompareUnavailableMessage(for: artifact))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    func currentDeltaSection(for artifact: StudioChangeProposalArtifact) -> some View {
        let summary = currentDeltaSummary(for: artifact)

        VStack(alignment: .leading, spacing: 12) {
            Text(StudioStrings.proposalApplyPreviewCurrentDeltaDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StudioInspectorSummaryGrid(items: [
                StudioInspectorSummaryItem(
                    label: StudioStrings.proposalApplyPreviewCurrentDeltaPosture,
                    value: summary.postureLabel,
                    tone: summary.postureTone
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.proposalApplyPreviewCurrentDeltaAligned,
                    value: StudioStrings.resultsCount(summary.alignedSignals.count),
                    tone: summary.alignedSignals.isEmpty ? .neutral : .success
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.proposalApplyPreviewCurrentDeltaGaps,
                    value: StudioStrings.resultsCount(summary.gaps.count),
                    tone: summary.gaps.isEmpty ? .success : .warning
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.proposalApplyPreviewReadiness,
                    value: artifact.applyPreviewReadiness.label,
                    tone: tone(for: artifact.applyPreviewReadiness)
                )
            ])

            previewDiffList(
                title: StudioStrings.proposalApplyPreviewCurrentDeltaAligned,
                items: summary.alignedSignals,
                emptyMessage: nil
            )
            previewDiffList(
                title: StudioStrings.proposalApplyPreviewCurrentDeltaGaps,
                items: summary.gaps,
                emptyMessage: nil
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(StudioStrings.proposalApplyPreviewCurrentDeltaFields)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(fieldDeltaRows(for: artifact)) { row in
                    StudioProposalFieldDeltaRow(row: row)
                }
            }
        }
    }

    @ViewBuilder
    func previewDiffList(title: String, items: [String], emptyMessage: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if items.isEmpty {
                if let emptyMessage {
                    Text(emptyMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    func diffPlan(
        for artifact: StudioChangeProposalArtifact,
        repoAuditEntries: [StudioProposalRepoAuditEntry]
    ) -> StudioProposalApplyPreviewDiffPlan {
        let deltaSummary = currentDeltaSummary(for: artifact)
        var touches = [artifact.applyPreviewTouchSummary]
        if let scopeTargetID = artifact.scopeTargetID {
            touches.append(StudioStrings.proposalScopeDisplay(kind: artifact.scopeKindLabel, identifier: scopeTargetID))
        }
        touches.append(contentsOf: deltaSummary.alignedSignals)

        let structuredTargetItems = artifact.structuredTargets
            .components(separatedBy: " · ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let targetCandidates = uniqueItems([
            artifact.tokenCandidate.isEmpty ? nil : "Token: \(artifact.tokenCandidate)",
            artifact.componentCandidate.isEmpty ? nil : "Component: \(artifact.componentCandidate)",
            artifact.viewCandidate.isEmpty ? nil : "View: \(artifact.viewCandidate)"
        ].compactMap { $0 } + structuredTargetItems)

        return StudioProposalApplyPreviewDiffPlan(
            touches: uniqueItems(touches),
            targetCandidates: targetCandidates,
            repositoryPaths: uniqueItems(repoAuditEntries.map(\.displayPath)),
            metadataGaps: uniqueItems(artifact.validationFindings + deltaSummary.gaps)
        )
    }

    func uniqueItems(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        return items.filter { seen.insert($0).inserted }
    }

    func evidenceMatchLabel(for artifact: StudioChangeProposalArtifact) -> String {
        isEvidenceMatched(for: artifact)
            ? StudioStrings.proposalApplyPreviewEvidenceMatched
            : StudioStrings.proposalApplyPreviewEvidenceNeedsCheck
    }

    func isEvidenceMatched(for artifact: StudioChangeProposalArtifact) -> Bool {
        proposalEvidenceMatched(for: artifact, document: document)
    }

    func evidenceMatchTone(for artifact: StudioChangeProposalArtifact) -> StudioInspectorSummaryTone {
        isEvidenceMatched(for: artifact) ? .success : .warning
    }

    func snapshotCompare(for artifact: StudioChangeProposalArtifact) -> StudioProposalSnapshotCompare? {
        proposalSnapshotCompare(for: artifact, document: document)
    }

    func currentDeltaSummary(for artifact: StudioChangeProposalArtifact) -> StudioProposalCurrentDeltaSummary {
        proposalCurrentDeltaSummary(for: artifact, document: document)
    }

    func fieldDeltaRows(for artifact: StudioChangeProposalArtifact) -> [StudioProposalFieldDeltaRowModel] {
        guard let compare = snapshotCompare(for: artifact) else {
            return [
                StudioProposalFieldDeltaRowModel(
                    field: StudioStrings.proposalApplyPreviewCurrentDeltaFields,
                    proposalValue: artifact.coverageDisplayLabel,
                    currentValue: StudioStrings.proposalApplyPreviewCurrentDeltaCompareUnavailable,
                    status: .gap
                )
            ]
        }

        let evidenceMatched = isEvidenceMatched(for: artifact)
        let coverageStatus: StudioProposalFieldDeltaStatus
        if compare.coverageLevel.rawValue == artifact.applyPreviewConfiguration.coverageLevel.rawValue {
            coverageStatus = .aligned
        } else if compare.coverageLevel == .fallbackNeeded {
            coverageStatus = .gap
        } else {
            coverageStatus = .review
        }

        let snapshotStatus: StudioProposalFieldDeltaStatus = compare.snapshotAvailable ? .aligned : .gap
        let evidenceStatus: StudioProposalFieldDeltaStatus = evidenceMatched ? .aligned : .gap
        let sourceStatus: StudioProposalFieldDeltaStatus = compare.sourcePath.isEmpty ? .gap : .aligned
        let truthStatus: StudioProposalFieldDeltaStatus = compare.truthStatus.needsAttention ? .review : .aligned
        let scopeStatus: StudioProposalFieldDeltaStatus = compare.scopeLabel.isEmpty ? .gap : .aligned
        let primaryStructureStatus: StudioProposalFieldDeltaStatus = artifact.touchpoints.isEmpty ? .gap : .review
        let secondaryStructureStatus: StudioProposalFieldDeltaStatus = artifact.hasStructuredTargets ? .review : .gap
        let proposalStructureValue = artifact.structuredTargets.isEmpty ? artifact.diffContextSummary : artifact.structuredTargets

        return [
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.proposalScope,
                proposalValue: artifact.scope,
                currentValue: compare.scopeLabel,
                status: scopeStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.proposalApplyPreviewCurrentDeltaCoverageField,
                proposalValue: artifact.applyPreviewConfiguration.coverageLevel.label,
                currentValue: compare.coverageLevel.label,
                status: coverageStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.truthStatus,
                proposalValue: artifact.applyPreviewReadiness.label,
                currentValue: compare.truthStatus.label,
                status: truthStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.proposalApplyPreviewCurrentDeltaSnapshotField,
                proposalValue: artifact.applyPreviewReadiness.label,
                currentValue: compare.snapshotAvailable ? StudioStrings.present : StudioStrings.missing,
                status: snapshotStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.proposalApplyPreviewCurrentDeltaEvidenceField,
                proposalValue: artifact.sourceEvidenceSummary,
                currentValue: evidenceMatchLabel(for: artifact),
                status: evidenceStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: compare.primaryStructureLabel,
                proposalValue: artifact.touchpointSummary,
                currentValue: compare.primaryStructureValue,
                status: primaryStructureStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: compare.secondaryStructureLabel,
                proposalValue: proposalStructureValue,
                currentValue: compare.secondaryStructureValue,
                status: secondaryStructureStatus
            ),
            StudioProposalFieldDeltaRowModel(
                field: StudioStrings.proposalApplyPreviewCurrentDeltaSourceField,
                proposalValue: StudioStrings.resultsCount(artifact.evidenceItems.count),
                currentValue: compare.sourcePath.isEmpty ? StudioStrings.notAvailableYet : compare.sourcePath,
                status: sourceStatus
            )
        ]
    }

    func snapshotCompareUnavailableMessage(for artifact: StudioChangeProposalArtifact) -> String {
        guard document != nil else {
            return StudioStrings.proposalApplyPreviewSnapshotCompareMissingDocument
        }
        if artifact.scopeTargetID == nil {
            return StudioStrings.proposalApplyPreviewSnapshotCompareMissingScope
        }
        switch artifact.scopeKind {
        case "component":
            let targetExists = document?.components.contains(where: { $0.id == artifact.scopeTargetID }) ?? false
            return targetExists ? StudioStrings.proposalApplyPreviewSnapshotCompareMissingDocument : StudioStrings.proposalApplyPreviewSnapshotCompareMissingScope
        case "view":
            let targetExists = document?.views.contains(where: { $0.id == artifact.scopeTargetID }) ?? false
            return targetExists ? StudioStrings.proposalApplyPreviewSnapshotCompareMissingDocument : StudioStrings.proposalApplyPreviewSnapshotCompareMissingScope
        default:
            return StudioStrings.proposalApplyPreviewSnapshotCompareMissingScope
        }
    }

    func sourceAuditLabel(for artifact: StudioChangeProposalArtifact) -> String {
        proposalSourceAuditLabel(for: artifact, document: document)
    }

    func sourceAuditSummary(for artifact: StudioChangeProposalArtifact) -> String {
        proposalSourceAuditSummary(for: artifact, document: document)
    }

    func sourceAuditTone(for artifact: StudioChangeProposalArtifact) -> StudioInspectorSummaryTone {
        proposalSourceAuditTone(for: artifact, document: document)
    }

    func sourceAuditStatus(for artifact: StudioChangeProposalArtifact) -> StudioProposalSourceAuditStatus {
        proposalSourceAuditStatus(for: artifact, document: document)
    }

    func tone(for readiness: StudioProposalApplyPreviewReadiness) -> StudioInspectorSummaryTone {
        proposalSharedTone(for: readiness)
    }

    func tone(for coverage: StudioPreviewCoverageLevel) -> StudioInspectorSummaryTone {
        proposalSharedTone(for: coverage)
    }
}

enum StudioProposalSourceAuditStatus {
    case exact
    case related
    case needsMetadata
}

enum StudioProposalInferenceQuality {
    case strong
    case review
    case weak
}

struct StudioProposalApplyPreviewDiffPlan {
    let touches: [String]
    let targetCandidates: [String]
    let repositoryPaths: [String]
    let metadataGaps: [String]
}

struct StudioProposalSnapshotCompare {
    let scopeLabel: String
    let truthStatus: StudioNativeTruthStatus
    let coverageLevel: StudioPreviewCoverageLevel
    let sourcePath: String
    let primaryStructureLabel: String
    let primaryStructureValue: String
    let secondaryStructureLabel: String
    let secondaryStructureValue: String
    let snapshotURL: URL?
    let snapshotAvailable: Bool
    let placeholderSystemImage: String
}

struct StudioProposalCurrentDeltaSummary {
    let postureLabel: String
    let postureTone: StudioInspectorSummaryTone
    let alignedSignals: [String]
    let gaps: [String]
}

enum StudioProposalFieldDeltaStatus {
    case aligned
    case review
    case gap

    var label: String {
        switch self {
        case .aligned:
            return StudioStrings.proposalApplyPreviewCurrentDeltaStatusAligned
        case .review:
            return StudioStrings.proposalApplyPreviewCurrentDeltaStatusReview
        case .gap:
            return StudioStrings.proposalApplyPreviewCurrentDeltaStatusGap
        }
    }

    var color: Color {
        switch self {
        case .aligned:
            return .green
        case .review:
            return .orange
        case .gap:
            return .red
        }
    }
}

struct StudioProposalFieldDeltaRowModel: Identifiable {
    let id = UUID()
    let field: String
    let proposalValue: String
    let currentValue: String
    let status: StudioProposalFieldDeltaStatus
}

struct StudioProposalFieldDeltaRow: View {
    let row: StudioProposalFieldDeltaRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(row.field)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                StudioProposalArtifactBadge(text: row.status.label, color: row.status.color)
            }

            StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewCurrentDeltaProposalValue, value: row.proposalValue)
            StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewCurrentDeltaCurrentValue, value: row.currentValue)
        }
        .padding(12)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct StudioProposalSnapshotCompareThumbnail: View {
    let url: URL?
    let appearance: StudioNativeAppearance
    let systemImage: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(appearance == .light ? Color.white : Color(hex: "#11182B"))

            if let url, url.isFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary.opacity(0.7), lineWidth: 1)
        )
    }

    private var fallback: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
            Text(StudioStrings.noSnapshot)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
    }
}

struct StudioProposalRepoAuditEntry: Identifiable {
    let displayPath: String
    let exists: Bool

    var id: String { displayPath }
}
