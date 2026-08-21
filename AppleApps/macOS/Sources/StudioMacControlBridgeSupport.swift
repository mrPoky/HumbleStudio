import AppKit
import SwiftUI

enum StudioControlReadinessEndpoint {
    struct Candidate: Identifiable, Equatable {
        let origin: String
        let path: String
        let url: URL

        var id: String {
            url.absoluteString
        }
    }

    static var defaultOrigin: String {
        "http://127.0.0.1:3035"
    }

    static func origins() -> [String] {
        let configured = ProcessInfo.processInfo.environment["HUMBLECONTROL_URL"]
            ?? ProcessInfo.processInfo.environment["HUMBLESTUDIO_CONTROL_URL"]
        let origins = ([configured].compactMap { $0 } + [
            defaultOrigin,
            "http://127.0.0.1:3022",
            "http://127.0.0.1:3000"
        ])
        var seen = Set<String>()
        return origins
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    static func candidates(for app: StudioSupportedAppSource) -> [Candidate] {
        let path = readinessPath(for: app)
        return origins().compactMap { origin in
            guard let url = url(origin: origin, path: path) else { return nil }
            return Candidate(origin: origin, path: path, url: url)
        }
    }

    static func readinessPath(for app: StudioSupportedAppSource) -> String {
        "/api/studio/\(app.id)/safe-edit/readiness"
    }

    static func workspacePath(for app: StudioSupportedAppSource) -> String {
        app.controlWorkspacePath
    }

    static func url(origin: String, path: String) -> URL? {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "\(origin)\(normalizedPath)")
    }
}

struct StudioControlBridgeRuntime: Equatable {
    enum Mode: Equatable {
        case checking
        case live
        case fallback
    }

    struct Attempt: Identifiable, Equatable {
        let id = UUID()
        let origin: String
        let status: String
        let detail: String
    }

    let mode: Mode
    let origin: String?
    let endpointPath: String?
    let message: String
    let checkedAt: String
    let attempts: [Attempt]

    var isLive: Bool {
        mode == .live
    }

    var modeLabel: String {
        switch mode {
        case .checking:
            return "checking"
        case .live:
            return "live"
        case .fallback:
            return "fallback"
        }
    }

    var originLabel: String {
        origin ?? StudioControlReadinessEndpoint.defaultOrigin
    }

    var summaryTone: StudioInspectorSummaryTone {
        switch mode {
        case .live:
            return .success
        case .checking:
            return .accent
        case .fallback:
            return .warning
        }
    }

    static func checking(candidates: [StudioControlReadinessEndpoint.Candidate]) -> Self {
        Self(
            mode: .checking,
            origin: candidates.first?.origin,
            endpointPath: candidates.first?.path,
            message: "Checking HumbleControl localhost candidates.",
            checkedAt: timestamp(),
            attempts: candidates.map { Attempt(origin: $0.origin, status: "checking", detail: $0.path) }
        )
    }

    static func live(origin: String, endpointPath: String, attempts: [Attempt]) -> Self {
        Self(
            mode: .live,
            origin: origin,
            endpointPath: endpointPath,
            message: "HumbleControl readiness endpoint is live.",
            checkedAt: timestamp(),
            attempts: attempts
        )
    }

    static func fallback(message: String, attempts: [Attempt]) -> Self {
        Self(
            mode: .fallback,
            origin: attempts.first?.origin ?? StudioControlReadinessEndpoint.defaultOrigin,
            endpointPath: nil,
            message: message,
            checkedAt: timestamp(),
            attempts: attempts
        )
    }

    private static func timestamp() -> String {
        Date().formatted(.dateTime.hour().minute().second())
    }
}

struct StudioControlBridgeSnapshot {
    let app: StudioSupportedAppSource
    let document: StudioNativeDocument?
    let runtime: StudioControlBridgeRuntime
    let pack: StudioControlReadinessPack

