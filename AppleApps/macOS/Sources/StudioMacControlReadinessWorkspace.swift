import AppKit
import SwiftUI

struct StudioMacControlReadinessPage: View {
    let document: StudioNativeDocument?
    let loadSupportedApp: (StudioSupportedAppSource) -> Void
    @StateObject private var viewModel = StudioControlReadinessViewModel()

    private var app: StudioSupportedAppSource {
        StudioControlReadinessAppResolver.resolve(document: document)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                readinessGrid
                detailGrid
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: app.id) {
            await viewModel.refresh(app: app)
        }
    }

    private var pack: StudioControlReadinessPack {
        viewModel.pack ?? StudioControlReadinessPack.fallback(app: app)
    }

    private var bridgeSnapshot: StudioControlBridgeSnapshot {
        StudioControlBridgeSnapshot(app: app, document: document, runtime: viewModel.runtime, pack: pack)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Control readiness", systemImage: "checklist.checked")
                        .font(.title2.weight(.semibold))
                    Text(pack.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button {
                    Task { await viewModel.refresh(app: app) }
                } label: {
                    Label(viewModel.isLoading ? "Loading" : "Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            StudioInspectorSummaryGrid(items: [
                StudioInspectorSummaryItem(label: "App", value: pack.appName, tone: .accent),
                StudioInspectorSummaryItem(label: "Items", value: "\(pack.itemCount)", tone: pack.itemCount == 10 ? .success : .warning),
                StudioInspectorSummaryItem(label: "Status", value: pack.status, tone: StudioControlReadinessTone.summaryTone(for: pack.status)),
                StudioInspectorSummaryItem(label: "Control", value: viewModel.runtime.modeLabel, tone: viewModel.runtime.summaryTone),
                StudioInspectorSummaryItem(label: "Origin", value: viewModel.runtime.originLabel, tone: viewModel.runtime.summaryTone),
                StudioInspectorSummaryItem(label: "Apply", value: pack.apply, tone: pack.apply == "locked" ? .success : .warning),
                StudioInspectorSummaryItem(label: "Writes", value: pack.writes ? "true" : "false", tone: pack.writes ? .warning : .success),
                StudioInspectorSummaryItem(label: "Source writes", value: pack.sourceWrites ? "true" : "false", tone: pack.sourceWrites ? .warning : .success)
            ])

            StudioControlBridgeActionBar(snapshot: bridgeSnapshot, loadSupportedApp: loadSupportedApp)

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "wifi.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }

    private var readinessGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
            ForEach(pack.items) { item in
                StudioControlReadinessCard(item: item)
            }
        }
    }

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 16)], spacing: 16) {
            StudioControlBridgeConnectionCenterView(snapshot: bridgeSnapshot, loadSupportedApp: loadSupportedApp)
            StudioControlBridgeDeepLinkMapView(snapshot: bridgeSnapshot)
            StudioControlBridgeStatusChecksView(snapshot: bridgeSnapshot)
            StudioControlBridgeEditPreviewView(snapshot: bridgeSnapshot)
            StudioControlBridgeEndToEndFlowView(snapshot: bridgeSnapshot, loadSupportedApp: loadSupportedApp)
            StudioControlReadinessNativeParityView(parity: pack.nativeParity)
            StudioControlReadinessRecoveryView(recovery: pack.recoveryWorkbench)
            StudioControlReadinessIntentView(inbox: pack.editIntentInbox)
            StudioControlReadinessDiagnosticsView(diagnostics: pack.connectionDiagnostics)
            StudioControlReadinessPreflightView(preflight: pack.ticketLanePreflightPreview)
            StudioControlReadinessNavigationView(navigation: pack.navigation)
            StudioControlReadinessApplyDesignView(document: pack.applyDesignDocument)
            StudioControlReadinessFidelityView(fidelity: pack.previewFidelity)
            StudioControlReadinessDensityView(readability: pack.workspaceReadability)
            StudioControlReadinessWriteContractView(contract: pack.writeContractPreview)
        }
    }
}

@MainActor
private final class StudioControlReadinessViewModel: ObservableObject {
    @Published var pack: StudioControlReadinessPack?
    @Published var runtime = StudioControlBridgeRuntime.fallback(message: "Control endpoint has not been checked yet.", attempts: [])
    @Published var isLoading = false
    @Published var errorMessage: String?

