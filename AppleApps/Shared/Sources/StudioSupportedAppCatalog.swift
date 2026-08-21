import SwiftUI

struct StudioSupportedAppSource: Identifiable, Equatable {
    let id: String
    let name: String
    let repo: String
    let sourceSummary: String
    let sourceKind: String
    let localExportPath: String
    let remoteURL: String
    let connectionMode: String
    let prepareEditMode: String
    let scopedPrepareEditPath: String
    let controlSessionPath: String
    let controlRecoveryPath: String
    let reviewArtifactPath: String
    let applyGateStatus: String
    let writesEnabled: Bool

    var sourceLabel: String {
        "\(name) · \(repo)"
    }

    var connectionSummary: String {
        "\(sourceKind) · \(connectionMode) · \(prepareEditMode)"
    }

    var scopedContractSummary: String {
        "\(scopedPrepareEditPath) · \(controlSessionPath)"
    }

    var controlWorkspacePath: String {
        "/studio/\(id)"
    }

    var launchIntentPath: String {
        controlWorkspacePath
    }

    var recoveryWizardPath: String {
        "\(controlWorkspacePath)#recovery"
    }

    var structuredDraftPath: String {
        "\(controlWorkspacePath)#structured-draft"
    }

    var patchPreviewPath: String {
        "\(controlWorkspacePath)#patch-preview"
    }

    var runtimeReadinessPath: String {
        "\(controlWorkspacePath)#runtime-readiness"
    }

    var proposalCenterPath: String {
        "\(controlWorkspacePath)#proposal-center"
    }

    var patchArtifactPath: String {
        "\(controlWorkspacePath)#patch-artifact"
    }

    var sandboxApplyPath: String {
        "\(controlWorkspacePath)#sandbox-apply"
    }

    var sourceApplyLockPath: String {
        "\(controlWorkspacePath)#source-apply-lock"
    }

    var trustLevelPath: String {
        "\(controlWorkspacePath)#trust"
    }

    var connectionRegistryPath: String {
        "\(controlWorkspacePath)#registry"
    }

    var nativeParityPath: String {
        "\(controlWorkspacePath)#native-parity"
    }

    var applyPreviewPath: String {
        "\(controlWorkspacePath)#apply-preview"
    }

    var editBoundaryPath: String {
        "\(controlWorkspacePath)#edit-boundary"
    }

    var safeApplyBoundaryPath: String {
        "\(controlWorkspacePath)#safe-apply"
    }

    var authoringSmokePath: String {
        "\(controlWorkspacePath)#smoke"
    }

    var reviewSummary: String {
        "\(reviewArtifactPath) · \(applyGateStatus)"
    }

    var sessionID: String {
        let normalized = id
            .lowercased()
            .map { character -> Character in
                character.isLetter || character.isNumber || character == "-" ? character : "-"
            }
        let value = String(normalized)
            .split(separator: "-")
            .joined(separator: "-")
        return "hs-\(value.isEmpty ? "app" : value)-read-only"
    }
}