    var appLanes: [StudioSupportedAppSource] {
        Array(StudioSupportedAppCatalog.all.prefix(10))
    }

    var origin: String {
        runtime.originLabel
    }

    var workspaceURL: URL? {
        StudioControlReadinessEndpoint.url(origin: origin, path: app.controlWorkspacePath)
    }

    var readinessURL: URL? {
        StudioControlReadinessEndpoint.url(origin: origin, path: StudioControlReadinessEndpoint.readinessPath(for: app))
    }

    var appWorkspaceLoaded: Bool {
        guard let document else { return false }
        return document.appName.caseInsensitiveCompare(app.name) == .orderedSame
            || document.appName.localizedCaseInsensitiveContains(app.name)
    }

    var fileState: StudioControlBridgeFileState {
        StudioControlBridgeFileState(app: app)
    }

    var manifestDiscovery: StudioControlBridgeManifestDiscovery {
        StudioControlBridgeManifestDiscovery(runtime: runtime)
    }

    var launcherHealth: [StudioControlBridgeStatusCheck] {
        let appURL = StudioControlBridgeActions.existingControlAppURL
        return [
            StudioControlBridgeStatusCheck(id: "runtime", label: "Runtime endpoint", status: runtime.isLive ? "passed" : "attention", detail: runtime.message),
            StudioControlBridgeStatusCheck(id: "launcher", label: "HumbleControl launcher", status: appURL == nil ? "missing" : "available", detail: appURL?.path ?? "No local HumbleControl.app was found."),
            StudioControlBridgeStatusCheck(id: "fallback", label: "Fallback open", status: workspaceURL == nil ? "missing" : "available", detail: workspaceURL?.absoluteString ?? app.controlWorkspacePath),
            StudioControlBridgeStatusCheck(id: "health", label: "Health check", status: runtime.isLive ? "passed" : "fallback", detail: runtime.checkedAt)
        ]
    }

    var fileRecoveryRows: [StudioControlBridgeAppFileRecovery] {
        appLanes.map { StudioControlBridgeAppFileRecovery(app: $0) }
    }

    var statusChecks: [StudioControlBridgeStatusCheck] {
        [
            StudioControlBridgeStatusCheck(id: "server", label: "Control server", status: runtime.isLive ? "passed" : "attention", detail: runtime.message),
            StudioControlBridgeStatusCheck(id: "manifest", label: "Readiness manifest", status: pack.schema.isEmpty ? "missing" : "passed", detail: pack.schema),
            StudioControlBridgeStatusCheck(id: "workspace", label: "Control workspace", status: workspaceURL == nil ? "missing" : "available", detail: app.controlWorkspacePath),
            StudioControlBridgeStatusCheck(id: "repository", label: "Local repository", status: fileState.repositoryStatus, detail: fileState.repositoryPath),
            StudioControlBridgeStatusCheck(id: "export", label: "Local export", status: fileState.exportStatus, detail: fileState.exportPath),
            StudioControlBridgeStatusCheck(id: "generator", label: "Export generator", status: fileState.generatorStatus, detail: fileState.generatorDetail),
            StudioControlBridgeStatusCheck(id: "ticket", label: "Ticket preflight", status: "required", detail: "Source apply requires an accepted HS ticket."),
            StudioControlBridgeStatusCheck(id: "lane", label: "Lane preflight", status: "required", detail: "Source apply requires a claimed clean lane."),
            StudioControlBridgeStatusCheck(id: "preview", label: "Edit preview", status: "ready", detail: "Token, text, navigation and asset intents are preview-only."),
            StudioControlBridgeStatusCheck(id: "apply", label: "Apply gate", status: "locked", detail: "writes:false / sourceWrites:false")
        ]
    }