    func refresh(app: StudioSupportedAppSource) async {
        isLoading = true
        let candidates = StudioControlReadinessEndpoint.candidates(for: app)
        runtime = .checking(candidates: candidates)
        defer { isLoading = false }

        var attempts: [StudioControlBridgeRuntime.Attempt] = []

        for candidate in candidates {
            do {
                let (data, response) = try await URLSession.shared.data(from: candidate.url)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode
                    attempts.append(.init(origin: candidate.origin, status: "failed", detail: "HTTP \(statusCode.map(String.init) ?? "unknown")"))
                    continue
                }
                let decoded = try JSONDecoder().decode(StudioControlReadinessPack.self, from: data)
                pack = decoded
                runtime = .live(origin: candidate.origin, endpointPath: candidate.path, attempts: attempts + [
                    .init(origin: candidate.origin, status: "passed", detail: "Readiness endpoint responded.")
                ])
                errorMessage = nil
                return
            } catch {
                attempts.append(.init(origin: candidate.origin, status: "failed", detail: error.localizedDescription))
            }
        }

        pack = StudioControlReadinessPack.fallback(app: app)
        runtime = .fallback(message: "Control readiness is using the native fallback.", attempts: attempts)
        errorMessage = attempts.last.map { "Control readiness is using the native fallback: \($0.detail)" }
    }
}

private enum StudioControlReadinessEndpoint {
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

private struct StudioControlBridgeRuntime: Equatable {
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

private enum StudioControlReadinessAppResolver {
    static func resolve(document: StudioNativeDocument?) -> StudioSupportedAppSource {
        if let document {
            if let app = StudioSupportedAppCatalog.all.first(where: { $0.name.caseInsensitiveCompare(document.appName) == .orderedSame }) {
                return app
            }
            if let app = StudioSupportedAppCatalog.all.first(where: { document.appName.localizedCaseInsensitiveContains($0.name) }) {
                return app
            }
        }
        return StudioSupportedAppCatalog.all.first(where: { $0.id == "humble-sudoku" }) ?? StudioSupportedAppCatalog.all[0]
    }
}

private struct StudioControlReadinessPack: Decodable {
    let schema: String
    let generatedAt: String
    let appId: String
    let appName: String
    let status: String
    let summary: String
    let writes: Bool
    let sourceWrites: Bool
    let apply: String
    let itemCount: Int
    let readyCount: Int
    let lockedCount: Int
    let attentionCount: Int
    let blockedCount: Int
    let items: [Item]
    let nativeParity: NativeParity
    let recoveryWorkbench: RecoveryWorkbench
    let editIntentInbox: EditIntentInbox
    let connectionDiagnostics: ConnectionDiagnostics
    let ticketLanePreflightPreview: TicketLanePreflightPreview
    let navigation: Navigation
    let applyDesignDocument: ApplyDesignDocument
    let previewFidelity: PreviewFidelity
    let workspaceReadability: WorkspaceReadability
    let writeContractPreview: WriteContractPreview

