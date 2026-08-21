import SwiftUI

struct StudioControlBridgeActionBar: View {
    let snapshot: StudioControlBridgeSnapshot
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            Button {
                loadSupportedApp(snapshot.app)
            } label: {
                Label("Load \(snapshot.app.name)", systemImage: "square.and.arrow.down")
            }

            Button {
                StudioControlBridgeActions.openControl(snapshot: snapshot)
            } label: {
                Label("Open Control", systemImage: snapshot.runtime.isLive ? "bolt.horizontal.circle.fill" : "play.circle")
            }

            Button {
                StudioControlBridgeActions.open(snapshot.readinessURL)
            } label: {
                Label("Open API", systemImage: "curlybraces")
            }
            .disabled(snapshot.readinessURL == nil)

            Button {
                StudioControlBridgeActions.reveal(snapshot.fileState.exportURL)
            } label: {
                Label("Reveal export", systemImage: "finder")
            }
            .disabled(snapshot.fileState.exportURL == nil)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

struct StudioControlBridgeLauncherHealthView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Control launcher health") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        StudioControlBridgeActions.openControl(snapshot: snapshot)
                    } label: {
                        Label("Launch Control", systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        StudioControlBridgeActions.open(snapshot.workspaceURL)
                    } label: {
                        Label("Open workspace", systemImage: "arrow.up.forward.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(snapshot.workspaceURL == nil)
                }

                ForEach(snapshot.launcherHealth) { check in
                    StudioControlReadinessRow(title: check.label, subtitle: check.detail, status: check.status)
                }
            }
        }
    }
}

struct StudioControlBridgeServerDiscoveryView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Server discovery") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlReadinessRow(
                    title: "Discovery manifest",
                    subtitle: snapshot.manifestDiscovery.detail,
                    status: snapshot.manifestDiscovery.status
                )
                StudioKeyValueRow(label: "Manifest", value: snapshot.manifestDiscovery.manifestPath)
                ForEach(snapshot.manifestDiscovery.originRows) { origin in
                    StudioControlReadinessRow(title: origin.label, subtitle: origin.detail, status: origin.status)
                }
            }
        }
    }
}

struct StudioControlBridgeWorkspaceSwitcherView: View {
    let snapshot: StudioControlBridgeSnapshot
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        StudioInspectorSection(title: "App workspace switcher") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 10)], spacing: 10) {
                ForEach(snapshot.appLanes) { app in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(app.name)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            StudioControlStatusBadge(status: app.id == snapshot.app.id ? "selected" : app.applyGateStatus)
                        }
                        Text(app.controlWorkspacePath)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Button {
                                loadSupportedApp(app)
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderless)
                            .help("Load \(app.name)")

                            Button {
                                StudioControlBridgeActions.open(StudioControlReadinessEndpoint.url(origin: snapshot.origin, path: app.controlWorkspacePath))
                            } label: {
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .buttonStyle(.borderless)
                            .help("Open \(app.name) in Control")
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
                    .padding(10)
                    .background(.quaternary.opacity(app.id == snapshot.app.id ? 0.32 : 0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

struct StudioControlBridgeFileRecoveryView: View {
    let snapshot: StudioControlBridgeSnapshot
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        StudioInspectorSection(title: "File recovery lanes") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.fileRecoveryRows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        StudioControlReadinessRow(title: row.app.name, subtitle: row.detail, status: row.status)
                        Button {
                            if let url = row.fileState.exportURL, row.fileState.exportStatus == "present" {
                                StudioControlBridgeActions.reveal(url)
                            } else if row.app.hasLocalExportResolver {
                                loadSupportedApp(row.app)
                            } else {
                                StudioControlBridgeActions.open(URL(string: row.app.remoteURL))
                            }
                        } label: {
                            Image(systemName: row.fileState.exportStatus == "present" ? "finder" : "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help(row.action)
                    }
                }
            }
        }
    }
}

struct StudioControlBridgeDiffArtifactView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Preview diff artifacts") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.diffArtifactRows) { row in
                    StudioControlReadinessRow(title: row.label, subtitle: row.detail, status: row.status)
                }
            }
        }
    }
}

struct StudioControlBridgeStructuredDraftInboxView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Structured draft inbox") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.structuredDraftItems) { item in
                    StudioControlReadinessRow(title: item.label, subtitle: item.detail, status: item.status)
                }
            }
        }
    }
}