    var structuredDraftItems: [StudioControlBridgeStatusCheck] {
        [
            StudioControlBridgeStatusCheck(id: "session", label: "Session", status: pack.editIntentInbox.status, detail: pack.editIntentInbox.sessionId),
            StudioControlBridgeStatusCheck(id: "proposal-url", label: "Proposal inbox", status: "ready", detail: pack.editIntentInbox.proposalsUrl),
            StudioControlBridgeStatusCheck(id: "operation-gate", label: "Operation gate", status: pack.editIntentInbox.operationGateStatus ?? "locked", detail: pack.editIntentInbox.detail)
        ] + pack.editIntentInbox.intents.map { intent in
            StudioControlBridgeStatusCheck(id: intent.id, label: intent.label, status: intent.status, detail: intent.detail)
        }
    }

    var repoPreflightRows: [StudioControlBridgeStatusCheck] {
        StudioControlBridgeRepoProbe.rows(ticketId: "HS-0106")
    }

    var diffArtifactRows: [StudioControlBridgeStatusCheck] {
        [
            StudioControlBridgeStatusCheck(id: "patch-preview", label: "Patch preview", status: "ready", detail: app.patchPreviewPath),
            StudioControlBridgeStatusCheck(id: "patch-artifact", label: "Patch artifact", status: "ready", detail: app.patchArtifactPath),
            StudioControlBridgeStatusCheck(id: "apply-preview", label: "Apply preview", status: pack.apply == "locked" ? "locked" : "attention", detail: app.applyPreviewPath),
            StudioControlBridgeStatusCheck(id: "source-lock", label: "Source apply lock", status: "locked", detail: app.sourceApplyLockPath),
            StudioControlBridgeStatusCheck(id: "write-state", label: "Write state", status: (!pack.writes && !pack.sourceWrites) ? "passed" : "failed", detail: "writes:\(pack.writes) / sourceWrites:\(pack.sourceWrites)")
        ]
    }

    var safeApplyWizardSteps: [StudioControlBridgeFlowStep] {
        let prerequisites = pack.writeContractPreview.prerequisites.enumerated().map { index, item in
            StudioControlBridgeFlowStep(rank: index + 1, label: item, status: "required", detail: pack.writeContractPreview.contractId)
        }
        return prerequisites + [
            StudioControlBridgeFlowStep(rank: prerequisites.count + 1, label: "Source apply", status: "locked", detail: "A separate accepted write contract must unlock this.")
        ]
    }

    var visualSmokeSteps: [StudioControlBridgeStatusCheck] {
        [
            StudioControlBridgeStatusCheck(id: "native-route", label: "Native Control route", status: "ready", detail: "Control readiness renders in the macOS workspace."),
            StudioControlBridgeStatusCheck(id: "refresh", label: "Refresh cycle", status: runtime.isLive ? "passed" : "attention", detail: runtime.checkedAt),
            StudioControlBridgeStatusCheck(id: "app-switch", label: "App switcher", status: appLanes.count == 10 ? "passed" : "attention", detail: "\(appLanes.count) app lanes visible."),
            StudioControlBridgeStatusCheck(id: "file-panel", label: "File recovery panel", status: fileRecoveryRows.isEmpty ? "missing" : "ready", detail: "\(fileRecoveryRows.count) recovery rows."),
            StudioControlBridgeStatusCheck(id: "no-write", label: "No-write smoke", status: (!pack.writes && !pack.sourceWrites && pack.apply == "locked") ? "passed" : "failed", detail: "writes:false, sourceWrites:false, apply locked.")
        ]
    }