    private enum CodingKeys: String, CodingKey {
        case schema
        case generatedAt
        case appId
        case appName
        case status
        case summary
        case writes
        case sourceWrites
        case apply
        case itemCount
        case readyCount
        case lockedCount
        case attentionCount
        case blockedCount
        case items
        case nativeParity
        case recoveryWorkbench
        case editIntentInbox
        case connectionDiagnostics
        case ticketLanePreflightPreview
        case navigation
        case applyDesignDocument
        case previewFidelity
        case workspaceReadability
        case writeContractPreview
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schema = values.decodeString(.schema, default: "humble.control.studio-control-readiness-pack.v1")
        generatedAt = values.decodeString(.generatedAt, default: "local-fallback")
        appId = values.decodeString(.appId, default: "humble-sudoku")
        appName = values.decodeString(.appName, default: "HumbleSudoku")
        status = values.decodeString(.status, default: "ready")
        summary = values.decodeString(.summary, default: "Native Studio readiness is available in review-only mode.")
        writes = values.decodeBool(.writes, default: false)
        sourceWrites = values.decodeBool(.sourceWrites, default: false)
        apply = values.decodeString(.apply, default: "locked")
        itemCount = values.decodeInt(.itemCount, default: 10)
        readyCount = values.decodeInt(.readyCount, default: 6)
        lockedCount = values.decodeInt(.lockedCount, default: 3)
        attentionCount = values.decodeInt(.attentionCount, default: 1)
        blockedCount = values.decodeInt(.blockedCount, default: 0)
        items = values.decodeArray(.items, default: [])
        nativeParity = values.decodeValue(.nativeParity, default: .fallback)
        recoveryWorkbench = values.decodeValue(.recoveryWorkbench, default: .fallback)
        editIntentInbox = values.decodeValue(.editIntentInbox, default: .fallback(appId: appId))
        connectionDiagnostics = values.decodeValue(.connectionDiagnostics, default: .fallback)
        ticketLanePreflightPreview = values.decodeValue(.ticketLanePreflightPreview, default: .fallback)
        navigation = values.decodeValue(.navigation, default: .fallback(appId: appId))
        applyDesignDocument = values.decodeValue(.applyDesignDocument, default: .fallback)
        previewFidelity = values.decodeValue(.previewFidelity, default: .fallback(appId: appId))
        workspaceReadability = values.decodeValue(.workspaceReadability, default: .fallback)
        writeContractPreview = values.decodeValue(.writeContractPreview, default: .fallback(appId: appId))
    }

    init(
        schema: String,
        generatedAt: String,
        appId: String,
        appName: String,
        status: String,
        summary: String,
        writes: Bool,
        sourceWrites: Bool,
        apply: String,
        itemCount: Int,
        readyCount: Int,
        lockedCount: Int,
        attentionCount: Int,
        blockedCount: Int,
        items: [Item],
        nativeParity: NativeParity,
        recoveryWorkbench: RecoveryWorkbench,
        editIntentInbox: EditIntentInbox,
        connectionDiagnostics: ConnectionDiagnostics,
        ticketLanePreflightPreview: TicketLanePreflightPreview,
        navigation: Navigation,
        applyDesignDocument: ApplyDesignDocument,
        previewFidelity: PreviewFidelity,
        workspaceReadability: WorkspaceReadability,
        writeContractPreview: WriteContractPreview
    ) {
        self.schema = schema
        self.generatedAt = generatedAt
        self.appId = appId
        self.appName = appName
        self.status = status
        self.summary = summary
        self.writes = writes
        self.sourceWrites = sourceWrites
        self.apply = apply
        self.itemCount = itemCount
        self.readyCount = readyCount
        self.lockedCount = lockedCount
        self.attentionCount = attentionCount
        self.blockedCount = blockedCount
        self.items = items
        self.nativeParity = nativeParity
        self.recoveryWorkbench = recoveryWorkbench
        self.editIntentInbox = editIntentInbox
        self.connectionDiagnostics = connectionDiagnostics
        self.ticketLanePreflightPreview = ticketLanePreflightPreview
        self.navigation = navigation
        self.applyDesignDocument = applyDesignDocument
        self.previewFidelity = previewFidelity
        self.workspaceReadability = workspaceReadability
        self.writeContractPreview = writeContractPreview
    }
}

private extension StudioControlReadinessPack {
    struct Item: Decodable, Identifiable {
        let id: String
        let rank: Int
        let label: String
        let status: String
        let href: String
        let summary: String
        let evidence: String
        let writes: Bool
        let sourceWrites: Bool

        static func fallback(id: String, rank: Int, label: String, status: String, summary: String, evidence: String) -> Self {
            Self(id: id, rank: rank, label: label, status: status, href: "#\(id)", summary: summary, evidence: evidence, writes: false, sourceWrites: false)
        }
    }

    struct NativeParity: Decodable {
        let status: String
        let route: String
        let apiRoute: String
        let sharedSchemas: [String]
        let handoffSurfaces: [String]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static let fallback = Self(
            status: "ready",
            route: "/studio/humble-sudoku/safe-edit",
            apiRoute: "/api/studio/humble-sudoku/safe-edit/readiness",
            sharedSchemas: [
                "humble.control.studio-safe-edit-flow.v1",
                "humble.control.studio-safe-edit-capability-plan.v1",
                "humble.control.studio-control-readiness-pack.v1"
            ],
            handoffSurfaces: ["native Studio inspector", "web safe-edit review", "localhost JSON endpoint"],
            writes: false,
            sourceWrites: false,
            detail: "Native Studio consumes the same readiness family as Control."
        )
    }