enum StudioSupportedAppCatalog {
    static let all: [StudioSupportedAppSource] = [
        StudioSupportedAppSource(
            id: "humble-sudoku",
            name: "HumbleSudoku",
            repo: "mrPoky/HumbleSudoku",
            sourceSummary: ".humble/HumbleSudoku.humblebundle",
            sourceKind: "humblebundle",
            localExportPath: ".humble/HumbleSudoku.humblebundle",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleSudoku/main/.humble/HumbleSudoku.humblebundle",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-sudoku/prepare-edit",
            controlSessionPath: "/studio/humble-sudoku/session",
            controlRecoveryPath: "/api/studio/humble-sudoku/recovery",
            reviewArtifactPath: "/studio/humble-sudoku/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "my-vltava-run",
            name: "MyVltavaRun",
            repo: "mrPoky/MyVltavaRun",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/MyVltavaRun/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/my-vltava-run/prepare-edit",
            controlSessionPath: "/studio/my-vltava-run/session",
            controlRecoveryPath: "/api/studio/my-vltava-run/recovery",
            reviewArtifactPath: "/studio/my-vltava-run/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-control",
            name: "HumbleControl",
            repo: "mrPoky/HumbleControl",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleControl/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-control/prepare-edit",
            controlSessionPath: "/studio/humble-control/session",
            controlRecoveryPath: "/api/studio/humble-control/recovery",
            reviewArtifactPath: "/studio/humble-control/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-workout",
            name: "HumbleWorkout",
            repo: "mrPoky/HumbleWorkout",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleWorkout/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-workout/prepare-edit",
            controlSessionPath: "/studio/humble-workout/session",
            controlRecoveryPath: "/api/studio/humble-workout/recovery",
            reviewArtifactPath: "/studio/humble-workout/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-kakuro",
            name: "HumbleKakuro",
            repo: "mrPoky/HumbleKakuro",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleKakuro/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-kakuro/prepare-edit",
            controlSessionPath: "/studio/humble-kakuro/session",
            controlRecoveryPath: "/api/studio/humble-kakuro/recovery",
            reviewArtifactPath: "/studio/humble-kakuro/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-cycling",
            name: "HumbleCycling",
            repo: "mrPoky/HumbleCycling",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleCycling/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-cycling/prepare-edit",
            controlSessionPath: "/studio/humble-cycling/session",
            controlRecoveryPath: "/api/studio/humble-cycling/recovery",
            reviewArtifactPath: "/studio/humble-cycling/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-home",
            name: "HumbleHome",
            repo: "mrPoky/HumbleHome",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleHome/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-home/prepare-edit",
            controlSessionPath: "/studio/humble-home/session",
            controlRecoveryPath: "/api/studio/humble-home/recovery",
            reviewArtifactPath: "/studio/humble-home/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-cook",
            name: "HumbleCook",
            repo: "mrPoky/HumbleCook",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleCook/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-cook/prepare-edit",
            controlSessionPath: "/studio/humble-cook/session",
            controlRecoveryPath: "/api/studio/humble-cook/recovery",
            reviewArtifactPath: "/studio/humble-cook/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-architect",
            name: "HumbleArchitect",
            repo: "mrPoky/HumbleArchitect",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleArchitect/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-architect/prepare-edit",
            controlSessionPath: "/studio/humble-architect/session",
            controlRecoveryPath: "/api/studio/humble-architect/recovery",
            reviewArtifactPath: "/studio/humble-architect/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-nas",
            name: "HumbleNAS",
            repo: "mrPoky/HumbleNAS",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleNAS/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-nas/prepare-edit",
            controlSessionPath: "/studio/humble-nas/session",
            controlRecoveryPath: "/api/studio/humble-nas/recovery",
            reviewArtifactPath: "/studio/humble-nas/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "humble-subscription",
            name: "HumbleSubscription",
            repo: "mrPoky/HumbleSubscription",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleSubscription/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/humble-subscription/prepare-edit",
            controlSessionPath: "/studio/humble-subscription/session",
            controlRecoveryPath: "/api/studio/humble-subscription/recovery",
            reviewArtifactPath: "/studio/humble-subscription/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
        StudioSupportedAppSource(
            id: "my-family",
            name: "MyFamily",
            repo: "mrPoky/MyFamily",
            sourceSummary: ".humble/design.json",
            sourceKind: "design.json",
            localExportPath: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/MyFamily/main/.humble/design.json",
            connectionMode: "read-only",
            prepareEditMode: "prepare-edit",
            scopedPrepareEditPath: "/studio/my-family/prepare-edit",
            controlSessionPath: "/studio/my-family/session",
            controlRecoveryPath: "/api/studio/my-family/recovery",
            reviewArtifactPath: "/studio/my-family/review",
            applyGateStatus: "locked",
            writesEnabled: false
        ),
    ]

    static var remotePlaceholder: String {
        all.first?.remoteURL ?? "https://raw.githubusercontent.com/user/repo/main/.humble/design.json"
    }

    static func app(forRemoteURL remoteURL: String?) -> StudioSupportedAppSource? {
        guard let remoteURL else { return nil }
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return all.first(where: { $0.remoteURL == trimmed })
    }
}

struct StudioSupportedRemoteAppsSection: View {
    @Binding var remoteURLDraft: String
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        Section(StudioStrings.supportedAppsTitle) {
            Text(StudioStrings.supportedAppsPrompt)
                .font(.footnote)
                .foregroundStyle(.secondary)

            StudioSupportedAppsList(
                selectedRemoteURL: remoteURLDraft,
                useURL: { remoteURLDraft = $0.remoteURL },
                loadApp: loadApp
            )
        }
    }
}

