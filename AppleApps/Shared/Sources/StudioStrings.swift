import Foundation

enum StudioStrings {
    static let appTitle = String(localized: "studio.app.title", defaultValue: "HumbleStudio")
    static let nativeSection = String(localized: "studio.sidebar.native", defaultValue: "Native")
    static let fallbackSection = String(localized: "studio.sidebar.fallback", defaultValue: "Fallback")
    static let quickOpen = String(localized: "studio.action.quick_open", defaultValue: "Quick Open")
    static let back = String(localized: "common.back", defaultValue: "Back")
    static func backTo(_ label: String) -> String {
        String(localized: "common.back_to", defaultValue: "Back to \(label)")
    }
    static let forward = String(localized: "common.forward", defaultValue: "Forward")
    static let open = String(localized: "common.open", defaultValue: "Open")
    static let openBundle = String(localized: "studio.action.open_bundle", defaultValue: "Open Bundle…")
    static let openRemoteURL = String(localized: "studio.action.open_remote_url", defaultValue: "Open Remote URL…")
    static let url = String(localized: "common.url", defaultValue: "URL")
    static let recent = String(localized: "common.recent", defaultValue: "Recent")
    static let recentURL = String(localized: "studio.action.recent_url", defaultValue: "Recent URL")
    static let reopenRecentImport = String(localized: "studio.action.reopen_recent_import", defaultValue: "Reopen Recent Import")
    static let reopenRecentImportHelp = String(localized: "studio.action.reopen_recent_import_help", defaultValue: "Reopen recent import")
    static let reopenRecentRemoteURL = String(localized: "studio.action.reopen_recent_remote_url", defaultValue: "Reopen Recent Remote URL")
    static let reopenRecentRemoteURLHelp = String(localized: "studio.action.reopen_recent_remote_url_help", defaultValue: "Reopen recent remote URL")
    static let loadDemo = String(localized: "studio.action.load_demo", defaultValue: "Load Demo")
    static let demo = String(localized: "studio.action.demo", defaultValue: "Demo")
    static let home = String(localized: "common.home", defaultValue: "Home")
    static let showHome = String(localized: "studio.action.show_home", defaultValue: "Show Home")
    static let reload = String(localized: "common.reload", defaultValue: "Reload")
    static let sources = String(localized: "studio.sources.title", defaultValue: "Sources")
    static let remoteSource = String(localized: "studio.remote_source.title", defaultValue: "Remote source")
    static let remoteSourcePrompt = String(localized: "studio.remote_source.prompt", defaultValue: "Use an http/https URL to a `.humblebundle`, `.zip`, or `design.json`. Native foundations and the legacy web inspector will both follow this source.")
    static let remoteSourcePlaceholder = String(localized: "studio.remote_source.placeholder", defaultValue: "https://raw.githubusercontent.com/mrPoky/HumbleSudoku/main/.humble/HumbleSudoku.humblebundle")
    static let useRecentURL = String(localized: "studio.remote_source.use_recent_url", defaultValue: "Use recent URL")
    static let openRemoteSourceTitle = String(localized: "studio.remote_source.open_title", defaultValue: "Open Remote URL")
    static let supportedAppsTitle = String(localized: "studio.remote_source.supported_apps_title", defaultValue: "Supported apps")
    static let supportedAppsPrompt = String(localized: "studio.remote_source.supported_apps_prompt", defaultValue: "Pick a known Humble app to prefill its exported raw URL or load it directly.")
    static let supportedAppSource = String(localized: "studio.remote_source.supported_app_source", defaultValue: "Supported app")
    static let useURL = String(localized: "studio.remote_source.use_url", defaultValue: "Use URL")
    static let loadNow = String(localized: "studio.remote_source.load_now", defaultValue: "Load Now")
    static let cancel = String(localized: "common.cancel", defaultValue: "Cancel")
    static let close = String(localized: "common.close", defaultValue: "Close")
    static let load = String(localized: "common.load", defaultValue: "Load")
    static let none = String(localized: "common.none", defaultValue: "None")
    static let current = String(localized: "common.current", defaultValue: "Current")
    static let unknown = String(localized: "common.unknown", defaultValue: "Unknown")
    static let legacyWeb = String(localized: "studio.legacy_web.title", defaultValue: "Legacy Web")
    static let webFallback = String(localized: "studio.legacy_web.fallback_label", defaultValue: "Web fallback")
    static let dropBundleTitle = String(localized: "studio.drop_bundle.title", defaultValue: "Drop a Humble bundle to import")
    static let dropBundleSubtitle = String(localized: "studio.drop_bundle.subtitle", defaultValue: ".humblebundle, .zip or .json")
    static let unableToLoadStudio = String(localized: "studio.error.unable_to_load", defaultValue: "Unable to load studio")
    static let unableToLoadLegacyInspector = String(localized: "studio.error.unable_to_load_legacy", defaultValue: "Unable to load legacy inspector")
    static let nativePreviewUnavailable = String(localized: "studio.error.native_preview_unavailable", defaultValue: "Native preview unavailable")
    static let loadDesignExport = String(localized: "studio.load_design_export.title", defaultValue: "Load a design export")
    static let loadNativeWorkspaceDescription = String(localized: "studio.load_design_export.workspace_description", defaultValue: "Open a `.humblebundle`, `.zip`, or `design.json` to populate the native foundations workspace.")
    static let loadNativePageDescription = String(localized: "studio.load_design_export.page_description", defaultValue: "Open a `.humblebundle`, `.zip`, or `design.json` to populate this native page.")
    static let componentsPageTitle = String(localized: "studio.content.components.title", defaultValue: "Components")
    static let componentsPageSubtitle = String(localized: "studio.content.components.subtitle", defaultValue: "First native component pass: snapshot-first cards over the exported contract, now with a real native inspector instead of a jump straight back to the web.")
    static let viewsPageTitle = String(localized: "studio.content.views.title", defaultValue: "Views")
    static let viewsPageSubtitle = String(localized: "studio.content.views.subtitle", defaultValue: "Native screen catalog over the exported truth, now with a native detail inspector for flow, linked components, and source evidence.")
    static let tokensPageTitle = String(localized: "studio.foundation.tokens.title", defaultValue: "Tokens")
    static let tokensPageSubtitle = String(localized: "studio.foundation.tokens.subtitle", defaultValue: "Native foundation inspector for colors and gradients, backed directly by the exported token contract.")
    static let iconsPageTitle = String(localized: "studio.foundation.icons.title", defaultValue: "Icons")
    static let iconsPageSubtitle = String(localized: "studio.foundation.icons.subtitle", defaultValue: "Native icon browser over the exported asset bundle, with a real inspector for symbol, asset path, and usage metadata.")
    static let typographyPageTitle = String(localized: "studio.foundation.typography.title", defaultValue: "Typography")
    static let typographyPageSubtitle = String(localized: "studio.foundation.typography.subtitle", defaultValue: "Native type role inspector for preview copy, SwiftUI mapping, and scale metadata exported from the design contract.")
    static let spacingPageTitle = String(localized: "studio.foundation.spacing.title", defaultValue: "Spacing & Radius")
    static let spacingPageSubtitle = String(localized: "studio.foundation.spacing.subtitle", defaultValue: "Native spatial token inspector for spacing and corner radius values, with larger previews and contract context instead of dashboard-only cards.")
    static let appearance = String(localized: "studio.preview.appearance", defaultValue: "Appearance")
    static let dark = String(localized: "studio.preview.appearance_dark", defaultValue: "Dark")
    static let light = String(localized: "studio.preview.appearance_light", defaultValue: "Light")
    static let componentCatalog = String(localized: "studio.content.component_catalog", defaultValue: "Component Catalog")
    static let colors = String(localized: "studio.foundation.colors", defaultValue: "Colors")
    static let gradients = String(localized: "studio.foundation.gradients", defaultValue: "Gradients")
    static let spacing = String(localized: "studio.foundation.spacing_group", defaultValue: "Spacing")
    static let cornerRadius = String(localized: "studio.foundation.corner_radius", defaultValue: "Corner Radius")
    static let componentDetail = String(localized: "studio.content.component_detail", defaultValue: "Component Detail")
    static let viewDetail = String(localized: "studio.content.view_detail", defaultValue: "View Detail")
    static let selectComponent = String(localized: "studio.content.select_component", defaultValue: "Select a component")
    static let selectComponentDescription = String(localized: "studio.content.select_component_description", defaultValue: "Choose a component card to inspect its snapshot truth, state catalog, and source metadata.")
    static let selectView = String(localized: "studio.content.select_view", defaultValue: "Select a view")
    static let selectViewDescription = String(localized: "studio.content.select_view_description", defaultValue: "Choose a view card to inspect its flow, linked components, and source evidence.")
    static let importingFile = String(localized: "studio.status.importing_file", defaultValue: "Importing file…")
    static let localFile = String(localized: "studio.source.local_file", defaultValue: "Local file")
    static let recoveryIssueArchive = String(localized: "studio.recovery.issue.archive", defaultValue: "Archive could not be unpacked")
    static let recoveryIssueManifest = String(localized: "studio.recovery.issue.manifest", defaultValue: "Missing design manifest")
    static let recoveryIssueDecode = String(localized: "studio.recovery.issue.decode", defaultValue: "Design export could not be decoded")
    static let recoveryIssuePlatform = String(localized: "studio.recovery.issue.platform", defaultValue: "Platform import limitation")
    static let recoveryIssueRemote = String(localized: "studio.recovery.issue.remote", defaultValue: "Remote source could not be hydrated")
    static let recoveryIssueLocal = String(localized: "studio.recovery.issue.local", defaultValue: "Local source could not be hydrated")
    static let recoveryIssueRecentImport = String(localized: "studio.recovery.issue.recent_import", defaultValue: "Recent import could not be reopened")
    static let recoveryIssueRemoteFetch = String(localized: "studio.recovery.issue.remote_fetch", defaultValue: "Remote source could not be downloaded")
    static let nativeImportPlatformDetail = String(localized: "studio.recovery.detail.platform", defaultValue: "Native bundle import is currently only available on macOS.")
    static let nativeImportArchiveDetail = String(localized: "studio.recovery.detail.archive", defaultValue: "The Humble bundle could not be unpacked.")
    static let nativeImportManifestDetail = String(localized: "studio.recovery.detail.manifest", defaultValue: "The imported source does not contain a design.json manifest.")
    static let nativeImportDecodeDetail = String(localized: "studio.recovery.detail.decode", defaultValue: "The imported design.json file could not be decoded.")
    static let saveProposalToRepo = String(localized: "studio.change_proposal.save_to_repo", defaultValue: "Save Proposal to Repo")
    static let repoProposalSaved = String(localized: "studio.change_proposal.repo_saved", defaultValue: "Proposal saved in repo")
    static let repoProposalFailed = String(localized: "studio.change_proposal.repo_failed", defaultValue: "Unable to save proposal in repo")
    static let sourceRecoveryTitle = String(localized: "studio.source_recovery.title", defaultValue: "Source & Recovery")
    static let currentSource = String(localized: "studio.source_recovery.current_source", defaultValue: "Current source")
    static let preferredRelaunch = String(localized: "studio.source_recovery.preferred_relaunch", defaultValue: "Preferred relaunch")
    static let recommendedNextStep = String(localized: "studio.source_recovery.recommended_next_step", defaultValue: "Recommended next step")
    static let recentRemote = String(localized: "studio.source_recovery.recent_remote", defaultValue: "Recent remote")
    static let notAvailableYet = String(localized: "common.not_available_yet", defaultValue: "Not available yet")
    static let currentIssue = String(localized: "studio.source_recovery.current_issue", defaultValue: "Current issue")
    static let issueCategory = String(localized: "studio.source_recovery.issue_category", defaultValue: "Issue category")
    static let recoveryPosture = String(localized: "studio.source_recovery.posture", defaultValue: "Recovery posture")
    static let recoveryChannel = String(localized: "studio.source_recovery.channel", defaultValue: "Best recovery channel")
    static let recoveryActionWhyLabel = String(localized: "studio.source_recovery.action_why", defaultValue: "Why this action")
    static let recoveryReadinessImportAndURL = String(localized: "studio.source_recovery.readiness.import_and_url", defaultValue: "Import + URL ready")
    static let recoveryReadinessImportOnly = String(localized: "studio.source_recovery.readiness.import_only", defaultValue: "Import ready")
    static let recoveryReadinessURLOnly = String(localized: "studio.source_recovery.readiness.url_only", defaultValue: "URL ready")
    static let recoveryReadinessBundledOnly = String(localized: "studio.source_recovery.readiness.bundled_only", defaultValue: "Bundled only")
    static func recoveryRecommendationIssue(_ actionTitle: String) -> String {
        String(format: String(localized: "studio.source_recovery.recommendation.issue", defaultValue: "Native hydration hit an issue. %@ is the safest next step while keeping the current session recoverable."), locale: Locale.current, actionTitle)
    }
    static func recoveryRecommendationHealthy(_ actionTitle: String) -> String {
        String(format: String(localized: "studio.source_recovery.recommendation.healthy", defaultValue: "Recovery is healthy. %@ remains available if you need to rehydrate the current source quickly."), locale: Locale.current, actionTitle)
    }
    static func recoveryRecommendationNoDocument(_ actionTitle: String) -> String {
        String(format: String(localized: "studio.source_recovery.recommendation.no_document", defaultValue: "No native document is loaded yet. %@ is the fastest way to establish working source truth."), locale: Locale.current, actionTitle)
    }
    static func recentImportResolutionFailed(_ reason: String) -> String {
        String(format: String(localized: "studio.source_recovery.recent_import_resolution_failed", defaultValue: "HumbleStudio could not reopen the recent import bookmark. Reason: %@"), locale: Locale.current, reason)
    }
    static func localFileReadFailed(_ fileName: String, _ reason: String) -> String {
        String(format: String(localized: "studio.source_recovery.local_file_read_failed", defaultValue: "HumbleStudio could not read %@. Reason: %@"), locale: Locale.current, fileName, reason)
    }
    static func remoteFetchUnavailable(_ host: String) -> String {
        String(format: String(localized: "studio.source_recovery.remote_fetch_unavailable", defaultValue: "HumbleStudio could not reach %@ while downloading the remote source."), locale: Locale.current, host)
    }
    static func remoteFetchTimedOut(_ host: String) -> String {
        String(format: String(localized: "studio.source_recovery.remote_fetch_timed_out", defaultValue: "The remote source at %@ took too long to respond."), locale: Locale.current, host)
    }
    static func remoteFetchServerRejected(_ host: String) -> String {
        String(format: String(localized: "studio.source_recovery.remote_fetch_server_rejected", defaultValue: "The remote source at %@ returned an invalid or rejected response."), locale: Locale.current, host)
    }
    static func recoveryIssueKindLabel(_ kind: StudioNativeRecoveryIssueKind) -> String {
        switch kind {
        case .recentImportBookmark:
            return String(localized: "studio.source_recovery.kind.recent_import_bookmark", defaultValue: "Recent import bookmark")
        case .localFile:
            return String(localized: "studio.source_recovery.kind.local_file", defaultValue: "Local file access")
        case .remoteFetch:
            return String(localized: "studio.source_recovery.kind.remote_fetch", defaultValue: "Remote download")
        case .archive:
            return String(localized: "studio.source_recovery.kind.archive", defaultValue: "Archive unpacking")
        case .manifest:
            return String(localized: "studio.source_recovery.kind.manifest", defaultValue: "Manifest structure")
        case .decode:
            return String(localized: "studio.source_recovery.kind.decode", defaultValue: "Manifest decoding")
        case .platform:
            return String(localized: "studio.source_recovery.kind.platform", defaultValue: "Platform limitation")
        case .remoteHydration:
            return String(localized: "studio.source_recovery.kind.remote_hydration", defaultValue: "Remote hydration")
        case .localHydration:
            return String(localized: "studio.source_recovery.kind.local_hydration", defaultValue: "Local hydration")
        }
    }