    var deepLinks: [StudioControlBridgeDeepLink] {
        [
            link("studio", "Studio workspace", app.controlWorkspacePath, "native"),
            link("control", "Control workspace", app.controlWorkspacePath, runtime.isLive ? "live" : "fallback"),
            link("readiness", "Readiness API", StudioControlReadinessEndpoint.readinessPath(for: app), runtime.isLive ? "live" : "fallback"),
            link("prepare", "Prepare edit", app.scopedPrepareEditPath, "locked"),
            link("session", "Session", app.controlSessionPath, "ready"),
            link("recovery", "Recovery", app.controlRecoveryPath, "ready"),
            link("proposals", "Proposal center", app.proposalCenterPath, "ready"),
            link("patch", "Patch preview", app.patchPreviewPath, "ready"),
            link("apply", "Apply preview", app.applyPreviewPath, "locked"),
            link("smoke", "End-to-end smoke", app.authoringSmokePath, "ready")
        ]
    }

    var editPreviewItems: [StudioControlBridgeStatusCheck] {
        [
            StudioControlBridgeStatusCheck(id: "token", label: "Token change", status: "preview", detail: "Would show affected colors, gradients, typography or metrics."),
            StudioControlBridgeStatusCheck(id: "text", label: "Text change", status: "preview", detail: "Would show selected strings and owner surface."),
            StudioControlBridgeStatusCheck(id: "navigation", label: "Navigation change", status: "preview", detail: "Would show route, source view and target view."),
            StudioControlBridgeStatusCheck(id: "asset", label: "Asset change", status: "preview", detail: "Would show asset id, local path and fallback status."),
            StudioControlBridgeStatusCheck(id: "diff", label: "Patch artifact", status: "locked", detail: "No patch can apply until the write contract is accepted.")
        ]
    }

    var endToEndFlow: [StudioControlBridgeFlowStep] {
        [
            StudioControlBridgeFlowStep(rank: 1, label: "Select app", status: "passed", detail: app.name),
            StudioControlBridgeFlowStep(rank: 2, label: "Resolve files", status: fileState.exportStatus == "present" ? "passed" : fileState.exportStatus, detail: fileState.exportPath),
            StudioControlBridgeFlowStep(rank: 3, label: "Load native workspace", status: appWorkspaceLoaded ? "passed" : "attention", detail: appWorkspaceLoaded ? document?.appName ?? app.name : "Use Load to open or generate the supported export."),
            StudioControlBridgeFlowStep(rank: 4, label: "Check Control", status: runtime.isLive ? "passed" : "fallback", detail: runtime.originLabel),
            StudioControlBridgeFlowStep(rank: 5, label: "Prepare edit", status: "locked", detail: app.scopedPrepareEditPath),
            StudioControlBridgeFlowStep(rank: 6, label: "Review preview", status: "ready", detail: app.patchPreviewPath),
            StudioControlBridgeFlowStep(rank: 7, label: "Ticket/lane preflight", status: "required", detail: "HS ticket, clean lane, native verification."),
            StudioControlBridgeFlowStep(rank: 8, label: "Apply gate", status: "locked", detail: "No source write can run from this panel."),
            StudioControlBridgeFlowStep(rank: 9, label: "Verification", status: "required", detail: "./script/build_and_run.sh --native-ci"),
            StudioControlBridgeFlowStep(rank: 10, label: "Promotion", status: "locked", detail: "Only after accepted write contract and evidence.")
        ]
    }

    private func link(_ id: String, _ label: String, _ path: String, _ status: String) -> StudioControlBridgeDeepLink {
        StudioControlBridgeDeepLink(
            id: id,
            label: label,
            path: path,
            url: StudioControlReadinessEndpoint.url(origin: origin, path: path),
            status: status
        )
    }
}

struct StudioControlBridgeManifestDiscovery {
    let status: String
    let detail: String
    let manifestPath: String
    let originRows: [StudioControlBridgeStatusCheck]