struct StudioSupportedAppsCard: View {
    let selectedRemoteURL: String?
    let loadApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(StudioStrings.supportedAppsTitle)
                .font(.headline)

            Text(StudioStrings.supportedAppsPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StudioSupportedAppsList(
                selectedRemoteURL: selectedRemoteURL,
                useURL: nil,
                loadApp: loadApp
            )
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct StudioSupportedAppsList: View {
    let selectedRemoteURL: String?
    let useURL: ((StudioSupportedAppSource) -> Void)?
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        ForEach(StudioSupportedAppCatalog.all) { app in
            StudioSupportedAppRow(
                app: app,
                isCurrent: selectedRemoteURL == app.remoteURL,
                useURL: useURL,
                loadApp: loadApp
            )
        }
    }
}

private struct StudioSupportedAppRow: View {
    let app: StudioSupportedAppSource
    let isCurrent: Bool
    let useURL: ((StudioSupportedAppSource) -> Void)?
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(app.repo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(app.sourceSummary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(app.connectionSummary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppWorkspace): \(app.controlWorkspacePath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppLaunchIntent): \(app.launchIntentPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppScopedPrepareEdit): \(app.scopedPrepareEditPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppSessionPath): \(app.controlSessionPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppRecoveryWizard): \(app.recoveryWizardPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppSessionID): \(app.sessionID)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppReviewArtifact): \(app.reviewArtifactPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppStructuredDraft): \(app.structuredDraftPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppPatchPreview): \(app.patchPreviewPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppRuntimeReadiness): \(app.runtimeReadinessPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppProposalCenter): \(app.proposalCenterPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppPatchArtifact): \(app.patchArtifactPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppSandboxApply): \(app.sandboxApplyPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppSourceApplyLock): \(app.sourceApplyLockPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppTrustLevel): \(app.trustLevelPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppConnectionRegistry): \(app.connectionRegistryPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppNativeParity): \(app.nativeParityPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppApplyPreview): \(app.applyPreviewPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppEditBoundary): \(app.editBoundaryPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppSafeApplyBoundary): \(app.safeApplyBoundaryPath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(StudioStrings.supportedAppAuthoringSmoke): \(app.authoringSmokePath)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                if isCurrent {
                    Label(StudioStrings.current, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }

                if let useURL {
                    Button(StudioStrings.useURL) {
                        useURL(app)
                    }
                    .buttonStyle(.borderless)
                }

                if let loadApp {
                    Button(StudioStrings.loadNow) {
                        loadApp(app)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Label(
                    app.writesEnabled ? StudioStrings.supportedAppWritesEnabled : StudioStrings.supportedAppWritesLocked,
                    systemImage: app.writesEnabled ? "pencil.and.outline" : "lock.fill"
                )
                    .font(.caption2.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(app.writesEnabled ? .primary : .secondary)

                Label(StudioStrings.supportedAppApplyGateLocked, systemImage: "checkmark.shield.fill")
                    .font(.caption2.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