struct StudioControlBridgeRepoPreflightView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Ticket/lane preflight") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.repoPreflightRows) { row in
                    StudioControlReadinessRow(title: row.label, subtitle: row.detail, status: row.status)
                }
            }
        }
    }
}

struct StudioControlBridgeSafeApplyWizardView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Safe apply wizard") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlReadinessRow(title: "Apply contract", subtitle: snapshot.pack.writeContractPreview.detail, status: snapshot.pack.writeContractPreview.status)
                ForEach(snapshot.safeApplyWizardSteps) { step in
                    StudioControlReadinessRow(title: "\(step.rank). \(step.label)", subtitle: step.detail, status: step.status)
                }
            }
        }
    }
}

struct StudioControlBridgeVisualSmokeView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Visual smoke checklist") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.visualSmokeSteps) { check in
                    StudioControlReadinessRow(title: check.label, subtitle: check.detail, status: check.status)
                }
            }
        }
    }
}

struct StudioControlBridgeConnectionCenterView: View {
    let snapshot: StudioControlBridgeSnapshot
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        StudioInspectorSection(title: "Connection center") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlReadinessRow(title: "Bridge mode", subtitle: "\(snapshot.runtime.modeLabel) / \(snapshot.runtime.originLabel)", status: snapshot.runtime.isLive ? "ready" : "attention")
                ForEach(snapshot.appLanes) { app in
                    StudioControlBridgeAppRow(app: app, isSelected: app.id == snapshot.app.id, origin: snapshot.origin, loadSupportedApp: loadSupportedApp)
                }
            }
        }
    }
}

struct StudioControlBridgeAppRow: View {
    let app: StudioSupportedAppSource
    let isSelected: Bool
    let origin: String
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StudioControlStatusBadge(status: isSelected ? "selected" : "ready")
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.subheadline.weight(.semibold))
                Text(app.connectionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(app.controlWorkspacePath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 10)

            Button {
                loadSupportedApp(app)
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)
            .help("Load \(app.name)")

            Button {
                StudioControlBridgeActions.open(StudioControlReadinessEndpoint.url(origin: origin, path: app.controlWorkspacePath))
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            .buttonStyle(.borderless)
            .help(app.controlWorkspacePath)
        }
        .padding(10)
        .background(.quaternary.opacity(isSelected ? 0.34 : 0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct StudioControlBridgeDeepLinkMapView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Deep-link map") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.deepLinks) { link in
                    HStack(alignment: .top, spacing: 10) {
                        StudioControlReadinessRow(title: link.label, subtitle: link.path, status: link.status)
                        Button {
                            StudioControlBridgeActions.open(link.url)
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(.borderless)
                        .disabled(link.url == nil)
                    }
                }
            }
        }
    }
}

struct StudioControlBridgeStatusChecksView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "Status checks") {
            VStack(alignment: .leading, spacing: 12) {
                StudioKeyValueRow(label: "Checked", value: snapshot.runtime.checkedAt)
                ForEach(snapshot.statusChecks) { check in
                    StudioControlReadinessRow(title: check.label, subtitle: check.detail, status: check.status)
                }
                ForEach(snapshot.runtime.attempts) { attempt in
                    StudioControlReadinessRow(title: attempt.origin, subtitle: attempt.detail, status: attempt.status)
                }
            }
        }
    }
}

struct StudioControlBridgeEditPreviewView: View {
    let snapshot: StudioControlBridgeSnapshot

    var body: some View {
        StudioInspectorSection(title: "No-write edit preview") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlReadinessRow(title: "Preview contract", subtitle: "writes:false / sourceWrites:false / apply:\(snapshot.pack.apply)", status: snapshot.pack.apply == "locked" ? "locked" : "attention")
                ForEach(snapshot.editPreviewItems) { item in
                    StudioControlReadinessRow(title: item.label, subtitle: item.detail, status: item.status)
                }
            }
        }
    }
}

struct StudioControlBridgeEndToEndFlowView: View {
    let snapshot: StudioControlBridgeSnapshot
    let loadSupportedApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        StudioInspectorSection(title: "End-to-end safe-edit flow") {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    loadSupportedApp(snapshot.app)
                } label: {
                    Label("Start with \(snapshot.app.name)", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                ForEach(snapshot.endToEndFlow) { step in
                    StudioControlReadinessRow(title: "\(step.rank). \(step.label)", subtitle: step.detail, status: step.status)
                }
            }
        }
    }
}
