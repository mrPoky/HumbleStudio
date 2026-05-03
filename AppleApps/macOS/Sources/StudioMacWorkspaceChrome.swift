import SwiftUI

struct StudioMacWorkspaceSidebar: View {
    let document: StudioNativeDocument?
    let selection: Binding<StudioNativeDestination?>
    let reviewQueueCount: Int?
    let navigationEdgeCount: Int?

    var body: some View {
        List(selection: selection) {
            Section(StudioStrings.nativeSection) {
                sidebarRow(.overview)
                sidebarRow(.tokens, count: document.map { $0.colors.count + $0.gradients.count })
                sidebarRow(.components, count: document?.components.count)
                sidebarRow(.views, count: document?.views.count)
                sidebarRow(.review, count: reviewQueueCount)
                sidebarRow(.navigation, count: navigationEdgeCount)
                sidebarRow(.proposals)
                sidebarRow(.icons, count: document?.icons.count)
                sidebarRow(.typography, count: document?.typography.count)
                sidebarRow(.spacing, count: document.map { $0.spacing.count + $0.radius.count })
            }

            Section(StudioStrings.fallbackSection) {
                sidebarRow(.legacyWeb)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 230, ideal: 250)
    }

    private func sidebarRow(_ destination: StudioNativeDestination, count: Int? = nil) -> some View {
        let tone = StudioMacParityResolver.tone(for: destination, document: document)
        return HStack(spacing: 10) {
            Image(systemName: destination.symbolName)
                .foregroundStyle(sidebarIconColor(for: tone))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.title)
                    .lineLimit(1)
                Text(destination.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let count {
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.55), in: Capsule())
                    .foregroundStyle(.secondary)
            } else if destination != .overview {
                Text(tone.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sidebarIconColor(for: tone).opacity(0.12), in: Capsule())
                    .foregroundStyle(sidebarIconColor(for: tone))
            }
        }
        .tag(destination)
    }

    private func sidebarIconColor(for tone: StudioMacParityTone) -> Color {
        switch tone {
        case .exact:
            return .green
        case .degraded:
            return .orange
        case .fallbackOnly:
            return .red
        }
    }
}

struct StudioMacWorkspaceContextBar: View {
    let eyebrow: String?
    let title: String
    let subtitle: String
    let previousLabel: String?
    let sourceSummary: String
    let sourceKind: String
    let recoveryReadiness: String
    let recoveryTone: String
    let parityLabel: String?
    let parityTone: StudioMacParityTone?
    let statusLevel: String
    let statusText: String
    let navigateBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if let eyebrow {
                        Text(eyebrow)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .lineLimit(1)
                    }
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                if let previousLabel {
                    Button {
                        navigateBack()
                    } label: {
                        Label(previousLabel, systemImage: "chevron.backward")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .help("Back to \(previousLabel)")
                }

                Label(sourceSummary, systemImage: "shippingbox")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.45), in: Capsule())
                    .foregroundStyle(.secondary)

                StudioMacWorkspaceMetaChip(
                    text: sourceKind,
                    systemImage: "tray.full",
                    tone: .neutral
                )

                StudioMacWorkspaceMetaChip(
                    text: recoveryReadiness,
                    systemImage: "arrow.clockwise.circle",
                    tone: recoveryTone == "ok" ? .success : .warning
                )

                if let parityLabel, let parityTone {
                    StudioMacWorkspaceMetaChip(
                        text: "\(StudioStrings.parityStatus): \(parityLabel)",
                        systemImage: "square.grid.3x2",
                        tone: parityMetaTone(for: parityTone)
                    )
                }

                StudioMacWorkspaceStatusChip(
                    statusLevel: statusLevel,
                    statusText: statusText
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .opacity(0.35)
        }
        .background(.thinMaterial)
    }

    private func parityMetaTone(for tone: StudioMacParityTone) -> StudioMacWorkspaceMetaChip.Tone {
        switch tone {
        case .exact:
            return .success
        case .degraded, .fallbackOnly:
            return .warning
        }
    }
}