    static func recoveryPostureLabel(_ posture: StudioNativeRecoveryPosture) -> String {
        switch posture {
        case .recoverable:
            return String(localized: "studio.source_recovery.posture.recoverable", defaultValue: "Recoverable")
        case .degraded:
            return String(localized: "studio.source_recovery.posture.degraded", defaultValue: "Degraded")
        case .bundledOnly:
            return String(localized: "studio.source_recovery.posture.bundled_only", defaultValue: "Bundled-only")
        }
    }

    static func recoveryChannelLabel(_ action: StudioRecoveryAction) -> String {
        switch action {
        case .reopenRecentImport:
            return String(localized: "studio.source_recovery.channel.recent_import", defaultValue: "Recent import bookmark")
        case .reopenRecentRemoteURL:
            return String(localized: "studio.source_recovery.channel.recent_remote", defaultValue: "Recent remote URL")
        case .loadBundledStudio:
            return String(localized: "studio.source_recovery.channel.bundled", defaultValue: "Bundled studio")
        }
    }

    static func recoveryActionWhy(_ actionTitle: String, channel: String, posture: String) -> String {
        String(
            format: String(
                localized: "studio.source_recovery.action_why_value",
                defaultValue: "%1$@ is recommended because %2$@ is currently the safest %3$@ path."
            ),
            locale: Locale.current,
            actionTitle,
            channel,
            posture.lowercased()
        )
    }
    static let previewCoverageTitle = String(localized: "studio.preview_coverage.title", defaultValue: "Preview Coverage")
    static let previewCoverageSubtitle = String(localized: "studio.preview_coverage.subtitle", defaultValue: "How much of the current native surface is exact, contract-driven, or still leaning on fallback.")
    static let nativeParityMapTitle = String(localized: "studio.native_parity.title", defaultValue: "Native Parity Map")
    static let nativeParityMapSubtitle = String(localized: "studio.native_parity.subtitle", defaultValue: "What already has first-class macOS coverage, and what still relies on the legacy fallback.")
    static let exact = String(localized: "studio.preview_coverage.exact", defaultValue: "Exact")
    static let contractDriven = String(localized: "studio.preview_coverage.contract_driven", defaultValue: "Contract-driven")
    static let fallbackNeeded = String(localized: "studio.preview_coverage.fallback_needed", defaultValue: "Fallback needed")
    static let totalPreviewable = String(localized: "studio.preview_coverage.total", defaultValue: "Total previewable")
    static let parityExactLabel = String(localized: "studio.parity.exact", defaultValue: "1:1")
    static let parityDegradedLabel = String(localized: "studio.parity.degraded", defaultValue: "Degraded")
    static let parityFallbackLabel = String(localized: "studio.parity.fallback_only", defaultValue: "Fallback-only")
    static let legacyFallbackTitle = String(localized: "studio.legacy_fallback.title", defaultValue: "Legacy Web Fallback")
    static let nativeStatus = String(localized: "studio.legacy_fallback.native_status", defaultValue: "Native status")
    static let bestUse = String(localized: "studio.legacy_fallback.best_use", defaultValue: "Best use")
    static let legacyFallbackBestUseValue = String(localized: "studio.legacy_fallback.best_use_value", defaultValue: "Fallback for parity gaps, unresolved native detail, and future authoring/write-back workflows.")
    static func legacyFallbackNativeStatusIssues(_ message: String) -> String {
        String(localized: "studio.legacy_fallback.native_status_issues", defaultValue: "Native import has issues: \(message)")
    }
    static let legacyFallbackNativeStatusLoaded = String(localized: "studio.legacy_fallback.native_status_loaded", defaultValue: "Native bundle truth is loaded; fallback is optional support.")
    static let legacyFallbackNativeStatusMissing = String(localized: "studio.legacy_fallback.native_status_missing", defaultValue: "Native document is not loaded yet.")
    static let support = String(localized: "studio.legacy_fallback.support", defaultValue: "Support")
    static let primary = String(localized: "studio.legacy_fallback.primary", defaultValue: "Primary")
    static let legacyFallbackSummarySupport = String(localized: "studio.legacy_fallback.summary_support", defaultValue: "Native coverage exists for the main inspector surfaces. Use this path when you need the older web behavior or a parity escape hatch.")
    static let legacyFallbackSummaryPrimary = String(localized: "studio.legacy_fallback.summary_primary", defaultValue: "This fallback is currently carrying the session because native truth is missing or still recovering.")
    static let migrationStatusTitle = String(localized: "studio.migration_status.title", defaultValue: "Migration status")
    static let migrationStatusMessage = String(localized: "studio.migration_status.message", defaultValue: "The macOS app now reads bundle truth natively for foundations, components, views, review, and navigation. The legacy web inspector remains as a fallback for parity gaps and future authoring workflows while the SwiftUI surface keeps expanding.")
    static let overviewTokensCaption = String(localized: "studio.overview.tokens_caption", defaultValue: "Colors and gradients")
    static let overviewComponentsCaption = String(localized: "studio.overview.components_caption", defaultValue: "Native dashboard now reads snapshots from the bundle")
    static let overviewViewsCaption = String(localized: "studio.overview.views_caption", defaultValue: "Native screen catalog with snapshot-first previews")
    static let overviewNavigationTitle = String(localized: "studio.overview.navigation_title", defaultValue: "Navigation")
    static let overviewNavigationCaption = String(localized: "studio.overview.navigation_caption", defaultValue: "Flow edges derived from the exported contract")
    static let overviewIconsCaption = String(localized: "studio.overview.icons_caption", defaultValue: "Resolved from the bundle")
    static let overviewTypographyCaption = String(localized: "studio.overview.typography_caption", defaultValue: "Type roles")
    static let overviewSpacingCaption = String(localized: "studio.overview.spacing_caption", defaultValue: "Spatial tokens")
    static let reviewQueueTitle = String(localized: "studio.review.title", defaultValue: "Review Queue")
    static let reviewQueueSubtitle = String(localized: "studio.review.subtitle", defaultValue: "Start with items where exported truth is weakest, then jump straight into the matching native inspector.")
    static let nothingNeedsReview = String(localized: "studio.review.empty_title", defaultValue: "Nothing needs review")
    static let nothingNeedsReviewDescription = String(localized: "studio.review.empty_description", defaultValue: "All currently imported components and views have reference snapshots or enough exported truth for the native inspector.")
    static let reviewFocus = String(localized: "studio.review.focus", defaultValue: "Review Focus")
    static let whyStillNeedsReview = String(localized: "studio.review.why", defaultValue: "Why It Still Needs Review")
    static let chooseReviewItem = String(localized: "studio.review.choose_item", defaultValue: "Choose a review item")
    static let chooseReviewItemDescription = String(localized: "studio.review.choose_item_description", defaultValue: "Select a component or view in the queue to inspect its native truth gap and preview coverage.")
    static let totalTruthGapsCaption = String(localized: "studio.review.total_truth_gaps_caption", defaultValue: "Total native truth gaps surfaced from the current import")
    static let componentTruthGapsCaption = String(localized: "studio.review.component_truth_gaps_caption", defaultValue: "Reusable pieces missing snapshot or strong state truth")
    static let viewTruthGapsCaption = String(localized: "studio.review.view_truth_gaps_caption", defaultValue: "Screens whose visual or flow evidence still needs attention")
    static let exportChangeProposal = String(localized: "studio.change_proposal.export", defaultValue: "Export Change Proposal…")
    static let changeProposalTitle = String(localized: "studio.change_proposal.title", defaultValue: "Change Proposal")
    static let changeProposalDescription = String(localized: "studio.change_proposal.description", defaultValue: "Capture this review finding as a markdown proposal before any future write-back touches source truth.")
    static let requestedChange = String(localized: "studio.change_proposal.requested_change", defaultValue: "Requested change")
    static let structuredTargets = String(localized: "studio.change_proposal.structured_targets", defaultValue: "Structured targets")
    static let acceptanceNotes = String(localized: "studio.change_proposal.acceptance_notes", defaultValue: "Acceptance notes")
    static let proposalExported = String(localized: "studio.change_proposal.exported", defaultValue: "Proposal exported")
    static let proposalArtifactsTitle = String(localized: "studio.change_proposal.artifacts_title", defaultValue: "Proposal Artifacts")
    static let proposalArtifactsDescription = String(localized: "studio.change_proposal.artifacts_description", defaultValue: "Read back saved markdown proposals for this scope before planning any apply step.")
    static let refreshProposals = String(localized: "studio.change_proposal.refresh", defaultValue: "Refresh Proposals")
    static let openProposal = String(localized: "studio.change_proposal.open", defaultValue: "Open Proposal")
    static let revealProposal = String(localized: "studio.change_proposal.reveal", defaultValue: "Reveal in Finder")
    static let noMatchingProposals = String(localized: "studio.change_proposal.no_matching", defaultValue: "No saved proposal matches this review scope yet.")
    static let noSavedProposals = String(localized: "studio.change_proposal.no_saved", defaultValue: "No saved change proposals are available in the repository yet.")
    static let noFilteredProposals = String(localized: "studio.change_proposal.no_filtered", defaultValue: "No proposal artifacts match the current filter set.")
    static let proposalFilterScopeLabel = String(localized: "studio.change_proposal.filter.scope", defaultValue: "Scope filter")
    static let proposalFilterStatusLabel = String(localized: "studio.change_proposal.filter.status", defaultValue: "Status filter")
    static let proposalFilterCoverageLabel = String(localized: "studio.change_proposal.filter.coverage", defaultValue: "Coverage filter")
    static let proposalFilterReadinessLabel = String(localized: "studio.change_proposal.filter.readiness", defaultValue: "Preview readiness filter")
    static let proposalFilterValidationLabel = String(localized: "studio.change_proposal.filter.validation", defaultValue: "Validation filter")
    static let proposalSortLabel = String(localized: "studio.change_proposal.sort", defaultValue: "Sort")
    static let proposalFilterMatchingScope = String(localized: "studio.change_proposal.filter.matching_scope", defaultValue: "Matching context")
    static let proposalFilterRelatedScope = String(localized: "studio.change_proposal.filter.related_scope", defaultValue: "Related context")
    static let proposalFilterAllArtifacts = String(localized: "studio.change_proposal.filter.all_artifacts", defaultValue: "All artifacts")
    static let proposalFilterAnyStatus = String(localized: "studio.change_proposal.filter.any_status", defaultValue: "Any status")
    static let proposalFilterAnyCoverage = String(localized: "studio.change_proposal.filter.any_coverage", defaultValue: "Any coverage")
    static let proposalFilterAnyReadiness = String(localized: "studio.change_proposal.filter.any_readiness", defaultValue: "Any readiness")
    static let proposalFilterAnyValidation = String(localized: "studio.change_proposal.filter.any_validation", defaultValue: "Any validation")
    static let proposalSortNewest = String(localized: "studio.change_proposal.sort.newest", defaultValue: "Newest first")
    static let proposalSortStatus = String(localized: "studio.change_proposal.sort.status", defaultValue: "Status first")
    static let proposalSortConfidence = String(localized: "studio.change_proposal.sort.confidence", defaultValue: "Scope confidence first")
    static let proposalEvidenceLinked = String(localized: "studio.change_proposal.evidence_linked", defaultValue: "Evidence-linked")
    static let proposalLinkageTitle = String(localized: "studio.change_proposal.linkage.title", defaultValue: "Proposal Linkage")
    static let proposalLinkageMatching = String(localized: "studio.change_proposal.linkage.matching", defaultValue: "Matching proposals")
    static let proposalLinkageReady = String(localized: "studio.change_proposal.linkage.ready", defaultValue: "Ready proposals")
    static let proposalLinkageEvidence = String(localized: "studio.change_proposal.linkage.evidence", defaultValue: "Evidence-linked")
    static let proposalLinkageTickets = String(localized: "studio.change_proposal.linkage.tickets", defaultValue: "Linked tickets")
    static let proposalWorkspaceTitle = String(localized: "studio.change_proposal.workspace.title", defaultValue: "Proposal Workspace")
    static let proposalWorkspaceSubtitle = String(localized: "studio.change_proposal.workspace.subtitle", defaultValue: "Native repository view over saved proposal artifacts, their readiness, and their current linkage back to source truth.")
    static let proposalWorkspaceAllArtifacts = String(localized: "studio.change_proposal.workspace.all_artifacts", defaultValue: "All artifacts")
    static let proposalWorkspaceReady = String(localized: "studio.change_proposal.workspace.ready", defaultValue: "Ready")
    static let proposalWorkspaceNeedsRefinement = String(localized: "studio.change_proposal.workspace.needs_refinement", defaultValue: "Needs refinement")
    static let proposalWorkspaceValidationSignal = String(localized: "studio.change_proposal.workspace.validation_signal", defaultValue: "Validation signal")
    static let proposalWorkspaceValidationHealthy = String(localized: "studio.change_proposal.workspace.validation_healthy", defaultValue: "Metadata is mostly complete")
    static let proposalWorkspaceValidationGaps = String(localized: "studio.change_proposal.workspace.validation_gaps", defaultValue: "Some artifacts still need stronger scope or evidence metadata")
    static let proposalWorkspaceQualitySummaryTitle = String(localized: "studio.change_proposal.workspace.quality_summary.title", defaultValue: "Proposal Quality Summary")
    static let proposalWorkspaceQualitySummaryDescription = String(localized: "studio.change_proposal.workspace.quality_summary.description", defaultValue: "Shows how strongly saved proposals are backed by source evidence, how confident their scope mapping is, and how trustworthy their read-only inference currently looks.")
    static let proposalWorkspaceSelectedArtifact = String(localized: "studio.change_proposal.workspace.selected_artifact", defaultValue: "Selected Proposal")
    static let proposalWorkspaceSelectArtifactPrompt = String(localized: "studio.change_proposal.workspace.select_artifact_prompt", defaultValue: "Select a proposal artifact to inspect its validation, linked scope, and read-only apply preview.")
    static let proposalWorkspaceSelected = String(localized: "studio.change_proposal.workspace.selected", defaultValue: "Selected")
    static let proposalWorkspaceChooseArtifact = String(localized: "studio.change_proposal.workspace.choose_artifact", defaultValue: "Choose artifact")
    static let inspectProposalScope = String(localized: "studio.change_proposal.inspect_scope", defaultValue: "Inspect Scope")
    static let openProposalReviewFocus = String(localized: "studio.change_proposal.open_review_focus", defaultValue: "Open Review Focus")
    static let openProposalNavigationFocus = String(localized: "studio.change_proposal.open_navigation_focus", defaultValue: "Open Navigation Focus")
    static let proposalValidation = String(localized: "studio.change_proposal.validation", defaultValue: "Validation")
    static let proposalValidationHealthy = String(localized: "studio.change_proposal.validation_healthy", defaultValue: "Metadata complete")
    static let proposalValidationNeedsAttention = String(localized: "studio.change_proposal.validation_needs_attention", defaultValue: "Needs metadata")
    static let proposalValidationMissingScope = String(localized: "studio.change_proposal.validation_missing_scope", defaultValue: "Missing scope")
    static let proposalValidationMissingEvidence = String(localized: "studio.change_proposal.validation_missing_evidence", defaultValue: "Missing evidence")
    static let proposalValidationMissingAcceptance = String(localized: "studio.change_proposal.validation_missing_acceptance", defaultValue: "Missing acceptance notes")
    static let proposalValidationMissingTargets = String(localized: "studio.change_proposal.validation_missing_targets", defaultValue: "Missing structured targets")
    static let proposalValidationWeakScopeConfidence = String(localized: "studio.change_proposal.validation_weak_scope_confidence", defaultValue: "Weak scope confidence")
    static let proposalApplyPreview = String(localized: "studio.change_proposal.apply_preview", defaultValue: "Read-only Apply Preview")
    static let proposalApplyPreviewDescription = String(localized: "studio.change_proposal.apply_preview.description", defaultValue: "This preview estimates expected impact and next checks without mutating repository source truth.")
    static let proposalApplyPreviewSnapshotCompare = String(localized: "studio.change_proposal.apply_preview.snapshot_compare", defaultValue: "Current Native Snapshot Compare")
    static let proposalApplyPreviewSnapshotCompareDescription = String(localized: "studio.change_proposal.apply_preview.snapshot_compare.description", defaultValue: "Compares the saved proposal scope against the current native snapshot and source truth without simulating a repository write.")
    static let proposalApplyPreviewSnapshotCompareMissingDocument = String(localized: "studio.change_proposal.apply_preview.snapshot_compare.missing_document", defaultValue: "Current import is unavailable, so this compare can only stay at proposal metadata level for now.")
    static let proposalApplyPreviewSnapshotCompareMissingScope = String(localized: "studio.change_proposal.apply_preview.snapshot_compare.missing_scope", defaultValue: "No matching native component or view was found in the current import, so snapshot compare cannot be exact yet.")
    static let proposalApplyPreviewCurrentDelta = String(localized: "studio.change_proposal.apply_preview.current_delta", defaultValue: "Current Delta Summary")
    static let proposalApplyPreviewCurrentDeltaDescription = String(localized: "studio.change_proposal.apply_preview.current_delta.description", defaultValue: "Summarizes the current native gaps and alignments that this proposal would need to respect before any future apply-oriented workflow.")
    static let proposalApplyPreviewCurrentDeltaFields = String(localized: "studio.change_proposal.apply_preview.current_delta.fields", defaultValue: "Field-Level Delta")
    static let proposalApplyPreviewCurrentDeltaProposalValue = String(localized: "studio.change_proposal.apply_preview.current_delta.proposal_value", defaultValue: "Proposal")
    static let proposalApplyPreviewCurrentDeltaCurrentValue = String(localized: "studio.change_proposal.apply_preview.current_delta.current_value", defaultValue: "Current native")
    static let proposalApplyPreviewCurrentDeltaCoverageField = String(localized: "studio.change_proposal.apply_preview.current_delta.coverage_field", defaultValue: "Coverage")
    static let proposalApplyPreviewCurrentDeltaSnapshotField = String(localized: "studio.change_proposal.apply_preview.current_delta.snapshot_field", defaultValue: "Snapshot truth")
    static let proposalApplyPreviewCurrentDeltaEvidenceField = String(localized: "studio.change_proposal.apply_preview.current_delta.evidence_field", defaultValue: "Evidence linkage")
    static let proposalApplyPreviewCurrentDeltaSourceField = String(localized: "studio.change_proposal.apply_preview.current_delta.source_field", defaultValue: "Source path")
    static let proposalApplyPreviewCurrentDeltaPosture = String(localized: "studio.change_proposal.apply_preview.current_delta.posture", defaultValue: "Current delta posture")
    static let proposalApplyPreviewCurrentDeltaAligned = String(localized: "studio.change_proposal.apply_preview.current_delta.aligned", defaultValue: "Aligned signals")
    static let proposalApplyPreviewCurrentDeltaGaps = String(localized: "studio.change_proposal.apply_preview.current_delta.gaps", defaultValue: "Current gaps")
    static let proposalApplyPreviewCurrentDeltaStatusAligned = String(localized: "studio.change_proposal.apply_preview.current_delta.status_aligned", defaultValue: "Aligned")
    static let proposalApplyPreviewCurrentDeltaStatusReview = String(localized: "studio.change_proposal.apply_preview.current_delta.status_review", defaultValue: "Review")
    static let proposalApplyPreviewCurrentDeltaStatusGap = String(localized: "studio.change_proposal.apply_preview.current_delta.status_gap", defaultValue: "Gap")
    static let proposalApplyPreviewCurrentDeltaPostureAligned = String(localized: "studio.change_proposal.apply_preview.current_delta.posture_aligned", defaultValue: "Current native truth is aligned")
    static let proposalApplyPreviewCurrentDeltaPostureReview = String(localized: "studio.change_proposal.apply_preview.current_delta.posture_review", defaultValue: "Current native truth still needs review")
    static let proposalApplyPreviewCurrentDeltaPostureBlocked = String(localized: "studio.change_proposal.apply_preview.current_delta.posture_blocked", defaultValue: "Current native truth is still blocked")
    static let proposalApplyPreviewCurrentDeltaNoSnapshotGap = String(localized: "studio.change_proposal.apply_preview.current_delta.no_snapshot_gap", defaultValue: "Current native scope still has no reference snapshot.")
    static let proposalApplyPreviewCurrentDeltaNoSourceGap = String(localized: "studio.change_proposal.apply_preview.current_delta.no_source_gap", defaultValue: "Current native scope still has no repository-backed source path.")
    static let proposalApplyPreviewCurrentDeltaEvidenceGap = String(localized: "studio.change_proposal.apply_preview.current_delta.evidence_gap", defaultValue: "Proposal evidence does not currently match the native source path.")
    static let proposalApplyPreviewCurrentDeltaCompareUnavailable = String(localized: "studio.change_proposal.apply_preview.current_delta.compare_unavailable", defaultValue: "Current native compare is unavailable, so delta summary cannot go beyond proposal metadata yet.")
    static let proposalApplyPreviewCurrentDeltaAlignedSnapshot = String(localized: "studio.change_proposal.apply_preview.current_delta.aligned_snapshot", defaultValue: "Current native scope already has a reference snapshot.")
    static let proposalApplyPreviewCurrentDeltaAlignedEvidence = String(localized: "studio.change_proposal.apply_preview.current_delta.aligned_evidence", defaultValue: "Proposal evidence already matches the current native source path.")
    static func proposalApplyPreviewCurrentDeltaCoverageGap(expected: String, current: String) -> String {
        String(localized: "studio.change_proposal.apply_preview.current_delta.coverage_gap", defaultValue: "Proposal metadata expects \(expected), but current native coverage is only \(current).")
    }
    static let proposalApplyPreviewDiffPlan = String(localized: "studio.change_proposal.apply_preview.diff_plan", defaultValue: "Expected Diff Plan")
    static let proposalApplyPreviewDiffTouches = String(localized: "studio.change_proposal.apply_preview.diff_touches", defaultValue: "Likely touches")
    static let proposalApplyPreviewDiffTargets = String(localized: "studio.change_proposal.apply_preview.diff_targets", defaultValue: "Target candidates")
    static let proposalApplyPreviewDiffPaths = String(localized: "studio.change_proposal.apply_preview.diff_paths", defaultValue: "Repository paths")
    static let proposalApplyPreviewDiffMetadata = String(localized: "studio.change_proposal.apply_preview.diff_metadata", defaultValue: "Metadata gaps")
    static let proposalApplyPreviewDiffNoMetadataGaps = String(localized: "studio.change_proposal.apply_preview.diff_no_metadata_gaps", defaultValue: "No blocking metadata gaps remain in the current artifact.")
    static let proposalApplyPreviewDiffNoTargets = String(localized: "studio.change_proposal.apply_preview.diff_no_targets", defaultValue: "No structured target candidates are declared yet.")
    static let proposalApplyPreviewDiffNoPaths = String(localized: "studio.change_proposal.apply_preview.diff_no_paths", defaultValue: "No repository-backed paths could be derived for this artifact yet.")
    static let proposalApplyPreviewReadiness = String(localized: "studio.change_proposal.apply_preview.readiness", defaultValue: "Preview readiness")
    static let proposalApplyPreviewReadinessReady = String(localized: "studio.change_proposal.apply_preview.readiness_ready", defaultValue: "Preview-ready")
    static let proposalApplyPreviewReadinessReview = String(localized: "studio.change_proposal.apply_preview.readiness_review", defaultValue: "Needs review")
    static let proposalApplyPreviewReadinessBlocked = String(localized: "studio.change_proposal.apply_preview.readiness_blocked", defaultValue: "Blocked")
    static let proposalApplyPreviewExpectedImpact = String(localized: "studio.change_proposal.apply_preview.expected_impact", defaultValue: "Expected impact")
    static let proposalApplyPreviewWouldTouch = String(localized: "studio.change_proposal.apply_preview.would_touch", defaultValue: "Would touch")
    static let proposalApplyPreviewNextStep = String(localized: "studio.change_proposal.apply_preview.next_step", defaultValue: "Next preview step")
    static let proposalApplyPreviewEvidenceMatch = String(localized: "studio.change_proposal.apply_preview.evidence_match", defaultValue: "Evidence match")
    static let proposalApplyPreviewEvidenceMatched = String(localized: "studio.change_proposal.apply_preview.evidence_matched", defaultValue: "Matched to current source")
    static let proposalApplyPreviewEvidenceNeedsCheck = String(localized: "studio.change_proposal.apply_preview.evidence_needs_check", defaultValue: "Needs source confirmation")
    static let proposalApplyPreviewWouldTouchComponent = String(localized: "studio.change_proposal.apply_preview.would_touch_component", defaultValue: "Matching component contract, related evidence paths, and native component inspector")
    static let proposalApplyPreviewWouldTouchView = String(localized: "studio.change_proposal.apply_preview.would_touch_view", defaultValue: "Matching view contract, navigation context, and native view inspector")
    static let proposalApplyPreviewWouldTouchUnknown = String(localized: "studio.change_proposal.apply_preview.would_touch_unknown", defaultValue: "Proposal metadata is not precise enough to predict a safe native target yet")
    static let proposalApplyPreviewImpactReady = String(localized: "studio.change_proposal.apply_preview.impact_ready", defaultValue: "Metadata is strong enough for a trustworthy read-only preview pass.")
    static let proposalApplyPreviewImpactReview = String(localized: "studio.change_proposal.apply_preview.impact_review", defaultValue: "Preview can outline probable impact, but some metadata should be tightened first.")
    static let proposalApplyPreviewImpactBlocked = String(localized: "studio.change_proposal.apply_preview.impact_blocked", defaultValue: "Preview should stay blocked until core scope and evidence metadata are filled in.")
    static let proposalApplyPreviewNextStepReady = String(localized: "studio.change_proposal.apply_preview.next_step_ready", defaultValue: "Compare this proposal against the linked native inspector and confirm the intended diff stays read-only.")
    static let proposalApplyPreviewNextStepReview = String(localized: "studio.change_proposal.apply_preview.next_step_review", defaultValue: "Tighten scope confidence or structured targets before trusting any apply-oriented preview.")
    static let proposalApplyPreviewNextStepBlocked = String(localized: "studio.change_proposal.apply_preview.next_step_blocked", defaultValue: "Complete missing scope and evidence metadata before any future apply workflow.")
    static let proposalApplyPreviewCheckEvidence = String(localized: "studio.change_proposal.apply_preview.check_evidence", defaultValue: "Would compare listed evidence paths against the current repository surfaces.")
    static let proposalApplyPreviewCheckTargets = String(localized: "studio.change_proposal.apply_preview.check_targets", defaultValue: "Would verify structured targets and candidate mappings before any automated step.")
    static let proposalApplyPreviewCheckAcceptance = String(localized: "studio.change_proposal.apply_preview.check_acceptance", defaultValue: "Would confirm acceptance notes against native preview coverage and review truth.")
    static let proposalArtifactsIssueMissingDirectoryTitle = String(localized: "studio.change_proposal.issue.missing_directory.title", defaultValue: "Proposal folder not created yet")
    static let proposalArtifactsIssueUnreadableDirectoryTitle = String(localized: "studio.change_proposal.issue.unreadable_directory.title", defaultValue: "Proposal folder could not be read")
    static let proposalArtifactsIssueUnreadableArtifactTitle = String(localized: "studio.change_proposal.issue.unreadable_artifact.title", defaultValue: "Proposal file could not be read")
    static let proposalArtifactsIssueDirectoryNotFolder = String(localized: "studio.change_proposal.issue.directory_not_folder", defaultValue: "Expected a folder, but found another item instead.")
    static let proposalArtifactsIssueMissingDirectoryRecovery = String(localized: "studio.change_proposal.issue.missing_directory.recovery", defaultValue: "Save the first proposal to the repository to create `docs/change-proposals/`, then refresh this inspector.")
    static let proposalArtifactsIssueUnreadableDirectoryRecovery = String(localized: "studio.change_proposal.issue.unreadable_directory.recovery", defaultValue: "Check repository access or branch state, then refresh proposals.")
    static let proposalArtifactsIssueUnreadableArtifactRecovery = String(localized: "studio.change_proposal.issue.unreadable_artifact.recovery", defaultValue: "Open the affected markdown file, fix encoding or content access, then refresh proposals.")
    static let proposalScope = String(localized: "studio.change_proposal.scope", defaultValue: "Scope")
    static let proposalCoverage = String(localized: "studio.change_proposal.coverage", defaultValue: "Coverage")
    static let proposalEvidence = String(localized: "studio.change_proposal.evidence", defaultValue: "Evidence")
    static let proposalUpdated = String(localized: "studio.change_proposal.updated", defaultValue: "Updated")
    static let proposalStatus = String(localized: "studio.change_proposal.status", defaultValue: "Status")
    static let proposalArea = String(localized: "studio.change_proposal.area", defaultValue: "Area")
    static let proposalWhy = String(localized: "studio.change_proposal.why", defaultValue: "Why")
    static let proposalDiffContext = String(localized: "studio.change_proposal.diff_context", defaultValue: "Diff context")
    static let proposalDiffSignal = String(localized: "studio.change_proposal.diff_signal", defaultValue: "Diff signal")
    static let proposalTouchpoints = String(localized: "studio.change_proposal.touchpoints", defaultValue: "Touchpoints")
    static let proposalTickets = String(localized: "studio.change_proposal.tickets", defaultValue: "Tickets")
    static let proposalReadyShort = String(localized: "studio.change_proposal.ready_short", defaultValue: "ready")
    static let proposalPreviewReadyShort = String(localized: "studio.change_proposal.preview_ready_short", defaultValue: "preview-ready")
    static let proposalScopeConfidence = String(localized: "studio.change_proposal.scope_confidence", defaultValue: "Scope confidence")
    static let proposalStatusDraft = String(localized: "studio.change_proposal.status_draft", defaultValue: "Draft")
    static let proposalStatusRefine = String(localized: "studio.change_proposal.status_refine", defaultValue: "Needs target refinement")
    static let proposalStatusReady = String(localized: "studio.change_proposal.status_ready", defaultValue: "Ready for apply preview")
    static let proposalScopeConfidenceLow = String(localized: "studio.change_proposal.scope_confidence_low", defaultValue: "Low")
    static let proposalScopeConfidenceMedium = String(localized: "studio.change_proposal.scope_confidence_medium", defaultValue: "Related")
    static let proposalScopeConfidenceHigh = String(localized: "studio.change_proposal.scope_confidence_high", defaultValue: "High")
    static let proposalInferenceQualityStrong = String(localized: "studio.change_proposal.inference_quality_strong", defaultValue: "Strong inference")
    static let proposalInferenceQualityReview = String(localized: "studio.change_proposal.inference_quality_review", defaultValue: "Needs review")
    static let proposalInferenceQualityWeak = String(localized: "studio.change_proposal.inference_quality_weak", defaultValue: "Weak inference")
    static let proposalNoLinkedTickets = String(localized: "studio.change_proposal.no_linked_tickets", defaultValue: "No linked HS ticket yet")
    static let proposalApplyPreviewSourceAudit = String(localized: "studio.change_proposal.apply_preview.source_audit", defaultValue: "Source audit")
    static let proposalApplyPreviewSourceAuditExact = String(localized: "studio.change_proposal.apply_preview.source_audit_exact", defaultValue: "Linked and evidence-backed")
    static let proposalApplyPreviewSourceAuditRelated = String(localized: "studio.change_proposal.apply_preview.source_audit_related", defaultValue: "Partially linked")
    static let proposalApplyPreviewSourceAuditNeedsMetadata = String(localized: "studio.change_proposal.apply_preview.source_audit_needs_metadata", defaultValue: "Needs metadata")
    static let proposalApplyPreviewSourceAuditSummaryExact = String(localized: "studio.change_proposal.apply_preview.source_audit_summary_exact", defaultValue: "Proposal already links ticket, scope, and evidence strongly enough for a truthful native audit.")
    static let proposalApplyPreviewSourceAuditSummaryRelated = String(localized: "studio.change_proposal.apply_preview.source_audit_summary_related", defaultValue: "Proposal has some native linkage, but ticket or evidence metadata still needs tightening.")
    static let proposalApplyPreviewSourceAuditSummaryNeedsMetadata = String(localized: "studio.change_proposal.apply_preview.source_audit_summary_needs_metadata", defaultValue: "Proposal still needs ticket, scope, or evidence metadata before any apply-oriented audit should be trusted.")
    static let proposalApplyPreviewRepoAudit = String(localized: "studio.change_proposal.apply_preview.repo_audit", defaultValue: "Repository path audit")
    static let proposalApplyPreviewRepoMatched = String(localized: "studio.change_proposal.apply_preview.repo_matched", defaultValue: "Resolved repo files")
    static let proposalApplyPreviewRepoMissing = String(localized: "studio.change_proposal.apply_preview.repo_missing", defaultValue: "Missing candidates")
    static let proposalApplyPreviewRepoCurrentSource = String(localized: "studio.change_proposal.apply_preview.repo_current_source", defaultValue: "Current scope file")
    static let proposalApplyPreviewRepoNoCandidates = String(localized: "studio.change_proposal.apply_preview.repo_no_candidates", defaultValue: "No repository file candidates could be derived from current evidence yet.")
    static let proposalScopeKindComponent = String(localized: "studio.change_proposal.scope_kind.component", defaultValue: "Component")
    static let proposalScopeKindView = String(localized: "studio.change_proposal.scope_kind.view", defaultValue: "View")
    static let proposalScopeKindUnknown = String(localized: "studio.change_proposal.scope_kind.unknown", defaultValue: "Unknown scope")
    static let proposalScopeMissingTarget = String(localized: "studio.change_proposal.scope_missing_target", defaultValue: "Missing target")
    static let embeddedAppAssets = String(localized: "studio.source.embedded_assets", defaultValue: "Embedded app assets")
    static let demoSource = String(localized: "studio.source.demo", defaultValue: "Demo source")
    static let reloadDemoSource = String(localized: "studio.source.reload_demo", defaultValue: "Reload demo source")
    static func proposalTicketSummary(count: Int, firstTicket: String) -> String {
        String(localized: "studio.change_proposal.ticket_summary", defaultValue: "\(count) linked tickets, starting with \(firstTicket)")
    }
    static func proposalTouchpointSummary(count: Int, firstItem: String) -> String {
        String(localized: "studio.change_proposal.touchpoint_summary", defaultValue: "\(count) touchpoints, starting with \(firstItem)")
    }
    static func proposalCountSummary(_ count: Int) -> String {
        String(localized: "studio.change_proposal.count_summary", defaultValue: "\(count) proposals")
    }
    static func proposalReadyCountSummary(_ count: Int) -> String {
        String(localized: "studio.change_proposal.ready_count_summary", defaultValue: "\(count) ready")
    }
    static func proposalPreviewReadyCountSummary(_ count: Int) -> String {
        String(localized: "studio.change_proposal.preview_ready_count_summary", defaultValue: "\(count) preview-ready")
    }
    static func proposalScopeDisplay(kind: String, identifier: String?) -> String {
        let resolvedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let resolvedIdentifier, !resolvedIdentifier.isEmpty {
            return String(
                format: String(localized: "studio.change_proposal.scope_display", defaultValue: "%1$@ · %2$@"),
                locale: Locale.current,
                kind,
                resolvedIdentifier
            )
        }
        return String(
            format: String(localized: "studio.change_proposal.scope_display_missing_target", defaultValue: "%1$@ · %2$@"),
            locale: Locale.current,
            kind,
            proposalScopeMissingTarget
        )
    }
    static func proposalArtifactsIssueMissingDirectoryDetail(_ path: String) -> String {
        String(localized: "studio.change_proposal.issue.missing_directory.detail", defaultValue: "The repository does not have a `docs/change-proposals/` folder yet. Expected path: \(path)")
    }
    static func proposalArtifactsIssueUnreadableDirectoryDetail(_ path: String, _ reason: String) -> String {
        String(localized: "studio.change_proposal.issue.unreadable_directory.detail", defaultValue: "HumbleStudio could not read the proposal folder at \(path). Reason: \(reason)")
    }
    static func proposalArtifactsIssueUnreadableArtifactDetail(_ fileName: String, _ reason: String) -> String {
        String(localized: "studio.change_proposal.issue.unreadable_artifact.detail", defaultValue: "HumbleStudio skipped \(fileName) while reloading proposal artifacts. Reason: \(reason)")
    }
    static let inspectorFocus = String(localized: "studio.inspector.focus", defaultValue: "Inspector focus")
    static let needsReview = String(localized: "studio.review.needs_review", defaultValue: "Needs Review")
    static let components = String(localized: "studio.destination.components", defaultValue: "Components")
    static let views = String(localized: "studio.destination.views", defaultValue: "Views")
    static let navigationMap = String(localized: "studio.navigation.title", defaultValue: "Navigation Map")
    static let navigationSubtitle = String(localized: "studio.navigation.subtitle", defaultValue: "Native flow map derived from exported navigation edges, rooted at the app entry route.")
    static let flowDetail = String(localized: "studio.navigation.flow_detail", defaultValue: "Flow Detail")
    static let selectRouteNode = String(localized: "studio.navigation.select_route_node", defaultValue: "Select a route node")
    static let selectRouteNodeDescription = String(localized: "studio.navigation.select_route_node_description", defaultValue: "Choose a view in the navigation map to inspect how users reach it and where they can go next.")
    static let pathFromRoot = String(localized: "studio.navigation.path_from_root", defaultValue: "Path from root")
    static let howUsersGetHere = String(localized: "studio.navigation.how_users_get_here", defaultValue: "How Users Get Here")
    static let whatUsersCanDoNext = String(localized: "studio.navigation.what_users_can_do_next", defaultValue: "What Users Can Do Next")
    static let interactionModel = String(localized: "studio.navigation.interaction_model", defaultValue: "Interaction Model")
    static let route = String(localized: "studio.navigation.route", defaultValue: "Route")
    static let transitionProfile = String(localized: "studio.navigation.transition_profile", defaultValue: "Transition Profile")
    static let triggerAudit = String(localized: "studio.navigation.trigger_audit", defaultValue: "Trigger Audit")
    static let rootScreen = String(localized: "studio.navigation.root_screen", defaultValue: "Root screen")
    static let parityStatus = String(localized: "studio.parity.status", defaultValue: "Parity")
    static let coverageStatus = String(localized: "studio.coverage.status", defaultValue: "Coverage")
    static let trigger = String(localized: "studio.navigation.trigger", defaultValue: "Trigger")
    static let presentation = String(localized: "studio.navigation.presentation", defaultValue: "Presentation")
    static let incomingShort = String(localized: "studio.navigation.incoming_short", defaultValue: "in")
    static let outgoingShort = String(localized: "studio.navigation.outgoing_short", defaultValue: "out")
    static let componentsShort = String(localized: "studio.content.components_short", defaultValue: "comps")
    static let recoveryActionSummary = String(localized: "studio.source_recovery.action_summary", defaultValue: "Recovery action")
    static let recentImportUnavailable = String(localized: "studio.source_recovery.recent_import_unavailable", defaultValue: "No recent import is available yet.")
    static let recentRemoteUnavailable = String(localized: "studio.source_recovery.recent_remote_unavailable", defaultValue: "No recent remote URL is available yet.")
    static let enterRemoteURL = String(localized: "studio.remote_source.enter_url", defaultValue: "Enter a remote bundle or config URL.")
    static let onlyHTTPSSupported = String(localized: "studio.remote_source.only_http", defaultValue: "Only http and https URLs are supported.")
    static let unsupportedIncomingURL = String(localized: "studio.remote_source.unsupported_incoming", defaultValue: "Unsupported incoming URL.")
    static let onlyFileOrWebURLSupported = String(localized: "studio.remote_source.only_supported_types", defaultValue: "Only file, http, and https URLs are supported.")
    static let loadingBundledStudio = String(localized: "studio.status.loading_bundled", defaultValue: "Loading bundled studio…")
    static let reloadingStudio = String(localized: "studio.status.reloading", defaultValue: "Reloading studio…")
    static let parityLegacyWebSubtitle = String(localized: "studio.parity.legacy_web_subtitle", defaultValue: "Fallback path for parity gaps, missing native detail, and future write-back workflows.")
    static let parityReviewSubtitle = String(localized: "studio.parity.review_subtitle", defaultValue: "Queue truth is native, but it still surfaces degraded and fallback-risk areas explicitly.")
    static let parityNavigationSubtitle = String(localized: "studio.parity.navigation_subtitle", defaultValue: "Navigation graph is native and contract-aware, with behavior edges still approximated where needed.")
    static let parityProposalSubtitle = String(localized: "studio.parity.proposal_subtitle", defaultValue: "Proposal artifacts are fully native here, with repo-aware filters, recovery, scope linkage, and ticket-aware audit context.")
    static let parityTypographyExactSubtitle = String(localized: "studio.parity.typography_exact_subtitle", defaultValue: "Type roles are evidence-backed and inspectable natively.")
    static let parityTypographyDegradedSubtitle = String(localized: "studio.parity.typography_degraded_subtitle", defaultValue: "Type roles are native-first, but some usage context is still contract-driven.")
    static let paritySpacingExactSubtitle = String(localized: "studio.parity.spacing_exact_subtitle", defaultValue: "Spacing and radius tokens are evidence-backed natively.")
    static let paritySpacingDegradedSubtitle = String(localized: "studio.parity.spacing_degraded_subtitle", defaultValue: "Spatial tokens are inspectable natively, with some context still inferred from usage data.")
    static func parityNarrativeDegraded(_ count: Int) -> String {
        String(localized: "studio.parity.narrative_degraded", defaultValue: "\(count) native surfaces are already first-class enough for everyday inspection, but still expose degraded areas where behavior or evidence is modeled instead of fully reference-backed.")
    }
    static let parityNarrativeExact = String(localized: "studio.parity.narrative_exact", defaultValue: "Native inspection is broadly exact across the current imported bundle. Remaining fallback need is now mostly about future write-back authoring and long-tail parity edges.")
    static func previewCoverageNarrativeFallback(_ count: Int) -> String {
        String(
            format: String(localized: "studio.preview_coverage.narrative_fallback", defaultValue: "%lld native surfaces still need fallback help. The highest remaining risk is where exported visual truth and native behavior modeling are both still thin."),
            locale: Locale.current,
            count
        )
    }
    static func previewCoverageNarrativeContract(_ count: Int) -> String {
        String(
            format: String(localized: "studio.preview_coverage.narrative_contract", defaultValue: "Fallback pressure is low, but %lld surfaces are still modeled from contract rather than fully reference-backed visual truth."),
            locale: Locale.current,
            count
        )
    }
    static let previewCoverageNarrativeExact = String(localized: "studio.preview_coverage.narrative_exact", defaultValue: "All currently imported component and view surfaces are reference-backed in native preview.")
    static let previewDeviceLabel = String(localized: "studio.preview.device_label", defaultValue: "Device")
    static let previewOrientationLabel = String(localized: "studio.preview.orientation_label", defaultValue: "Orientation")
    static let previewPresentationLabel = String(localized: "studio.preview.presentation_label", defaultValue: "Presentation")
    static let previewChromeLabel = String(localized: "studio.preview.chrome_label", defaultValue: "Chrome")
    static let previewNavigationDepthLabel = String(localized: "studio.preview.navigation_depth_label", defaultValue: "Navigation depth")
    static let previewLayeringLabel = String(localized: "studio.preview.layering_label", defaultValue: "Layering")
    static let previewStackContext = String(localized: "studio.preview.stack_context", defaultValue: "Stack context")
    static let previewCoverage = String(localized: "studio.preview.coverage", defaultValue: "Coverage")
    static let previewShowSafeAreas = String(localized: "studio.preview.show_safe_areas", defaultValue: "Show safe areas")
    static let previewShowDeviceFrame = String(localized: "studio.preview.show_device_frame", defaultValue: "Show device frame")
    static let previewScale = String(localized: "studio.preview.scale", defaultValue: "Preview scale")
    static let previewContract = String(localized: "studio.preview.contract", defaultValue: "Preview contract")
    static let previewBehaviorModel = String(localized: "studio.preview.behavior_model", defaultValue: "Behavior model")
    static let previewFlowPath = String(localized: "studio.preview.flow_path", defaultValue: "Flow path")
    static let previewFlowProgress = String(localized: "studio.preview.flow_progress", defaultValue: "Flow progress")
    static let previewModalContext = String(localized: "studio.preview.modal_context", defaultValue: "Modal context")
    static let previewContractNoteLabel = String(localized: "studio.preview.contract_note_label", defaultValue: "Contract note")
    static let previewCoverageNote = String(localized: "studio.preview.coverage_note", defaultValue: "Coverage note")
    static let previewSizeClasses = String(localized: "studio.preview.size_classes", defaultValue: "Size classes")
    static let previewBreadcrumbDetail = String(localized: "studio.preview.breadcrumb.detail", defaultValue: "Detail")
    static let previewBreadcrumbFlow = String(localized: "studio.preview.breadcrumb.flow", defaultValue: "Flow")
    static let previewBreadcrumbReview = String(localized: "studio.preview.breadcrumb.review", defaultValue: "Review")
    static let previewFullScreen = String(localized: "studio.preview.presentation.full_screen", defaultValue: "Full Screen")
    static let previewNavigationChrome = String(localized: "studio.preview.chrome.navigation", defaultValue: "Navigation")
    static let previewNone = String(localized: "studio.preview.chrome.none", defaultValue: "None")
    static let previewTabBar = String(localized: "studio.preview.chrome.tab_bar", defaultValue: "Tab Bar")
    static let previewBoth = String(localized: "studio.preview.chrome.both", defaultValue: "Both")
    static let previewDeepLink = String(localized: "studio.preview.navigation_depth.deep", defaultValue: "Deep Link")
    static let previewInline = String(localized: "studio.preview.layering.inline", defaultValue: "Inline")
    static let previewElevated = String(localized: "studio.preview.layering.elevated", defaultValue: "Elevated")
    static let previewBlocking = String(localized: "studio.preview.layering.blocking", defaultValue: "Blocking")
    static let previewFit = String(localized: "studio.preview.scale.fit", defaultValue: "Fit")
    static let previewFocus = String(localized: "studio.preview.scale.focus", defaultValue: "Focus")
    static let previewCompact = String(localized: "studio.preview.size_class.compact", defaultValue: "Compact")
    static let previewRegular = String(localized: "studio.preview.size_class.regular", defaultValue: "Regular")
    static let loadingDemoConfig = String(localized: "studio.status.loading_demo", defaultValue: "Loading demo config…")
    static let loadingRemoteSource = String(localized: "studio.status.loading_remote", defaultValue: "Loading remote source…")
    static let restoringDemoSource = String(localized: "studio.status.restoring_demo", defaultValue: "Restoring demo source…")
    static let reopeningRecentImport = String(localized: "studio.status.reopening_import", defaultValue: "Reopening recent import…")
    static let recentImportUnavailableFallback = String(localized: "studio.status.import_unavailable_fallback", defaultValue: "Recent import is unavailable. Showing bundled studio.")
    static let restoringRemoteSource = String(localized: "studio.status.restoring_remote", defaultValue: "Restoring remote source…")
    static let recentRemoteUnavailableFallback = String(localized: "studio.status.remote_unavailable_fallback", defaultValue: "Recent remote URL is unavailable. Showing bundled studio.")
    static let nativePreviewUnavailableForSource = String(localized: "studio.status.native_preview_unavailable_source", defaultValue: "Native preview is unavailable for this source.")
    static let remotePreviewUnavailable = String(localized: "studio.status.remote_preview_unavailable", defaultValue: "Remote source loaded, but native preview could not be prepared.")
    static let recentImport = String(localized: "studio.action.recent_import", defaultValue: "Recent import")
    static let recentRemoteURLButton = String(localized: "studio.action.recent_remote_url", defaultValue: "Recent remote URL")
    static let bundledStudio = String(localized: "studio.action.bundled_studio", defaultValue: "Bundled studio")
    static let loadBundledStudioAction = String(localized: "studio.action.load_bundled_studio", defaultValue: "Load bundled studio")
    static let root = String(localized: "common.root", defaultValue: "Root")
    static let noSnapshot = String(localized: "studio.snapshot.none", defaultValue: "No snapshot")
    static let catalogOnly = String(localized: "studio.snapshot.catalog_only", defaultValue: "Catalog only")
    static let referenceSnapshot = String(localized: "studio.snapshot.reference", defaultValue: "Reference snapshot")
    static let approximationOnly = String(localized: "studio.snapshot.approximation_only", defaultValue: "Approximation only")
    static let preview = String(localized: "studio.inspector.preview", defaultValue: "Preview")
    static let relationships = String(localized: "studio.inspector.relationships", defaultValue: "Relationships")
    static let source = String(localized: "studio.inspector.source", defaultValue: "Source")
    static let inspectorSection = String(localized: "studio.inspector.section", defaultValue: "Inspector section")
    static let colorDetail = String(localized: "studio.foundation.color_detail", defaultValue: "Color Detail")
    static let gradientDetail = String(localized: "studio.foundation.gradient_detail", defaultValue: "Gradient Detail")
    static let iconDetail = String(localized: "studio.foundation.icon_detail", defaultValue: "Icon Detail")
    static let typographyDetail = String(localized: "studio.foundation.typography_detail", defaultValue: "Typography Detail")
    static let spacingDetail = String(localized: "studio.foundation.spacing_detail", defaultValue: "Spacing Detail")
    static let cornerRadiusDetail = String(localized: "studio.foundation.corner_radius_detail", defaultValue: "Corner Radius Detail")
    static let group = String(localized: "studio.foundation.group", defaultValue: "Group")
    static let references = String(localized: "studio.foundation.references", defaultValue: "References")
    static let variants = String(localized: "studio.foundation.variants", defaultValue: "Variants")
    static let derivedGradients = String(localized: "studio.foundation.derived_gradients", defaultValue: "Derived gradients")
    static let whatThisIs = String(localized: "studio.inspector.what_this_is", defaultValue: "What This Is")
    static let evidence = String(localized: "studio.inspector.evidence", defaultValue: "Evidence")
    static let usedByComponents = String(localized: "studio.inspector.used_by_components", defaultValue: "Used By Components")
    static let usedByViews = String(localized: "studio.inspector.used_by_views", defaultValue: "Used By Views")
    static let inspectComponent = String(localized: "studio.action.inspect_component", defaultValue: "Inspect Component")
    static let inspectView = String(localized: "studio.action.inspect_view", defaultValue: "Inspect View")
    static let selectToken = String(localized: "studio.foundation.select_token", defaultValue: "Select a token")
    static let selectTokenDescription = String(localized: "studio.foundation.select_token_description", defaultValue: "Choose a color or gradient card to inspect its variants, references, and relationships.")
    static let type = String(localized: "studio.foundation.type", defaultValue: "Type")
    static let token = String(localized: "studio.foundation.token", defaultValue: "Token")
    static let tokenColors = String(localized: "studio.foundation.token_colors", defaultValue: "Token colors")
    static let symbol = String(localized: "studio.foundation.symbol", defaultValue: "Symbol")
    static let truth = String(localized: "studio.foundation.truth", defaultValue: "Truth")
    static let bundledAsset = String(localized: "studio.foundation.bundled_asset", defaultValue: "Bundled asset")
    static let usedBy = String(localized: "studio.foundation.used_by", defaultValue: "Used by")
    static let contract = String(localized: "studio.inspector.contract", defaultValue: "Contract")
    static let asset = String(localized: "studio.inspector.asset", defaultValue: "Asset")
    static let path = String(localized: "studio.foundation.path", defaultValue: "Path")
    static let identifier = String(localized: "studio.foundation.identifier", defaultValue: "Identifier")
    static let selectIcon = String(localized: "studio.foundation.select_icon", defaultValue: "Select an icon")
    static let selectIconDescription = String(localized: "studio.foundation.select_icon_description", defaultValue: "Choose an icon card to inspect its symbol, bundled asset path, and exported usage metadata.")
    static let size = String(localized: "studio.foundation.size", defaultValue: "Size")
    static let weight = String(localized: "studio.foundation.weight", defaultValue: "Weight")
    static let previewSurface = String(localized: "studio.inspector.preview_surface", defaultValue: "Preview Surface")
    static let contextPreview = String(localized: "studio.inspector.context_preview", defaultValue: "Context Preview")
    static let flowContext = String(localized: "studio.inspector.flow_context", defaultValue: "Flow context")
    static let usageSignal = String(localized: "studio.inspector.usage_signal", defaultValue: "Usage signal")
    static let mostlyComponentScoped = String(localized: "studio.inspector.mostly_component_scoped", defaultValue: "Mostly component-scoped")
    static let visibleInViewLevelFlows = String(localized: "studio.inspector.visible_in_view_flows", defaultValue: "Visible in view-level flows")
    static let selectTypographyRole = String(localized: "studio.foundation.select_typography_role", defaultValue: "Select a typography role")
    static let selectTypographyRoleDescription = String(localized: "studio.foundation.select_typography_role_description", defaultValue: "Choose a type card to inspect its preview copy, scale, and SwiftUI mapping.")
    static let value = String(localized: "studio.foundation.value", defaultValue: "Value")
    static let usage = String(localized: "studio.foundation.usage", defaultValue: "Usage")
    static let noExportedUsageGuidanceYet = String(localized: "studio.foundation.no_usage_guidance", defaultValue: "No exported usage guidance yet")
    static let selectSpatialToken = String(localized: "studio.foundation.select_spatial_token", defaultValue: "Select a spatial token")
    static let selectSpatialTokenDescription = String(localized: "studio.foundation.select_spatial_token_description", defaultValue: "Choose a spacing or radius token to inspect its value, preview scale, and usage guidance.")
    static let sharedLightDark = String(localized: "studio.foundation.shared_light_dark", defaultValue: "Shared light/dark")
    static let distinctVariants = String(localized: "studio.foundation.distinct_variants", defaultValue: "Distinct variants")
    static let sharedLightDarkValue = String(localized: "studio.foundation.shared_light_dark_value", defaultValue: "Shared light/dark value")
    static let distinctLightDarkValues = String(localized: "studio.foundation.distinct_light_dark_values", defaultValue: "Distinct light and dark values")
    static let typographyPreviewSample = String(localized: "studio.foundation.typography_preview_sample", defaultValue: "The quick brown fox jumps over the lazy dog.")
    static let snapshot = String(localized: "studio.snapshot.label", defaultValue: "Snapshot")
    static let catalog = String(localized: "studio.snapshot.catalog", defaultValue: "Catalog")
    static let renderer = String(localized: "studio.content.renderer", defaultValue: "Renderer")
    static let defaultState = String(localized: "studio.content.default_state", defaultValue: "Default state")
    static let usedIn = String(localized: "studio.content.used_in", defaultValue: "Used in")
    static let whereItAppears = String(localized: "studio.content.where_it_appears", defaultValue: "Where It Appears")
    static let usedInViews = String(localized: "studio.content.used_in_views", defaultValue: "Used In Views")
    static let foundationCategories = String(localized: "studio.content.foundation_categories", defaultValue: "Foundation categories")
    static let stateCatalog = String(localized: "studio.content.state_catalog", defaultValue: "State Catalog")
    static let states = String(localized: "studio.content.states", defaultValue: "States")
    static let designTokens = String(localized: "studio.content.design_tokens", defaultValue: "Design tokens")
    static let sourceTokens = String(localized: "studio.content.source_tokens", defaultValue: "Source tokens")
    static let file = String(localized: "studio.content.file", defaultValue: "File")
    static let categories = String(localized: "studio.content.categories", defaultValue: "Categories")
    static let flow = String(localized: "studio.content.flow", defaultValue: "Flow")
    static let entryPoints = String(localized: "studio.content.entry_points", defaultValue: "Entry points")
    static let primaryActions = String(localized: "studio.content.primary_actions", defaultValue: "Primary actions")
    static let secondaryActions = String(localized: "studio.content.secondary_actions", defaultValue: "Secondary actions")
    static let linkedComponents = String(localized: "studio.content.linked_components", defaultValue: "Linked components")
    static let nextSteps = String(localized: "studio.content.next_steps", defaultValue: "Next steps")
    static let actions = String(localized: "studio.content.actions", defaultValue: "Actions")
    static let viewCountLabel = String(localized: "studio.content.views_label", defaultValue: "Views")
    static let edgeCountLabel = String(localized: "studio.content.edges_label", defaultValue: "Edges")
    static let rootLabel = String(localized: "common.root", defaultValue: "Root")
    static let depth = String(localized: "studio.navigation.depth", defaultValue: "Depth")
    static let incoming = String(localized: "studio.navigation.incoming", defaultValue: "Incoming")
    static let outgoing = String(localized: "studio.navigation.outgoing", defaultValue: "Outgoing")
    static let truthStatus = String(localized: "studio.review.truth_status", defaultValue: "Truth status")
    static let gap = String(localized: "studio.review.gap", defaultValue: "Gap")
    static let navigation = String(localized: "studio.navigation.label", defaultValue: "Navigation")
    static let missing = String(localized: "common.missing", defaultValue: "Missing")
    static let present = String(localized: "common.present", defaultValue: "Present")
    static let notExportedYet = String(localized: "studio.content.not_exported_yet", defaultValue: "Not exported yet")
    static let addPreciseTargetAfterInspection = String(localized: "studio.change_proposal.add_precise_target", defaultValue: "Add precise target after inspection.")
    static let push = String(localized: "studio.navigation.push", defaultValue: "Push")
    static let sheet = String(localized: "studio.navigation.sheet", defaultValue: "Sheet")
    static let replace = String(localized: "studio.navigation.replace", defaultValue: "Replace")
    static let other = String(localized: "studio.navigation.other", defaultValue: "Other")
    static let overlays = String(localized: "studio.content.overlays", defaultValue: "Overlays")
    static let sheets = String(localized: "studio.content.sheets", defaultValue: "Sheets")
    static let componentFallbackSubtitle = String(localized: "studio.content.component_fallback_subtitle", defaultValue: "Component")
    static let swiftUILabel = String(localized: "studio.content.swiftui", defaultValue: "SwiftUI")
    static let quickOpenSearchPlaceholder = String(localized: "studio.quick_open.search_placeholder", defaultValue: "Search pages, foundations, components, and views…")
    static let quickOpenNoMatches = String(localized: "studio.quick_open.no_matches", defaultValue: "No matches")
    static let quickOpenNoMatchesDescription = String(localized: "studio.quick_open.no_matches_description", defaultValue: "Try searching by token name, component, view, or page.")
    static let pages = String(localized: "studio.quick_open.pages", defaultValue: "Pages")
    static let proposalIntentComponentTemplate = String(localized: "studio.change_proposal.intent_component", defaultValue: "Tighten native truth for %@ and resolve the current review gap before future write-back.")
    static let proposalIntentViewTemplate = String(localized: "studio.change_proposal.intent_view", defaultValue: "Clarify flow, visual truth, or behavior coverage for %@ before any authoring step.")
    static let proposalAcceptanceComponentTemplate = String(localized: "studio.change_proposal.acceptance_component", defaultValue: "Keep coverage at %@ or better and preserve current state catalog semantics.")
    static let proposalAcceptanceViewTemplate = String(localized: "studio.change_proposal.acceptance_view", defaultValue: "Preserve %@ behavior and re-check current navigation depth and coverage after the proposal is applied.")
    static let graphNodesCaption = String(localized: "studio.navigation.graph_nodes_caption", defaultValue: "Nodes currently in the exported flow graph")
    static let graphEdgesCaption = String(localized: "studio.navigation.graph_edges_caption", defaultValue: "Push, sheet, replace, and pop transitions")
    static let graphRootCaption = String(localized: "studio.navigation.graph_root_caption", defaultValue: "Primary entry route for the current bundle")
    static let proposalMarkdownTitle = String(localized: "studio.change_proposal.markdown_title", defaultValue: "Change Proposal")
    static let proposalMarkdownScopeHeading = String(localized: "studio.change_proposal.markdown_scope_heading", defaultValue: "Scope")
    static let proposalMarkdownRequestedHeading = String(localized: "studio.change_proposal.markdown_requested_heading", defaultValue: "Requested Change")
    static let proposalMarkdownStructuredTargetsHeading = String(localized: "studio.change_proposal.markdown_structured_targets_heading", defaultValue: "Structured Targets")
    static let proposalMarkdownAcceptanceHeading = String(localized: "studio.change_proposal.markdown_acceptance_heading", defaultValue: "Acceptance Notes")
    static let proposalMarkdownRecheckNote = String(localized: "studio.change_proposal.markdown_recheck_note", defaultValue: "Re-check the matching native inspector and current preview contract after the change lands.")