    struct RecoveryWorkbench: Decodable {
        let status: String
        let acceptedSchemas: [String]
        let exportFilenames: [String]
        let importModes: [String]
        let steps: [String]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static let fallback = Self(
            status: "ready",
            acceptedSchemas: ["safe-edit", "capabilities", "readiness"],
            exportFilenames: [
                "humble-sudoku-studio-safe-edit-request.json",
                "humble-sudoku-studio-safe-edit-capabilities.json",
                "humble-sudoku-studio-control-readiness-pack.json"
            ],
            importModes: ["review-only", "compare-only", "restore-context"],
            steps: ["Load JSON", "Verify app id", "Compare gates", "Restore review context"],
            writes: false,
            sourceWrites: false,
            detail: "Recovery can rebuild review context without source apply."
        )
    }

    struct EditIntentInbox: Decodable {
        let status: String
        let sessionId: String
        let proposalsUrl: String
        let operationGateStatus: String?
        let intents: [Intent]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static func fallback(appId: String) -> Self {
            Self(
                status: "ready",
                sessionId: "hc-\(appId)-studio-mode",
                proposalsUrl: "/studio/\(appId)/proposals",
                operationGateStatus: "passed",
                intents: [
                    Intent(id: "review-live-operations", label: "Review live operations", status: "ready", detail: "Use app-scoped proposal operations.", writes: false, sourceWrites: false),
                    Intent(id: "compare-artifacts", label: "Compare artifacts", status: "ready", detail: "Compare proposal, patch and sandbox evidence.", writes: false, sourceWrites: false),
                    Intent(id: "restore-session-context", label: "Restore session context", status: "ready", detail: "Keep the selected app and session stable.", writes: false, sourceWrites: false)
                ],
                writes: false,
                sourceWrites: false,
                detail: "Intent rows are scoped to the selected app and current Studio session."
            )
        }
    }

    struct Intent: Decodable, Identifiable {
        let id: String
        let label: String
        let status: String
        let detail: String
        let writes: Bool
        let sourceWrites: Bool
    }

    struct ConnectionDiagnostics: Decodable {
        let status: String
        let helperUrl: String
        let causes: [Cause]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static let fallback = Self(
            status: "attention",
            helperUrl: "/api/studio/helper",
            causes: [
                Cause(id: "runtime-readiness", severity: "attention", source: "runtime", detail: "Control is not currently connected, native fallback is active.", recoveryHref: "#runtime", writes: false, sourceWrites: false),
                Cause(id: "proposal-review", severity: "info", source: "proposal", detail: "Proposal intent remains app-scoped.", recoveryHref: "#proposal", writes: false, sourceWrites: false),
                Cause(id: "source-apply", severity: "locked", source: "apply", detail: "Source apply is locked.", recoveryHref: "#apply", writes: false, sourceWrites: false)
            ],
            writes: false,
            sourceWrites: false,
            detail: "Diagnostics explain readiness causes without writing source files."
        )
    }

    struct Cause: Decodable, Identifiable {
        let id: String
        let severity: String
        let source: String
        let detail: String
        let recoveryHref: String
        let writes: Bool
        let sourceWrites: Bool
    }

    struct TicketLanePreflightPreview: Decodable {
        let status: String
        let ticketRequired: Bool
        let laneRequired: Bool
        let checks: [Check]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static let fallback = Self(
            status: "locked",
            ticketRequired: true,
            laneRequired: true,
            checks: [
                Check(id: "ticket", label: "Repo-native ticket", status: "required", command: nil, detail: "A source apply needs a ticket.", writes: false, sourceWrites: false),
                Check(id: "lane", label: "Lane-backed branch", status: "required", command: nil, detail: "Implementation must use a prepared lane.", writes: false, sourceWrites: false),
                Check(id: "verification", label: "Verification", status: "required", command: "./script/build_and_run.sh --native-ci", detail: "Attach native build evidence.", writes: false, sourceWrites: false),
                Check(id: "confirmation", label: "Explicit confirmation", status: "locked", command: nil, detail: "A separate accepted write contract must unlock apply.", writes: false, sourceWrites: false)
            ],
            writes: false,
            sourceWrites: false,
            detail: "Preflight is visible now, but source apply stays locked."
        )
    }