struct StudioMacWorkspaceContextChrome: View {
    let context: StudioMacWorkspaceContextSnapshot
    let status: StudioMacWorkspaceStatusSnapshot
    let navigateBack: () -> Void

    var body: some View {
        StudioMacWorkspaceContextBar(
            eyebrow: context.eyebrow,
            title: context.title,
            subtitle: context.subtitle,
            previousLabel: context.previousLabel,
            sourceSummary: status.sourceSummary,
            sourceKind: status.sourceKind,
            recoveryReadiness: status.recoveryReadiness,
            recoveryTone: status.recoveryTone,
            parityLabel: status.parityLabel,
            parityTone: status.parityTone,
            statusLevel: status.statusLevel,
            statusText: status.statusText,
            navigateBack: navigateBack
        )
    }
}

struct StudioMacWorkspaceDetailContent: View {
    let model: StudioShellModel
    let selection: StudioNativeDestination?
    @Binding var selectedTokenSelection: StudioNativeTokenSelection?
    @Binding var componentAppearance: StudioNativeAppearance
    @Binding var viewAppearance: StudioNativeAppearance
    @Binding var selectedComponentID: String?
    @Binding var selectedViewID: String?
    @Binding var selectedNavigationViewID: String?
    @Binding var selectedIconID: String?
    @Binding var selectedTypographyID: String?
    @Binding var selectedMetricSelection: StudioNativeMetricSelection?
    let inspectComponent: (String) -> Void
    let inspectView: (String) -> Void

    var body: some View {
        switch selection ?? .overview {
        case .overview:
            StudioMacOverviewPage(model: model)
        case .tokens:
            StudioMacTokensPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                selection: $selectedTokenSelection,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .components:
            StudioMacComponentsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $componentAppearance,
                selectedComponentID: $selectedComponentID,
                inspectView: inspectView
            )
        case .views:
            StudioMacViewsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                appearance: $viewAppearance,
                selectedViewID: $selectedViewID,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .review:
            StudioMacReviewPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .navigation:
            StudioMacNavigationPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                selectedViewID: $selectedNavigationViewID,
                inspectView: inspectView
            )
        case .proposals:
            StudioMacProposalArtifactsPage(
                document: model.nativeDocument,
                inspectComponent: inspectComponent,
                inspectView: inspectView
            )
        case .icons:
            StudioMacIconsPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                selection: $selectedIconID
            )
        case .typography:
            StudioMacTypographyPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView,
                selection: $selectedTypographyID
            )
        case .spacing:
            StudioMacSpacingPage(
                document: model.nativeDocument,
                nativeErrorMessage: model.nativeErrorMessage,
                inspectComponent: inspectComponent,
                inspectView: inspectView,
                selection: $selectedMetricSelection
            )
        case .legacyWeb:
            StudioMacLegacyWebFallback(model: model)
        }
    }
}

private struct StudioMacWorkspaceMetaChip: View {
    enum Tone {
        case neutral
        case success
        case warning
    }

    let text: String
    let systemImage: String
    let tone: Tone

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var foreground: Color {
        switch tone {
        case .neutral:
            return .secondary
        case .success:
            return .green
        case .warning:
            return .orange
        }
    }

    private var background: Color {
        switch tone {
        case .neutral:
            return .secondary.opacity(0.12)
        case .success:
            return .green.opacity(0.14)
        case .warning:
            return .orange.opacity(0.14)
        }
    }
}

private struct StudioMacWorkspaceStatusChip: View {
    let statusLevel: String
    let statusText: String