    init(runtime: StudioControlBridgeRuntime) {
        let manifestURL = Self.manifestCandidates().first { FileManager.default.fileExists(atPath: $0.path) }
        status = runtime.isLive ? "passed" : (manifestURL == nil ? "attention" : "available")
        manifestPath = manifestURL?.path ?? "No local manifest found."
        if runtime.isLive {
            detail = "Resolved through live HumbleControl endpoint \(runtime.originLabel)."
        } else if let manifestURL {
            detail = "Using local manifest candidate \(manifestURL.lastPathComponent)."
        } else {
            detail = "Using environment and localhost candidates until HumbleControl publishes a manifest."
        }

        originRows = StudioControlReadinessEndpoint.origins().enumerated().map { index, origin in
            let attempt = runtime.attempts.first { $0.origin == origin }
            return StudioControlBridgeStatusCheck(
                id: "origin-\(index)",
                label: origin,
                status: attempt?.status ?? (runtime.origin == origin ? runtime.modeLabel : "candidate"),
                detail: attempt?.detail ?? StudioControlReadinessEndpoint.readinessPath(for: StudioSupportedAppCatalog.all[0])
            )
        }
    }

    private static func manifestCandidates() -> [URL] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let seeds = [
            cwd,
            sourceDirectory,
            home.appendingPathComponent("Coding/personal/apps/HumbleStudio", isDirectory: true),
            home.appendingPathComponent("Coding/personal/apps/HumbleControl", isDirectory: true)
        ]
        let relativePaths = [
            ".humble/control-origin.json",
            ".humble/control-manifest.json",
            ".local-preview/control-origin.json",
            ".local-preview/control-manifest.json"
        ]
        var seen = Set<String>()
        return seeds.flatMap { seed in
            relativePaths.map { seed.appendingPathComponent($0) }
        }
        .filter { seen.insert($0.path).inserted }
    }
}

struct StudioControlBridgeFileState {
    let repositoryPath: String
    let repositoryStatus: String
    let exportPath: String
    let exportStatus: String
    let generatorStatus: String
    let generatorDetail: String
    let exportURL: URL?

    init(app: StudioSupportedAppSource) {
        guard app.hasLocalExportResolver, let repositoryURL = app.localRepositoryURL, let exportURL = app.localExportURL else {
            repositoryPath = app.remoteURL
            repositoryStatus = "remote"
            exportPath = app.remoteURL
            exportStatus = "remote"
            generatorStatus = "remote"
            generatorDetail = "Remote source is used for this app."
            self.exportURL = nil
            return
        }

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let repositoryExists = fileManager.fileExists(atPath: repositoryURL.path, isDirectory: &isDirectory) && isDirectory.boolValue
        let exportExists = fileManager.fileExists(atPath: exportURL.path)

        repositoryPath = repositoryURL.path
        repositoryStatus = repositoryExists ? "present" : "missing"
        exportPath = exportURL.path
        exportStatus = exportExists ? "present" : "missing"
        generatorStatus = app.localExportCommand.isEmpty ? "missing" : "available"
        generatorDetail = app.localExportCommand.joined(separator: " ")
        self.exportURL = exportURL
    }
}

struct StudioControlBridgeAppFileRecovery: Identifiable {
    let app: StudioSupportedAppSource
    let fileState: StudioControlBridgeFileState
    let status: String
    let detail: String
    let action: String

    var id: String {
        app.id
    }

    init(app: StudioSupportedAppSource) {
        self.app = app
        fileState = StudioControlBridgeFileState(app: app)

        if fileState.exportStatus == "present" {
            status = "present"
            detail = fileState.exportPath
            action = "Reveal export"
        } else if fileState.repositoryStatus == "missing" {
            status = "missing"
            detail = fileState.repositoryPath
            action = "Recover repository"
        } else if fileState.generatorStatus == "available" {
            status = "recoverable"
            detail = fileState.generatorDetail
            action = "Load or generate"
        } else if fileState.exportStatus == "remote" {
            status = "remote"
            detail = app.remoteURL
            action = "Open remote"
        } else {
            status = "attention"
            detail = fileState.exportPath
            action = "Inspect source"
        }
    }
}