    struct Check: Decodable, Identifiable {
        let id: String
        let label: String
        let status: String
        let command: String?
        let detail: String
        let writes: Bool
        let sourceWrites: Bool
    }

    struct Navigation: Decodable {
        let status: String
        let primary: [NavigationItem]
        let writes: Bool
        let sourceWrites: Bool

        static func fallback(appId: String) -> Self {
            Self(
                status: "ready",
                primary: [
                    NavigationItem(id: "workspace", label: "Workspace", href: "/studio/\(appId)", intent: "read", writes: false, sourceWrites: false),
                    NavigationItem(id: "review", label: "Review", href: "/studio/\(appId)/review", intent: "review", writes: false, sourceWrites: false),
                    NavigationItem(id: "proposals", label: "Proposals", href: "/studio/\(appId)/proposals", intent: "review", writes: false, sourceWrites: false),
                    NavigationItem(id: "prepare", label: "Prepare", href: "/studio/\(appId)/prepare-edit", intent: "prepare", writes: false, sourceWrites: false),
                    NavigationItem(id: "session", label: "Session", href: "/studio/\(appId)/session", intent: "session", writes: false, sourceWrites: false),
                    NavigationItem(id: "safe-edit", label: "Safe edit", href: "/studio/\(appId)/safe-edit", intent: "safe-edit", writes: false, sourceWrites: false)
                ],
                writes: false,
                sourceWrites: false
            )
        }
    }

    struct NavigationItem: Decodable, Identifiable {
        let id: String
        let label: String
        let href: String
        let intent: String
        let writes: Bool
        let sourceWrites: Bool
    }

    struct ApplyDesignDocument: Decodable {
        let status: String
        let title: String
        let sections: [Section]
        let writes: Bool
        let sourceWrites: Bool

        static let fallback = Self(
            status: "locked",
            title: "Locked source apply design",
            sections: [
                Section(id: "input", title: "Input contract", bullets: ["Accept only app-scoped JSON.", "Reject sourceWrites:true."]),
                Section(id: "review", title: "Review contract", bullets: ["Show target files and proposed diff.", "Require ticket/lane/verification preview."]),
                Section(id: "apply", title: "Apply contract", bullets: ["Stay locked until a separate ticket is accepted.", "Attach verification evidence."])
            ],
            writes: false,
            sourceWrites: false
        )
    }

    struct Section: Decodable, Identifiable {
        let id: String
        let title: String
        let bullets: [String]
    }

    struct PreviewFidelity: Decodable {
        let status: String
        let targetAppId: String
        let activeForSelectedApp: Bool
        let checkpoints: [String]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static func fallback(appId: String) -> Self {
            Self(
                status: appId == "humble-sudoku" ? "ready" : "attention",
                targetAppId: "humble-sudoku",
                activeForSelectedApp: appId == "humble-sudoku",
                checkpoints: ["selected app identity", "board/state preview route", "safe-edit review route", "session recovery route", "no-write parity"],
                writes: false,
                sourceWrites: false,
                detail: "HumbleSudoku remains the first native preview fidelity target."
            )
        }
    }

    struct WorkspaceReadability: Decodable {
        let status: String
        let density: String
        let regions: [String]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static let fallback = Self(
            status: "ready",
            density: "compact-review",
            regions: ["summary hero", "readiness rows", "diagnostics", "preflight", "apply lock", "source metadata"],
            writes: false,
            sourceWrites: false,
            detail: "Dense readiness information is split into stable native scan regions."
        )
    }

    struct WriteContractPreview: Decodable {
        let status: String
        let contractId: String
        let prerequisites: [String]
        let forbiddenUntilAccepted: [String]
        let writes: Bool
        let sourceWrites: Bool
        let detail: String

