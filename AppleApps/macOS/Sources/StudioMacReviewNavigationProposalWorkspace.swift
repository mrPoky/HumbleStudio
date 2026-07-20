import SwiftUI

struct StudioMacProposalArtifactsPage: View {
    let document: StudioNativeDocument?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void
    let openComponentReviewFocus: (String) -> Void
    let openViewNavigationFocus: (String) -> Void
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
                    StudioCountCard(
                        title: StudioStrings.proposalLinkageTickets,
                        value: StudioStrings.resultsCount(linkedTicketCount),
                        caption: linkedTicketCount == 0 ? StudioStrings.proposalNoLinkedTickets : StudioStrings.proposalLinkageTickets
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
                                label: StudioStrings.proposalLinkageTickets,
                                value: StudioStrings.resultsCount(linkedTicketCount),
                                tone: linkedTicketCount == 0 ? .warning : .success
                            ),
                            StudioInspectorSummaryItem(
                                label: StudioStrings.proposalWorkspaceValidationSignal,
                                value: metadataHealthCount,
                                tone: metadataGapCount == 0 ? .success : .warning
                            )
                        ])
                    }
                }

                StudioInspectorSection(title: StudioStrings.proposalWorkspaceQualitySummaryTitle) {
                    Text(StudioStrings.proposalWorkspaceQualitySummaryDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    StudioInspectorSummaryGrid(items: proposalWorkspaceQualityItems(
                        artifacts: proposalArtifacts,
                        document: document
                    ))
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

                StudioInspectorSection(title: StudioStrings.proposalApplyPreviewReadiness) {
                    StudioInspectorSummaryGrid(items: [
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalApplyPreviewReadinessReady,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.applyPreviewReadiness == .ready }.count),
                            tone: .success
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalApplyPreviewReadinessReview,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.applyPreviewReadiness == .review }.count),
                            tone: .warning
                        ),
                        StudioInspectorSummaryItem(
                            label: StudioStrings.proposalApplyPreviewReadinessBlocked,
                            value: StudioStrings.resultsCount(proposalArtifacts.filter { $0.applyPreviewReadiness == .blocked }.count),
                            tone: proposalArtifacts.contains(where: { $0.applyPreviewReadiness == .blocked }) ? .warning : .neutral
                        )
                    ])
                }

                HStack(alignment: .top, spacing: 16) {
                    StudioMacProposalArtifactSection(
                        artifacts: proposalArtifacts,
                        preferredScope: nil,
                        preferredEvidencePaths: [],
                        loadIssue: proposalArtifactIssue,
                        reloadProposals: reloadProposals,
                        inspectComponent: inspectComponent,
                        inspectView: inspectView,
                        openComponentReviewFocus: openComponentReviewFocus,
                        openViewNavigationFocus: openViewNavigationFocus,
                        artifactLimit: nil,
                        selectedArtifactID: selectedArtifactID,
                        selectArtifact: { artifact in
                            selectedArtifactID = artifact?.id
                        }
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    StudioMacProposalArtifactDetailPanel(
                        artifact: selectedArtifact,
                        document: document,
                        repositoryRootURL: repositoryRootURL,
                        inspectComponent: inspectComponent,
                        inspectView: inspectView,
                        openComponentReviewFocus: openComponentReviewFocus,
                        openViewNavigationFocus: openViewNavigationFocus
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
        guard let selectedArtifactID else {
            return nil
        }
        return proposalArtifacts.first(where: { $0.id == selectedArtifactID })
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

    private var linkedTicketCount: Int {
        Set(proposalArtifacts.flatMap(\.ticketIDs)).count
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