enum StudioControlBridgeRepoProbe {
    static func rows(ticketId: String) -> [StudioControlBridgeStatusCheck] {
        guard let rootURL = repoRootURL() else {
            return [
                StudioControlBridgeStatusCheck(id: "repo-root", label: "Repo root", status: "missing", detail: "No ancestor with .humble was found.")
            ]
        }

        let humbleURL = rootURL.appendingPathComponent(".humble", isDirectory: true)
        let ticketsURL = humbleURL.appendingPathComponent("tickets", isDirectory: true)
        let ticketURL = ticketsURL.appendingPathComponent("\(ticketId).json")
        let lanesURL = humbleURL.appendingPathComponent("coordination/lanes.json")
        let statusURL = humbleURL.appendingPathComponent("status/current.json")
        let ticketStatus = statusValue(in: ticketURL) ?? "unreadable"

        return [
            StudioControlBridgeStatusCheck(id: "repo-root", label: "Repo root", status: "passed", detail: rootURL.path),
            StudioControlBridgeStatusCheck(id: "ticket-store", label: "Ticket store", status: exists(ticketsURL) ? "passed" : "missing", detail: ticketsURL.path),
            StudioControlBridgeStatusCheck(id: "ticket", label: ticketId, status: exists(ticketURL) ? ticketStatus : "missing", detail: ticketURL.path),
            StudioControlBridgeStatusCheck(id: "lane-registry", label: "Lane registry", status: exists(lanesURL) ? "passed" : "missing", detail: lanesURL.path),
            StudioControlBridgeStatusCheck(id: "status-snapshot", label: "Status snapshot", status: exists(statusURL) ? "passed" : "missing", detail: statusURL.path)
        ]
    }

    private static func repoRootURL() -> URL? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let seeds = [
            URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true),
            URL(fileURLWithPath: #filePath),
            home.appendingPathComponent("Coding/personal/apps/HumbleStudio", isDirectory: true),
            home.appendingPathComponent("Coding/personal/worktrees/HumbleStudio/lane-1", isDirectory: true)
        ]

        for seed in seeds {
            if let root = firstHumbleAncestor(from: seed) {
                return root
            }
        }
        return nil
    }

    private static func firstHumbleAncestor(from seed: URL) -> URL? {
        var current = directoryURL(from: seed)
        for _ in 0..<12 {
            if exists(current.appendingPathComponent(".humble", isDirectory: true)) {
                return current
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                return nil
            }
            current = parent
        }
        return nil
    }

    private static func directoryURL(from url: URL) -> URL {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url
        }
        return url.deletingLastPathComponent()
    }

    private static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private static func statusValue(in url: URL) -> String? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data),
              let object = json as? [String: Any],
              let status = object["status"] as? String else {
            return nil
        }
        return status
    }
}

struct StudioControlBridgeDeepLink: Identifiable {
    let id: String
    let label: String
    let path: String
    let url: URL?
    let status: String
}

struct StudioControlBridgeStatusCheck: Identifiable {
    let id: String
    let label: String
    let status: String
    let detail: String
}

struct StudioControlBridgeFlowStep: Identifiable {
    let rank: Int
    let label: String
    let status: String
    let detail: String

    var id: Int {
        rank
    }
}

enum StudioControlBridgeActions {
    static var existingControlAppURL: URL? {
        firstExistingControlAppURL()
    }

    static func openControl(snapshot: StudioControlBridgeSnapshot) {
        if !snapshot.runtime.isLive, let appURL = firstExistingControlAppURL() {
            NSWorkspace.shared.open(appURL)
            return
        }
        open(snapshot.workspaceURL)
    }

    static func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    static func reveal(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private static func firstExistingControlAppURL() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "/Applications/HumbleControl.app",
            "\(home)/Applications/HumbleControl.app",
            "\(home)/Coding/personal/apps/HumbleControl/.build/XcodeDerivedData/Build/Products/Debug/HumbleControl.app"
        ]
        return candidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