        static func fallback(appId: String) -> Self {
            Self(
                status: "locked",
                contractId: "\(appId)-write-contract-preview-v1",
                prerequisites: ["accepted write ticket", "claimed lane", "clean worktree", "artifact review", "explicit confirmation", "post-apply verification"],
                forbiddenUntilAccepted: ["writing repository source files", "running apply from imported JSON", "promoting without ticket evidence"],
                writes: false,
                sourceWrites: false,
                detail: "The write contract is intentionally a preview and cannot execute apply."
            )
        }
    }
}

private extension StudioControlReadinessPack {
    static func fallback(app: StudioSupportedAppSource) -> Self {
        let items = [
            Item.fallback(id: "native-safe-edit-parity", rank: 1, label: "Native safe-edit parity", status: "ready", summary: "Native Studio reads the same safe-edit readiness family as Control.", evidence: "Shared schema family is rendered in SwiftUI."),
            Item.fallback(id: "json-recovery-workbench", rank: 2, label: "JSON recovery workbench", status: "ready", summary: "Readiness JSON can restore review context without applying changes.", evidence: "review-only / compare-only / restore-context"),
            Item.fallback(id: "session-edit-intent-inbox", rank: 3, label: "Session edit intent inbox", status: "ready", summary: "Edit intent is tied to selected app and session.", evidence: "hc-\(app.id)-studio-mode"),
            Item.fallback(id: "connection-health-diagnostics", rank: 4, label: "Connection health diagnostics", status: "attention", summary: "Native fallback explains helper/Control state while offline.", evidence: "Control endpoint candidates are checked on refresh."),
            Item.fallback(id: "ticket-lane-preflight-preview", rank: 5, label: "Ticket/lane preflight preview", status: "locked", summary: "Future writes expose ticket, lane, verification and confirmation requirements.", evidence: "locked / sourceWrites:false"),
            Item.fallback(id: "unified-studio-navigation", rank: 6, label: "Unified Studio navigation", status: "ready", summary: "Workspace, review, proposals, prepare, session and safe-edit are grouped.", evidence: "six app-scoped routes"),
            Item.fallback(id: "locked-apply-design-document", rank: 7, label: "Locked apply design document", status: "locked", summary: "Apply design is readable but cannot execute.", evidence: "separate write contract required"),
            Item.fallback(id: "humblesudoku-preview-fidelity", rank: 8, label: "HumbleSudoku preview fidelity", status: app.id == "humble-sudoku" ? "ready" : "attention", summary: "HumbleSudoku remains the first fidelity target.", evidence: app.id == "humble-sudoku" ? "selected target active" : "selected app differs"),
            Item.fallback(id: "workspace-density-readability", rank: 9, label: "Workspace density/readability", status: "ready", summary: "Native page uses scan-first sections.", evidence: "hero / grid / diagnostics / preflight"),
            Item.fallback(id: "write-contract-preview", rank: 10, label: "Write-contract preview", status: "locked", summary: "A future apply contract is previewable while writes remain forbidden.", evidence: "cannot execute source apply")
        ]
        return Self(
            schema: "humble.control.studio-control-readiness-pack.v1",
            generatedAt: "native-fallback",
            appId: app.id,
            appName: app.name,
            status: "attention",
            summary: "Control readiness is shown from native fallback until the HumbleControl localhost endpoint responds.",
            writes: false,
            sourceWrites: false,
            apply: "locked",
            itemCount: items.count,
            readyCount: items.filter { $0.status == "ready" }.count,
            lockedCount: items.filter { $0.status == "locked" }.count,
            attentionCount: items.filter { $0.status == "attention" }.count,
            blockedCount: items.filter { $0.status == "blocked" }.count,
            items: items,
            nativeParity: .fallback,
            recoveryWorkbench: .fallback,
            editIntentInbox: .fallback(appId: app.id),
            connectionDiagnostics: .fallback,
            ticketLanePreflightPreview: .fallback,
            navigation: .fallback(appId: app.id),
            applyDesignDocument: .fallback,
            previewFidelity: .fallback(appId: app.id),
            workspaceReadability: .fallback,
            writeContractPreview: .fallback(appId: app.id)
        )
    }
}

private struct StudioControlBridgeSnapshot {
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

private struct StudioControlBridgeFileState {
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

private struct StudioControlBridgeDeepLink: Identifiable {
    let id: String
    let label: String
    let path: String
    let url: URL?
    let status: String
}

private struct StudioControlBridgeStatusCheck: Identifiable {
    let id: String
    let label: String
    let status: String
    let detail: String
}

private struct StudioControlBridgeFlowStep: Identifiable {
    let rank: Int
    let label: String
    let status: String
    let detail: String

