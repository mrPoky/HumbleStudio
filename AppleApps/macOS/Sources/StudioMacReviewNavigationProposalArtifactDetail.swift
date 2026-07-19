import SwiftUI

struct StudioMacProposalArtifactDetailPanel: View {
    let artifact: StudioChangeProposalArtifact?
    let document: StudioNativeDocument?
    let repositoryRootURL: URL
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    let openComponentReviewFocus: (String) -> Void
    let openViewNavigationFocus: (String) -> Void

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

                        StudioKeyValueRow(label: StudioStrings.proposalScope, value: artifact.scopeDisplayLabel)
                        StudioKeyValueRow(label: StudioStrings.proposalCoverage, value: artifact.coverageDisplayLabel)
                        StudioKeyValueRow(label: StudioStrings.proposalEvidence, value: artifact.sourceEvidenceSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalTouchpoints, value: artifact.touchpointSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalTickets, value: artifact.ticketSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalDiffSignal, value: artifact.diffSignalSummary)
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

                        if let targetID = artifact.scopeTargetID {
                            HStack(spacing: 10) {
                                if let focusAction = focusAction(for: artifact) {
                                    Button(focusActionTitle(for: artifact)) {
                                        focusAction(targetID)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }

                                if let inspectAction = inspectAction(for: artifact) {
                                    Button(StudioStrings.inspectProposalScope) {
                                        inspectAction(targetID)
                                    }
                                    .buttonStyle(.bordered)
                                }
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

            StudioInspectorSection(title: StudioStrings.proposalApplyPreview) {
                if let artifact {
                    let repoAuditEntries = repositoryAuditEntries(for: artifact)
                    let matchedRepoEntries = repoAuditEntries.filter(\.exists)
                    let missingRepoEntries = repoAuditEntries.filter { !$0.exists }
                    let diffPlan = diffPlan(for: artifact, repoAuditEntries: repoAuditEntries)

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
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalApplyPreviewSourceAudit,
                                value: sourceAuditLabel(for: artifact),
                                tone: sourceAuditTone(for: artifact)
                            )
                        ])

                        StudioPreviewContractPanel(configuration: artifact.applyPreviewConfiguration)

                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewExpectedImpact, value: artifact.applyPreviewImpactSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewWouldTouch, value: artifact.applyPreviewTouchSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalTickets, value: artifact.ticketSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalTouchpoints, value: artifact.touchpointSummary)
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewSourceAudit, value: sourceAuditSummary(for: artifact))
                        StudioKeyValueRow(label: StudioStrings.proposalApplyPreviewNextStep, value: artifact.applyPreviewNextStep)

                        StudioInspectorSection(title: StudioStrings.proposalApplyPreviewSnapshotCompare) {
                            snapshotCompareSection(for: artifact)
                        }

                        StudioInspectorSection(title: StudioStrings.proposalApplyPreviewCurrentDelta) {
                            currentDeltaSection(for: artifact)
                        }

                        StudioInspectorSection(title: StudioStrings.proposalApplyPreviewDiffPlan) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioInspectorSummaryGrid(items: [
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewDiffTouches,
                                        value: StudioStrings.resultsCount(diffPlan.touches.count),
                                        tone: diffPlan.touches.isEmpty ? .warning : .accent
                                    ),
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewDiffTargets,
                                        value: StudioStrings.resultsCount(diffPlan.targetCandidates.count),
                                        tone: diffPlan.targetCandidates.isEmpty ? .warning : .success
                                    ),
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewDiffPaths,
                                        value: StudioStrings.resultsCount(diffPlan.repositoryPaths.count),
                                        tone: diffPlan.repositoryPaths.isEmpty ? .warning : .success
                                    ),
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewDiffMetadata,
                                        value: StudioStrings.resultsCount(diffPlan.metadataGaps.count),
                                        tone: diffPlan.metadataGaps.isEmpty ? .success : .warning
                                    )
                                ])

                                previewDiffList(
                                    title: StudioStrings.proposalApplyPreviewDiffTouches,
                                    items: diffPlan.touches,
                                    emptyMessage: nil
                                )
                                previewDiffList(
                                    title: StudioStrings.proposalApplyPreviewDiffTargets,
                                    items: diffPlan.targetCandidates,
                                    emptyMessage: StudioStrings.proposalApplyPreviewDiffNoTargets
                                )
                                previewDiffList(
                                    title: StudioStrings.proposalApplyPreviewDiffPaths,
                                    items: diffPlan.repositoryPaths,
                                    emptyMessage: StudioStrings.proposalApplyPreviewDiffNoPaths
                                )
                                previewDiffList(
                                    title: StudioStrings.proposalApplyPreviewDiffMetadata,
                                    items: diffPlan.metadataGaps,
                                    emptyMessage: StudioStrings.proposalApplyPreviewDiffNoMetadataGaps
                                )
                            }
                        }

                        StudioInspectorSection(title: StudioStrings.proposalApplyPreviewRepoAudit) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioInspectorSummaryGrid(items: [
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewRepoMatched,
                                        value: StudioStrings.resultsCount(matchedRepoEntries.count),
                                        tone: matchedRepoEntries.isEmpty ? .warning : .success
                                    ),
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewRepoMissing,
                                        value: StudioStrings.resultsCount(missingRepoEntries.count),
                                        tone: missingRepoEntries.isEmpty ? .success : .warning
                                    ),
                                    StudioInspectorSummaryItem(
                                        label: StudioStrings.proposalApplyPreviewRepoCurrentSource,
                                        value: matchedScopeSourcePath(for: artifact).isEmpty ? StudioStrings.notAvailableYet : matchedScopeSourcePath(for: artifact),
                                        tone: matchedScopeSourcePath(for: artifact).isEmpty ? .warning : .accent
                                    )
                                ])

                                if repoAuditEntries.isEmpty {
                                    Text(StudioStrings.proposalApplyPreviewRepoNoCandidates)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    ForEach(repoAuditEntries.prefix(6)) { entry in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text(entry.displayPath)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer(minLength: 8)
                                            StudioProposalArtifactBadge(
                                                text: entry.exists ? StudioStrings.present : StudioStrings.missing,
                                                color: entry.exists ? .green : .orange
                                            )
                                        }
                                    }
                                }
                            }
                        }

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
}

struct StudioProposalArtifactBadge: View {
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