    var body: some View {
        HStack(spacing: 8) {
            if statusLevel == "loading" {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: statusSymbolName)
                    .font(.caption.weight(.semibold))
            }

            Text(statusText)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusBackground, in: Capsule())
        .foregroundStyle(statusForeground)
    }

    private var statusSymbolName: String {
        switch statusLevel {
        case "ok":
            return "checkmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "err":
            return "xmark.octagon.fill"
        default:
            return "circle.fill"
        }
    }

    private var statusForeground: Color {
        switch statusLevel {
        case "ok":
            return .green
        case "warn":
            return .orange
        case "err":
            return .red
        default:
            return .secondary
        }
    }

    private var statusBackground: Color {
        switch statusLevel {
        case "ok":
            return .green.opacity(0.14)
        case "warn":
            return .orange.opacity(0.14)
        case "err":
            return .red.opacity(0.14)
        default:
            return .secondary.opacity(0.12)
        }
    }
}

struct StudioMacLegacyWebFallback: View {
    @ObservedObject var model: StudioShellModel

    var body: some View {
        ZStack {
            StudioWebView(model: model)

            VStack {
                HStack {
                    Spacer(minLength: 0)
                    StudioMacLegacyFallbackStatusCard(model: model)
                        .frame(maxWidth: 360)
                }
                Spacer(minLength: 0)
            }
            .padding(24)

            if let errorMessage = model.errorMessage {
                ContentUnavailableView(
                    StudioStrings.unableToLoadLegacyInspector,
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StudioMacLegacyFallbackStatusCard: View {
    @ObservedObject var model: StudioShellModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(StudioStrings.legacyFallbackTitle)
                        .font(.headline)
                    Text(statusSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(statusBadge)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                StudioKeyValueRow(label: StudioStrings.currentSource, value: model.sourceSummary)
                StudioKeyValueRow(label: StudioStrings.nativeStatus, value: nativeStatusText)
                StudioKeyValueRow(label: StudioStrings.bestUse, value: "Fallback for parity gaps, unresolved native detail, and future authoring/write-back workflows.")
            }

            if let nativeErrorMessage = model.nativeErrorMessage, !nativeErrorMessage.isEmpty {
                Text(nativeErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.75), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
    }

    private var nativeStatusText: String {
        if let nativeErrorMessage = model.nativeErrorMessage, !nativeErrorMessage.isEmpty {
            return "Native import has issues: \(nativeErrorMessage)"
        }
        if model.nativeDocument != nil {
            return "Native bundle truth is loaded; fallback is optional support."
        }
        return "Native document is not loaded yet."
    }

    private var statusSummary: String {
        if model.nativeDocument != nil {
            return "Native coverage exists for the main inspector surfaces. Use this path when you need the older web behavior or a parity escape hatch."
        }
        return "This fallback is currently carrying the session because native truth is missing or still recovering."
    }

    private var statusBadge: String {
        model.nativeDocument != nil ? StudioStrings.support : StudioStrings.primary
    }

    private var statusColor: Color {
        model.nativeDocument != nil ? .green : .orange
    }
}

struct StudioMacOverviewPage: View {
    @ObservedObject var model: StudioShellModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let document = model.nativeDocument {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.appName)
                            .font(.system(size: 32, weight: .bold))
                        if !document.appDescription.isEmpty {
                            Text(document.appDescription)
                                .foregroundStyle(.secondary)
                        }
                        if !document.appVersion.isEmpty {
                            Text("v\(document.appVersion)")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary.opacity(0.55), in: Capsule())
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                        StudioCountCard(title: "Tokens", value: "\(document.colors.count + document.gradients.count)", caption: "Colors and gradients")
                        StudioCountCard(title: "Components", value: "\(document.components.count)", caption: "Native dashboard now reads snapshots from the bundle")
                        StudioCountCard(title: "Views", value: "\(document.views.count)", caption: "Native screen catalog with snapshot-first previews")
                        StudioCountCard(title: "Navigation", value: "\(document.views.reduce(0) { $0 + $1.navigatesTo.count })", caption: "Flow edges derived from the exported contract")
                        StudioCountCard(title: "Icons", value: "\(document.icons.count)", caption: "Resolved from the bundle")
                        StudioCountCard(title: "Typography", value: "\(document.typography.count)", caption: "Type roles")
                        StudioCountCard(title: "Spacing & Radius", value: "\(document.spacing.count + document.radius.count)", caption: "Spatial tokens")
                    }

                    StudioMigrationCard(
                        title: StudioStrings.migrationStatusTitle,
                        message: StudioStrings.migrationStatusMessage
                    )

                    StudioMacSourceRecoveryCard(model: model)
                    StudioMacPreviewCoverageCard(document: document)
                    StudioMacNativeParityCard(document: document)
                } else if let nativeErrorMessage = model.nativeErrorMessage {
                    ContentUnavailableView(
                        StudioStrings.nativePreviewUnavailable,
                        systemImage: "exclamationmark.triangle",
                        description: Text(nativeErrorMessage)
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    ContentUnavailableView(
                        StudioStrings.loadDesignExport,
                        systemImage: "shippingbox",
                        description: Text(StudioStrings.loadNativeWorkspaceDescription)
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(24)
        }
    }
}

private struct StudioMacSourceRecoveryCard: View {
    @ObservedObject var model: StudioShellModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(StudioStrings.sourceRecoveryTitle)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                sourceCell(title: StudioStrings.currentSource, value: model.sourceSummary, tone: .neutral)
                sourceCell(title: StudioStrings.preferredRelaunch, value: preferredLaunchLabel, tone: .accent)
                sourceCell(title: StudioStrings.recommendedNextStep, value: model.recommendedRecoveryActionTitle, tone: model.nativeDocument != nil ? .success : .warning)
                sourceCell(title: StudioStrings.recentImport, value: model.recentImportName ?? StudioStrings.notAvailableYet, tone: model.hasRecentImport ? .success : .warning)
                sourceCell(title: StudioStrings.recentRemote, value: model.hasRecentRemoteURL ? trimmedRecentRemoteURL : StudioStrings.notAvailableYet, tone: model.hasRecentRemoteURL ? .success : .warning)
            }

            Text(model.recommendedRecoveryDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let nativeErrorMessage = model.nativeErrorMessage, !nativeErrorMessage.isEmpty {
                sourceCell(
                    title: model.nativeRecoveryIssue?.title ?? StudioStrings.currentIssue,
                    value: nativeErrorMessage,
                    tone: .warning
                )
            }

            HStack(spacing: 10) {
                Button(model.recommendedRecoveryActionTitle) {
                    performRecommendedAction()
                }
                .buttonStyle(.borderedProminent)

                if model.nativeDocument != nil || model.hasRecentImport || model.hasRecentRemoteURL {
                    Button(model.reloadActionLabel) {
                        model.reloadCurrentSource()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if model.hasRecentImport || model.hasRecentRemoteURL {
                HStack(spacing: 10) {
                    if model.hasRecentImport {
                        Button(StudioStrings.recentImport) {
                            model.reopenRecentImport()
                        }
                        .buttonStyle(.bordered)
                    }

                    if model.hasRecentRemoteURL {
                        Button(StudioStrings.recentRemoteURLButton) {
                            model.reopenRecentRemoteURL()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(StudioStrings.bundledStudio) {
                        model.loadBundledStudio()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !model.recoveryAlternativeActionTitles.isEmpty {
                HStack(spacing: 10) {
                    ForEach(model.recoveryAlternativeActionTitles, id: \.self) { actionTitle in
                        Button(actionTitle) {
                            model.performRecoveryAction(named: actionTitle)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }

    private func performRecommendedAction() {
        if model.hasRecentImport {
            model.reopenRecentImport()
            return
        }
        if model.hasRecentRemoteURL {
            model.reopenRecentRemoteURL()
            return
        }
        model.loadBundledStudio()
    }

    private func sourceCell(title: String, value: String, tone: StudioInspectorSummaryTone) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone.foreground)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var preferredLaunchLabel: String {
        switch model.preferredLaunchSource {
        case .bundled:
            return StudioStrings.bundledStudio
        case .demo:
            return "Demo source"
        case .recentImport:
            return StudioStrings.recentImport
        case .recentRemote:
            return StudioStrings.recentRemoteURLButton
        }
    }

    private var trimmedRecentRemoteURL: String {
        let raw = model.recentRemoteURL ?? ""
        return raw.count > 72 ? String(raw.prefix(69)) + "..." : raw
    }
}

private struct StudioMacPreviewCoverageCard: View {
    let document: StudioNativeDocument

    private var summary: StudioPreviewCoverageSummary {
        nativePreviewCoverageSummary(for: document)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(StudioStrings.previewCoverageTitle)
                        .font(.headline)
                    Text(StudioStrings.previewCoverageSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                StudioMacCoverageBadge(level: .exact, value: "\(summary.exact)")
                StudioMacCoverageBadge(level: .contractDriven, value: "\(summary.contractDriven)")
                StudioMacCoverageBadge(level: .fallbackNeeded, value: "\(summary.fallbackNeeded)")
            }

            StudioInspectorSummaryGrid(items: [
                StudioInspectorSummaryItem(
                    label: StudioStrings.exact,
                    value: "\(summary.exact)",
                    tone: .success
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.contractDriven,
                    value: "\(summary.contractDriven)",
                    tone: .warning
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.fallbackNeeded,
                    value: "\(summary.fallbackNeeded)",
                    tone: summary.fallbackNeeded > 0 ? .warning : .neutral
                ),
                StudioInspectorSummaryItem(
                    label: StudioStrings.totalPreviewable,
                    value: "\(summary.total)",
                    tone: .accent
                )
            ])

            Text(summaryNarrative)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }

    private var summaryNarrative: String {
        if summary.fallbackNeeded > 0 {
            return "\(summary.fallbackNeeded) native surfaces still need fallback help. The highest remaining risk is where exported visual truth and native behavior modeling are both still thin."
        }
        if summary.contractDriven > 0 {
            return "Fallback pressure is low, but \(summary.contractDriven) surfaces are still modeled from contract rather than fully reference-backed visual truth."
        }
        return "All currently imported component and view surfaces are reference-backed in native preview."
    }
}

private struct StudioMacNativeParityCard: View {
    let document: StudioNativeDocument

    private let nativeDestinations: [StudioNativeDestination] = [
        .tokens, .components, .views, .review, .navigation, .proposals, .icons, .typography, .spacing
    ]

    private var rows: [StudioMacParityEntry] {
        nativeDestinations.map { StudioMacParityEntry(destination: $0, tone: StudioMacParityResolver.tone(for: $0, document: document)) }
            + [StudioMacParityEntry(destination: .legacyWeb, tone: .fallbackOnly)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(StudioStrings.nativeParityMapTitle)
                        .font(.headline)
                    Text(StudioStrings.nativeParityMapSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                StudioMacParityBadge(label: "\(rows.filter { $0.tone == .exact }.count) \(StudioStrings.parityExactLabel)", tone: .exact)
                StudioMacParityBadge(label: "\(rows.filter { $0.tone == .degraded }.count) \(StudioStrings.parityDegradedLabel)", tone: .degraded)
                StudioMacParityBadge(label: "\(rows.filter { $0.tone == .fallbackOnly }.count) \(StudioStrings.parityFallbackLabel)", tone: .fallbackOnly)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(rows) { row in
                    StudioMacParityRow(
                        title: row.destination.title,
                        subtitle: paritySubtitle(for: row.destination, tone: row.tone),
                        symbolName: row.destination.symbolName,
                        tone: row.tone
                    )
                }
            }

            Text(parityNarrative)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }

    private func paritySubtitle(for destination: StudioNativeDestination, tone: StudioMacParityTone) -> String {
        switch destination {
        case .legacyWeb:
            return "Fallback path for parity gaps, missing native detail, and future write-back workflows."
        case .review:
            return "Queue truth is native, but it still surfaces degraded and fallback-risk areas explicitly."
        case .navigation:
            return "Navigation graph is native and contract-aware, with behavior edges still approximated where needed."
        case .proposals:
            return "Proposal artifacts are fully native here, with repo-aware filters, recovery, and scope linkage."
        case .typography:
            return tone == .exact ? "Type roles are evidence-backed and inspectable natively." : "Type roles are native-first, but some usage context is still contract-driven."
        case .spacing:
            return tone == .exact ? "Spacing and radius tokens are evidence-backed natively." : "Spatial tokens are inspectable natively, with some context still inferred from usage data."
        default:
            return destination.subtitle
        }
    }

    private var parityNarrative: String {
        let degradedCount = rows.filter { $0.tone == .degraded }.count
        if degradedCount > 0 {
            return "\(degradedCount) native surfaces are already first-class enough for everyday inspection, but still expose degraded areas where behavior or evidence is modeled instead of fully reference-backed."
        }
        return "Native inspection is broadly exact across the current imported bundle. Remaining fallback need is now mostly about future write-back authoring and long-tail parity edges."
    }
}

private struct StudioMacParityEntry: Identifiable {
    let destination: StudioNativeDestination
    let tone: StudioMacParityTone

    var id: StudioNativeDestination { destination }
}

private struct StudioMacParityRow: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tone: StudioMacParityTone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbolName)
                    .foregroundStyle(tone.foreground)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
            }

            StudioMacParityBadge(label: tone.label, tone: tone)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct StudioMacParityBadge: View {
    let label: String
    let tone: StudioMacParityTone

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tone.foreground.opacity(0.12), in: Capsule())
            .foregroundStyle(tone.foreground)
    }
}

private struct StudioMacCoverageBadge: View {
    let level: StudioPreviewCoverageLevel
    let value: String

    var body: some View {
        Label("\(value) \(level.rawValue)", systemImage: iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(level.color.opacity(0.12), in: Capsule())
            .foregroundStyle(level.color)
    }

    private var iconName: String {
        switch level {
        case .exact:
            return "checkmark.circle.fill"
        case .contractDriven:
            return "square.stack.3d.up.fill"
        case .fallbackNeeded:
            return "exclamationmark.triangle.fill"
        }
    }
}

private extension StudioMacParityTone {
    var foreground: Color {
        switch self {
        case .exact: return .green
        case .degraded: return .orange
        case .fallbackOnly: return .red
        }
    }

    var background: Color {
        switch self {
        case .exact: return .green.opacity(0.08)
        case .degraded: return .orange.opacity(0.10)
        case .fallbackOnly: return .red.opacity(0.10)
        }
    }
}

struct StudioMacRemoteURLSheet: View {
    @Binding var remoteURLDraft: String
    let recentRemoteURL: String?
    let hasRecentRemoteURL: Bool
    let dismiss: () -> Void
    let load: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(StudioStrings.remoteSource) {
                    TextField(
                        "https://raw.githubusercontent.com/user/repo/main/.humble/HumbleSudoku.humblebundle",
                        text: $remoteURLDraft,
                        axis: .vertical
                    )

                    Text(StudioStrings.remoteSourcePrompt)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if hasRecentRemoteURL, let recentRemoteURL {
                        Button {
                            remoteURLDraft = recentRemoteURL
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StudioStrings.useRecentURL)
                                Text(recentRemoteURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle(StudioStrings.openRemoteSourceTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(StudioStrings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(StudioStrings.load) {
                        let url = remoteURLDraft
                        dismiss()
                        load(url)
                    }
                    .disabled(remoteURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 540, minHeight: 250)
    }
}

struct StudioMacWorkspaceDropOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 28, weight: .semibold))
                    Text(StudioStrings.dropBundleTitle)
                        .font(.headline)
                    Text(StudioStrings.dropBundleSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(28)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.tint.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [10, 8]))
            )
            .padding(28)
    }
}