    var id: Int {
        rank
    }
}

private enum StudioControlBridgeActions {
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

private struct StudioControlBridgeActionBar: View {
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

private struct StudioControlBridgeConnectionCenterView: View {
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

private struct StudioControlBridgeAppRow: View {
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

private struct StudioControlBridgeDeepLinkMapView: View {
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

private struct StudioControlBridgeStatusChecksView: View {
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

private struct StudioControlBridgeEditPreviewView: View {
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

private struct StudioControlBridgeEndToEndFlowView: View {
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

private struct StudioControlReadinessCard: View {
    let item: StudioControlReadinessPack.Item

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("\(item.rank)/10")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                StudioControlStatusBadge(status: item.status)
            }
            Text(item.label)
                .font(.headline)
                .lineLimit(2)
            Text(item.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.evidence)
                .font(.caption2.weight(.medium))
                .foregroundStyle(StudioControlReadinessTone.color(for: item.status))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(14)
        .background(StudioControlReadinessTone.color(for: item.status).opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(StudioControlReadinessTone.color(for: item.status).opacity(0.28), lineWidth: 1)
        )
    }
}

private struct StudioControlReadinessNativeParityView: View {
    let parity: StudioControlReadinessPack.NativeParity

    var body: some View {
        StudioInspectorSection(title: "Native parity") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: parity.status)
                Text(parity.detail)
                    .foregroundStyle(.secondary)
                FlexiblePillStack(items: parity.sharedSchemas)
                StudioKeyValueRow(label: "Route", value: parity.route)
                StudioKeyValueRow(label: "API", value: parity.apiRoute)
            }
        }
    }
}

private struct StudioControlReadinessRecoveryView: View {
    let recovery: StudioControlReadinessPack.RecoveryWorkbench

    var body: some View {
        StudioInspectorSection(title: "JSON recovery workbench") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: recovery.status)
                Text(recovery.detail)
                    .foregroundStyle(.secondary)
                FlexiblePillStack(items: recovery.importModes)
                ForEach(recovery.exportFilenames, id: \.self) { filename in
                    StudioKeyValueRow(label: "Export", value: filename)
                }
            }
        }
    }
}

private struct StudioControlReadinessIntentView: View {
    let inbox: StudioControlReadinessPack.EditIntentInbox

    var body: some View {
        StudioInspectorSection(title: "Session edit intent inbox") {
            VStack(alignment: .leading, spacing: 12) {
                StudioKeyValueRow(label: "Session", value: inbox.sessionId)
                Text(inbox.detail)
                    .foregroundStyle(.secondary)
                ForEach(inbox.intents) { intent in
                    StudioControlReadinessRow(title: intent.label, subtitle: intent.detail, status: intent.status)
                }
            }
        }
    }
}

private struct StudioControlReadinessDiagnosticsView: View {
    let diagnostics: StudioControlReadinessPack.ConnectionDiagnostics

    var body: some View {
        StudioInspectorSection(title: "Connection health") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: diagnostics.status)
                Text(diagnostics.detail)
                    .foregroundStyle(.secondary)
                ForEach(diagnostics.causes) { cause in
                    StudioControlReadinessRow(title: cause.id, subtitle: cause.detail, status: cause.severity)
                }
            }
        }
    }
}

private struct StudioControlReadinessPreflightView: View {
    let preflight: StudioControlReadinessPack.TicketLanePreflightPreview

    var body: some View {
        StudioInspectorSection(title: "Ticket/lane preflight") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: preflight.status)
                Text(preflight.detail)
                    .foregroundStyle(.secondary)
                ForEach(preflight.checks) { check in
                    StudioControlReadinessRow(title: check.label, subtitle: check.command ?? check.detail, status: check.status)
                }
            }
        }
    }
}

private struct StudioControlReadinessNavigationView: View {
    let navigation: StudioControlReadinessPack.Navigation