    static func importingFileNamed(_ name: String) -> String {
        String(localized: "studio.status.importing_file_named", defaultValue: "Importing \(name)…")
    }

    static func referencesCount(_ count: Int) -> String {
        String(localized: "studio.foundation.references_count", defaultValue: "\(count) references")
    }

    static func componentsCount(_ count: Int) -> String {
        String(localized: "studio.foundation.components_count", defaultValue: "\(count) components")
    }

    static func itemsCount(_ count: Int) -> String {
        String(localized: "studio.foundation.items_count", defaultValue: "\(count) items")
    }

    static func points(_ value: Int) -> String {
        String(localized: "studio.foundation.points", defaultValue: "\(value) pt")
    }

    static func statesCount(_ count: Int) -> String {
        String(localized: "studio.content.states_count", defaultValue: "\(count) states")
    }

    static func viewsCount(_ count: Int) -> String {
        String(localized: "studio.content.views_count", defaultValue: "\(count) views")
    }

    static func linksCount(_ count: Int) -> String {
        String(localized: "studio.content.links_count", defaultValue: "\(count) links")
    }

    static func defaultStateValue(_ value: String) -> String {
        String(localized: "studio.content.default_state_value", defaultValue: "Default: \(value)")
    }

    static func fallbackValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? none : value
    }

    static func readableLabel(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed.lowercased() {
        case "":
            return none
        case "swiftui":
            return swiftUILabel
        case "uikit":
            return String(localized: "studio.content.renderer.uikit", defaultValue: "UIKit")
        default:
            return trimmed
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    static func rendererLabel(_ rawValue: String) -> String {
        readableLabel(rawValue)
    }

    static func foundationGroupLabel(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "color", "colors", "gradient", "gradients", "spacing", "cornerradius", "corner-radius", "corner_radius":
            return foundationTokenKindLabel(rawValue)
        default:
            return readableLabel(rawValue)
        }
    }

    static func designTokenCategoryLabel(_ rawValue: String) -> String {
        foundationGroupLabel(rawValue)
    }

    static func stateValue(_ value: String) -> String {
        String(localized: "studio.content.state_value", defaultValue: "State: \(value)")
    }

    static func depthValue(_ depth: Int) -> String {
        String(localized: "studio.navigation.depth_value", defaultValue: "Depth \(depth)")
    }

    static func viewCountSummary(_ count: Int) -> String {
        String(localized: "studio.navigation.view_count_summary", defaultValue: "\(count) views")
    }

    static func resultsCount(_ count: Int) -> String {
        String(localized: "common.results_count", defaultValue: "\(count) results")
    }

    static func proposalEvidenceSummary(count: Int, firstItem: String) -> String {
        String(localized: "studio.change_proposal.evidence_summary", defaultValue: "\(count) evidence sources, starting with \(firstItem)")
    }
    static func proposalDiffContextSummary(_ diffSignal: String, _ touchpoints: String) -> String {
        let trimmedSignal = diffSignal.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTouchpoints = touchpoints.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSignal.isEmpty {
            return trimmedTouchpoints.isEmpty ? notAvailableYet : trimmedTouchpoints
        }
        if trimmedTouchpoints.isEmpty {
            return trimmedSignal
        }
        return String(localized: "studio.change_proposal.diff_context_summary", defaultValue: "\(trimmedSignal) · \(trimmedTouchpoints)")
    }
    static let proposalMarkdownDiffSignalLabel = String(localized: "studio.change_proposal.markdown_diff_signal_label", defaultValue: "Diff signal")
    static let proposalMarkdownTouchpointsLabel = String(localized: "studio.change_proposal.markdown_touchpoints_label", defaultValue: "Touchpoints")
    static let proposalDiffSignalComponent = String(localized: "studio.change_proposal.diff_signal_component", defaultValue: "Component contract + preview coverage")
    static let proposalDiffSignalView = String(localized: "studio.change_proposal.diff_signal_view", defaultValue: "View flow + navigation coverage")

    static func colorTokenSummary(_ group: String) -> String {
        String(localized: "studio.foundation.color_token_summary", defaultValue: "Color token · \(group)")
    }

    static func gradientTokenSummary(_ group: String) -> String {
        String(localized: "studio.foundation.gradient_token_summary", defaultValue: "Gradient token · \(group)")
    }

    static func iconSummary(_ symbol: String) -> String {
        String(localized: "studio.foundation.icon_summary", defaultValue: "Icon · \(symbol)")
    }

    static func typographySummary(points: Int) -> String {
        String(localized: "studio.foundation.typography_summary", defaultValue: "Typography · \(points) pt")
    }

    static func typographyContext(points: Int, swiftUI: String) -> String {
        String(format: String(localized: "studio.foundation.typography_context", defaultValue: "%lld pt · %@"), locale: Locale.current, points, swiftUI)
    }

    static func typographyScaleWeight(points: Int, weight: String) -> String {
        String(format: String(localized: "studio.foundation.typography_scale_weight", defaultValue: "%lld pt · %@"), locale: Locale.current, points, weight)
    }

    static func spacingSummary(_ value: String) -> String {
        String(localized: "studio.foundation.spacing_summary", defaultValue: "Spacing · \(value)")
    }

    static func cornerRadiusSummary(_ value: String) -> String {
        String(localized: "studio.foundation.corner_radius_summary", defaultValue: "Corner radius · \(value)")
    }

    static func componentSummary(_ group: String) -> String {
        String(localized: "studio.content.component_summary", defaultValue: "Component · \(group)")
    }

    static func viewSummary(_ presentation: String) -> String {
        String(localized: "studio.content.view_summary", defaultValue: "View · \(navigationKindLabel(presentation))")
    }

    static func navigationFlowSummary(outgoingCount: Int) -> String {
        String(localized: "studio.navigation.flow_summary", defaultValue: "Navigation flow · \(outgoingCount) outgoing edges")
    }

    static func incomingCountShort(_ count: Int) -> String {
        String(localized: "studio.navigation.incoming_count_short", defaultValue: "\(count) \(incomingShort)")
    }

    static func outgoingCountShort(_ count: Int) -> String {
        String(localized: "studio.navigation.outgoing_count_short", defaultValue: "\(count) \(outgoingShort)")
    }

    static func componentsCountShort(_ count: Int) -> String {
        String(localized: "studio.content.components_count_short", defaultValue: "\(count) \(componentsShort)")
    }

    static func proposalExportedFile(_ fileName: String) -> String {
        String(localized: "studio.change_proposal.exported_file", defaultValue: "Proposal exported: \(fileName)")
    }

    static func repoProposalSavedFile(_ fileName: String) -> String {
        String(localized: "studio.change_proposal.repo_saved_file", defaultValue: "Proposal saved in repo: \(fileName)")
    }

    static func repoProposalFailedReason(_ reason: String) -> String {
        String(localized: "studio.change_proposal.repo_failed_reason", defaultValue: "Unable to save proposal in repo: \(reason)")
    }

    static func proposalNavigationChecklist(_ presentation: String, _ stackContext: String) -> String {
        String(localized: "studio.change_proposal.navigation_checklist", defaultValue: "Preserve \(presentation) behavior and keep the current \(stackContext) preview contract honest.")
    }

    static func componentNoTruthReason() -> String {
        String(localized: "studio.review.component_no_truth_reason", defaultValue: "No reference snapshot is exported and the native inspector also has no declared state catalog to lean on yet.")
    }

    static func componentMissingSnapshotReason() -> String {
        String(localized: "studio.review.component_missing_snapshot_reason", defaultValue: "The component has declared states, but there is still no exported reference snapshot to confirm visual truth.")
    }

    static func componentFullyBackedReason() -> String {
        String(localized: "studio.review.component_fully_backed_reason", defaultValue: "This component is fully backed by exported truth.")
    }

    static func viewMissingSnapshotReason() -> String {
        String(localized: "studio.review.view_missing_snapshot_reason", defaultValue: "The screen has flow and component metadata, but no exported reference snapshot yet, so visual truth still needs review.")
    }

    static func viewFullyBackedReason() -> String {
        String(localized: "studio.review.view_fully_backed_reason", defaultValue: "This view is fully backed by exported truth.")
    }

    static func proposalIntentComponent(_ name: String) -> String {
        String(format: proposalIntentComponentTemplate, locale: Locale.current, name)
    }

    static func proposalIntentView(_ name: String) -> String {
        String(format: proposalIntentViewTemplate, locale: Locale.current, name)
    }

    static func proposalAcceptanceComponent(_ coverage: String) -> String {
        String(format: proposalAcceptanceComponentTemplate, locale: Locale.current, coverage)
    }

    static func proposalAcceptanceView(_ presentation: String) -> String {
        String(format: proposalAcceptanceViewTemplate, locale: Locale.current, presentation)
    }

    static func previewCoverageLabel(_ level: StudioPreviewCoverageLevel) -> String {
        switch level {
        case .exact:
            return exact
        case .contractDriven:
            return contractDriven
        case .fallbackNeeded:
            return fallbackNeeded
        }
    }

    static func previewCoverageCount(_ count: Int, level: StudioPreviewCoverageLevel) -> String {
        String(
            format: String(localized: "studio.preview_coverage.count", defaultValue: "%lld %@"),
            locale: Locale.current,
            count,
            previewCoverageLabel(level)
        )
    }

    static func previewDeviceName(_ id: String) -> String {
        switch id {
        case "iphone-compact":
            return String(localized: "studio.preview.device.iphone_compact.name", defaultValue: "iPhone Compact")
        case "iphone-plus":
            return String(localized: "studio.preview.device.iphone_plus.name", defaultValue: "iPhone Plus")
        case "ipad-portrait":
            return String(localized: "studio.preview.device.ipad_portrait.name", defaultValue: "iPad Portrait")
        default:
            return id
        }
    }

    static func previewDeviceNotes(_ id: String) -> String {
        switch id {
        case "iphone-compact":
            return String(localized: "studio.preview.device.iphone_compact.note", defaultValue: "Phone-first compact viewport for everyday navigation and sheet checks.")
        case "iphone-plus":
            return String(localized: "studio.preview.device.iphone_plus.note", defaultValue: "Larger phone viewport for dense content and action spacing checks.")
        case "ipad-portrait":
            return String(localized: "studio.preview.device.ipad_portrait.note", defaultValue: "Tablet viewport for split layouts, popovers, and longer reading flows.")
        default:
            return id
        }
    }

    static func previewOrientationLabel(_ orientation: StudioPreviewOrientation) -> String {
        switch orientation {
        case .portrait:
            return String(localized: "studio.preview.orientation.portrait", defaultValue: "Portrait")
        case .landscape:
            return String(localized: "studio.preview.orientation.landscape", defaultValue: "Landscape")
        }
    }

    static func previewPresentationModeLabel(_ mode: StudioPreviewPresentationMode) -> String {
        switch mode {
        case .push:
            return push
        case .sheet:
            return sheet
        case .fullScreenCover:
            return previewFullScreen
        }
    }

    static func previewNavigationChromeLabel(_ chrome: StudioPreviewNavigationChrome) -> String {
        switch chrome {
        case .none:
            return previewNone
        case .navigationBar:
            return previewNavigationChrome
        case .tabBar:
            return previewTabBar
        case .both:
            return previewBoth
        }
    }

    static func previewNavigationDepthLabel(_ depth: StudioPreviewNavigationDepth) -> String {
        switch depth {
        case .root:
            return rootLabel
        case .detail:
            return previewBreadcrumbDetail
        case .deep:
            return previewDeepLink
        }
    }

    static func previewModalLayeringLabel(_ layering: StudioPreviewModalLayering) -> String {
        switch layering {
        case .inline:
            return previewInline
        case .elevated:
            return previewElevated
        case .blocking:
            return previewBlocking
        }
    }

    static func foundationTokenKindLabel(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "gradient":
            return String(localized: "studio.foundation.kind.gradient", defaultValue: "Gradient")
        case "lineargradient", "linear-gradient", "linear_gradient":
            return String(localized: "studio.foundation.kind.linear_gradient", defaultValue: "Linear Gradient")
        case "radialgradient", "radial-gradient", "radial_gradient":
            return String(localized: "studio.foundation.kind.radial_gradient", defaultValue: "Radial Gradient")
        case "cornerradius", "corner-radius", "corner_radius":
            return cornerRadius
        case "spacing":
            return spacing
        case "color":
            return colors
        default:
            return readableLabel(rawValue)
        }
    }

    static func previewStackContextLabel(_ context: StudioPreviewStackContext) -> String {
        switch context {
        case .single:
            return String(localized: "studio.preview.stack.single", defaultValue: "Single Screen")
        case .stacked:
            return String(localized: "studio.preview.stack.stacked", defaultValue: "Stacked Flow")
        case .branched:
            return String(localized: "studio.preview.stack.branched", defaultValue: "Branched Flow")
        }
    }

    static func previewStackContextSummary(_ context: StudioPreviewStackContext) -> String {
        switch context {
        case .single:
            return String(localized: "studio.preview.stack.single.summary", defaultValue: "Inspecting one isolated surface without surrounding flow baggage.")
        case .stacked:
            return String(localized: "studio.preview.stack.stacked.summary", defaultValue: "Inspecting a screen inside a straightforward parent-child navigation stack.")
        case .branched:
            return String(localized: "studio.preview.stack.branched.summary", defaultValue: "Inspecting a screen inside a larger flow with alternate routes, overlays, or exits.")
        }
    }

    static func previewBreadcrumbLabels(_ context: StudioPreviewStackContext) -> [String] {
        switch context {
        case .single:
            return [current]
        case .stacked:
            return [home, previewBreadcrumbDetail, current]
        case .branched:
            return [home, previewBreadcrumbFlow, previewBreadcrumbReview, current]
        }
    }

    static func previewCoverageSummary(_ level: StudioPreviewCoverageLevel) -> String {
        switch level {
        case .exact:
            return String(localized: "studio.preview_coverage.exact.summary", defaultValue: "Reference-backed preview with strong exported visual truth.")
        case .contractDriven:
            return String(localized: "studio.preview_coverage.contract_driven.summary", defaultValue: "Behavior is modeled natively from the contract, but still approximated.")
        case .fallbackNeeded:
            return String(localized: "studio.preview_coverage.fallback_needed.summary", defaultValue: "Native preview is still incomplete here and may require fallback inspection.")
        }
    }

    static func previewLayoutModeLabel(_ mode: StudioPreviewLayoutMode) -> String {
        switch mode {
        case .regular:
            return previewFit
        case .focus:
            return previewFocus
        }
    }

    static func previewSizeClassLabel(_ sizeClass: StudioPreviewSizeClass) -> String {
        switch sizeClass {
        case .compact:
            return previewCompact
        case .regular:
            return previewRegular
        }
    }

    static let previewSafeArea = String(localized: "studio.preview.safe_area", defaultValue: "Safe area insets")
    static let previewContractDerivedFromModel = String(localized: "studio.preview.contract_note.default", defaultValue: "This preview is driven by native contract data rather than a live runtime capture.")
    static let previewProposalInferenceNote = String(localized: "studio.preview.contract_note.proposal_inference", defaultValue: "Proposal apply preview infers its flow context from saved scope and evidence, not from a live runtime navigation session.")
    static let previewNavigationGraphNote = String(localized: "studio.preview.contract_note.navigation_graph", defaultValue: "Flow context is derived from the exported navigation graph and matches the currently known route structure.")
    static let previewNavigationGraphApproximationNote = String(localized: "studio.preview.contract_note.navigation_graph_approximation", defaultValue: "Flow context is derived from the exported navigation graph, but visual behavior still remains partly contract-driven.")
    static let previewComponentUsageInferenceNote = String(localized: "studio.preview.contract_note.component_usage", defaultValue: "Component flow context is inferred from usage relationships rather than a screen-level runtime path.")

    static func previewSafeAreaInsets(top: Int, bottom: Int, horizontal: Int) -> String {
        String(
            format: String(
                localized: "studio.preview.safe_area_insets",
                defaultValue: "Top %lld pt · Bottom %lld pt · Horizontal %lld pt"
            ),
            locale: Locale.current,
            top,
            bottom,
            horizontal
        )
    }

    static func previewBreadcrumbTrailSummary(_ labels: [String]) -> String {
        let cleaned = labels
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else {
            return notAvailableYet
        }
        return cleaned.joined(separator: " -> ")
    }

    static func previewFlowProgressSummary(currentStep: Int?, totalSteps: Int?) -> String {
        guard let currentStep else {
            return notAvailableYet
        }
        if let totalSteps {
            return String(
                format: String(localized: "studio.preview.flow_progress_value", defaultValue: "Step %1$lld of %2$lld"),
                locale: Locale.current,
                currentStep,
                totalSteps
            )
        }
        return String(
            format: String(localized: "studio.preview.flow_progress_current_only", defaultValue: "Step %lld"),
            locale: Locale.current,
            currentStep
        )
    }

    static func previewModalContextSummary(
        depth: Int,
        presentationMode: StudioPreviewPresentationMode,
        layering: StudioPreviewModalLayering
    ) -> String {
        let normalizedDepth = max(depth, 1)
        if presentationMode == .push {
            return String(localized: "studio.preview.modal_context.inline_route", defaultValue: "No extra modal layer is modeled beyond the active route.")
        }
        return String(
            format: String(
                localized: "studio.preview.modal_context.layered_value",
                defaultValue: "%1$lld visible layers with %2$@ presentation and %3$@ layering."
            ),
            locale: Locale.current,
            normalizedDepth,
            previewPresentationModeLabel(presentationMode).lowercased(),
            previewModalLayeringLabel(layering).lowercased()
        )
    }

    static func previewStepBadge(currentStep: Int, totalSteps: Int?) -> String {
        if let totalSteps {
            return String(
                format: String(localized: "studio.preview.step_badge", defaultValue: "Step %1$lld/%2$lld"),
                locale: Locale.current,
                currentStep,
                totalSteps
            )
        }
        return String(
            format: String(localized: "studio.preview.step_badge_current_only", defaultValue: "Step %lld"),
            locale: Locale.current,
            currentStep
        )
    }

    static func previewLayerBadge(_ depth: Int) -> String {
        String(
            format: String(localized: "studio.preview.layer_badge", defaultValue: "%lld layers"),
            locale: Locale.current,
            max(depth, 1)
        )
    }

    static func previewSizeClassesValue(horizontal: StudioPreviewSizeClass, vertical: StudioPreviewSizeClass) -> String {
        String(
            format: String(localized: "studio.preview.size_classes_value", defaultValue: "H %@ · V %@"),
            locale: Locale.current,
            previewSizeClassLabel(horizontal),
            previewSizeClassLabel(vertical)
        )
    }

    static func previewContractSummary(
        deviceName: String,
        orientation: StudioPreviewOrientation,
        presentationMode: StudioPreviewPresentationMode,
        navigationChrome: StudioPreviewNavigationChrome,
        navigationDepth: StudioPreviewNavigationDepth,
        stackContext: StudioPreviewStackContext
    ) -> String {
        [
            deviceName,
            previewOrientationLabel(orientation),
            previewPresentationModeLabel(presentationMode),
            previewNavigationChromeLabel(navigationChrome),
            previewNavigationDepthLabel(navigationDepth),
            previewStackContextLabel(stackContext)
        ].joined(separator: " · ")
    }

    static func previewBehaviorSummary(
        presentationMode: StudioPreviewPresentationMode,
        navigationChrome: StudioPreviewNavigationChrome,
        navigationDepth: StudioPreviewNavigationDepth,
        modalLayering: StudioPreviewModalLayering,
        stackContext: StudioPreviewStackContext
    ) -> String {
        String(
            format: String(
                localized: "studio.preview.behavior_summary",
                defaultValue: "%1$@ flow with %2$@ chrome, %3$@ route depth, %4$@ layering, and a %5$@ context."
            ),
            locale: Locale.current,
            previewPresentationModeLabel(presentationMode),
            previewNavigationChromeLabel(navigationChrome).lowercased(),
            previewNavigationDepthLabel(navigationDepth).lowercased(),
            previewModalLayeringLabel(modalLayering).lowercased(),
            previewStackContextLabel(stackContext).lowercased()
        )
    }

    static func navigationKindLabel(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "push":
            return push
        case "sheet":
            return sheet
        case "replace":
            return replace
        case "root":
            return rootLabel
        default:
            return readableLabel(rawValue)
        }
    }

    static func navigationEdgeLabel(type: String, trigger: String) -> String {
        let trimmedTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = navigationKindLabel(type)
        guard !trimmedTrigger.isEmpty else {
            return kind
        }
        return String(localized: "studio.navigation.transition_via", defaultValue: "\(kind) via \(trimmedTrigger)")
    }

    static func destinationTitle(_ destination: StudioNativeDestination) -> String {
        switch destination {
        case .overview: return String(localized: "studio.destination.overview", defaultValue: "Overview")
        case .tokens: return String(localized: "studio.destination.tokens", defaultValue: "Tokens")
        case .components: return components
        case .views: return views
        case .review: return reviewQueueTitle
        case .navigation: return navigationMap
        case .proposals: return proposalWorkspaceTitle
        case .icons: return String(localized: "studio.destination.icons", defaultValue: "Icons")
        case .typography: return String(localized: "studio.destination.typography", defaultValue: "Typography")
        case .spacing: return String(localized: "studio.destination.spacing", defaultValue: "Spacing & Radius")
        case .legacyWeb: return String(localized: "studio.destination.legacy_web", defaultValue: "Legacy Web Inspector")
        }
    }

    static func destinationSubtitle(_ destination: StudioNativeDestination) -> String {
        switch destination {
        case .overview:
            return String(localized: "studio.destination.overview_subtitle", defaultValue: "Native foundations workspace for imported design exports.")
        case .tokens:
            return String(localized: "studio.destination.tokens_subtitle", defaultValue: "Colors and gradients rendered directly in SwiftUI.")
        case .components:
            return String(localized: "studio.destination.components_subtitle", defaultValue: "Snapshot-first component catalog rendered natively.")
        case .views:
            return String(localized: "studio.destination.views_subtitle", defaultValue: "Screen catalog with snapshot and flow truth, rendered natively.")
        case .review:
            return String(localized: "studio.destination.review_subtitle", defaultValue: "Native queue for components and views whose exported truth is degraded or still needs fallback review.")
        case .navigation:
            return String(localized: "studio.destination.navigation_subtitle", defaultValue: "Native flow map over exported navigation edges, root routing, and behavior coverage.")
        case .proposals:
            return String(localized: "studio.destination.proposals_subtitle", defaultValue: "Repository-aware proposal workspace with native filters, recovery, and scope linkage.")
        case .icons:
            return String(localized: "studio.destination.icons_subtitle", defaultValue: "Native icon catalog sourced from the imported bundle.")
        case .typography:
            return String(localized: "studio.destination.typography_subtitle", defaultValue: "Type styles decoded from the export contract.")
        case .spacing:
            return String(localized: "studio.destination.spacing_subtitle", defaultValue: "Padding and corner radius tokens rendered natively.")
        case .legacyWeb:
            return String(localized: "studio.destination.legacy_web_subtitle", defaultValue: "Fallback-only web inspector for parity gaps, write-back workflows, and unresolved native detail.")
        }
    }
}