    var body: some View {
        StudioInspectorSection(title: "Unified navigation") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: navigation.status)
                ForEach(navigation.primary) { item in
                    StudioControlReadinessRow(title: item.label, subtitle: "\(item.intent) / \(item.href)", status: "ready")
                }
            }
        }
    }
}

private struct StudioControlReadinessApplyDesignView: View {
    let document: StudioControlReadinessPack.ApplyDesignDocument

    var body: some View {
        StudioInspectorSection(title: document.title) {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: document.status)
                ForEach(document.sections) { section in
                    StudioControlReadinessRow(title: section.title, subtitle: section.bullets.joined(separator: " "), status: document.status)
                }
            }
        }
    }
}

private struct StudioControlReadinessFidelityView: View {
    let fidelity: StudioControlReadinessPack.PreviewFidelity

    var body: some View {
        StudioInspectorSection(title: "HumbleSudoku preview fidelity") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: fidelity.status)
                Text(fidelity.detail)
                    .foregroundStyle(.secondary)
                FlexiblePillStack(items: fidelity.checkpoints)
                StudioKeyValueRow(label: "Target", value: fidelity.targetAppId)
                StudioKeyValueRow(label: "Selected target active", value: fidelity.activeForSelectedApp ? "true" : "false")
            }
        }
    }
}

private struct StudioControlReadinessDensityView: View {
    let readability: StudioControlReadinessPack.WorkspaceReadability

    var body: some View {
        StudioInspectorSection(title: "Density/readability") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: readability.status)
                Text(readability.detail)
                    .foregroundStyle(.secondary)
                FlexiblePillStack(items: readability.regions)
                StudioKeyValueRow(label: "Density", value: readability.density)
            }
        }
    }
}

private struct StudioControlReadinessWriteContractView: View {
    let contract: StudioControlReadinessPack.WriteContractPreview

    var body: some View {
        StudioInspectorSection(title: "Write-contract preview") {
            VStack(alignment: .leading, spacing: 12) {
                StudioControlStatusBadge(status: contract.status)
                Text(contract.detail)
                    .foregroundStyle(.secondary)
                StudioKeyValueRow(label: "Contract", value: contract.contractId)
                FlexiblePillStack(items: contract.prerequisites)
                ForEach(contract.forbiddenUntilAccepted, id: \.self) { item in
                    StudioControlReadinessRow(title: "Forbidden", subtitle: item, status: "locked")
                }
            }
        }
    }
}

private struct StudioControlReadinessRow: View {
    let title: String
    let subtitle: String
    let status: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StudioControlStatusBadge(status: status)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct StudioControlStatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(StudioControlReadinessTone.color(for: status).opacity(0.14), in: Capsule())
            .foregroundStyle(StudioControlReadinessTone.color(for: status))
    }
}

private enum StudioControlReadinessTone {
    static func color(for status: String) -> Color {
        switch status.lowercased() {
        case "ready", "passed", "present", "available", "info", "required":
            return .green
        case "locked":
            return .secondary
        case "blocked", "failed", "missing":
            return .red
        default:
            return .orange
        }
    }

    static func summaryTone(for status: String) -> StudioInspectorSummaryTone {
        switch status.lowercased() {
        case "ready", "passed", "present", "available":
            return .success
        case "blocked", "failed", "missing":
            return .warning
        case "locked":
            return .neutral
        default:
            return .warning
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeString(_ key: Key, default defaultValue: String) -> String {
        (try? decodeIfPresent(String.self, forKey: key)) ?? defaultValue
    }

    func decodeBool(_ key: Key, default defaultValue: Bool) -> Bool {
        (try? decodeIfPresent(Bool.self, forKey: key)) ?? defaultValue
    }

    func decodeInt(_ key: Key, default defaultValue: Int) -> Int {
        (try? decodeIfPresent(Int.self, forKey: key)) ?? defaultValue
    }

    func decodeArray<T: Decodable>(_ key: Key, default defaultValue: [T]) -> [T] {
        (try? decodeIfPresent([T].self, forKey: key)) ?? defaultValue
    }

    func decodeValue<T: Decodable>(_ key: Key, default defaultValue: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? defaultValue
    }
}
