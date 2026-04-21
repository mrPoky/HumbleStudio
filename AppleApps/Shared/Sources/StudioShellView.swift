import SwiftUI
import UniformTypeIdentifiers

struct StudioShellView: View {
    @State private var model = StudioShellModel()
    @State private var isImportingFile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nativeContextBar

                ZStack {
                    StudioWebView(model: model)
                        .ignoresSafeArea()

                    if let errorMessage = model.errorMessage {
                        ContentUnavailableView(
                            "Unable to load studio",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .padding(24)
                    }
                }
            }
            .navigationTitle("HumbleStudio")
            .toolbar {
                shellToolbar
            }
        }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: Self.supportedImportTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                model.importFile(at: url)
            case .failure(let error):
                model.report(error: error)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioOpenImport)) { _ in
            isImportingFile = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioLoadDemo)) { _ in
            model.loadDemo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioLoadHome)) { _ in
            model.loadBundledStudio()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studioReload)) { _ in
            model.reload()
        }
    }

    private static var supportedImportTypes: [UTType] {
        [UTType(filenameExtension: "humblebundle") ?? .zip, .zip, .json]
    }

    @ToolbarContentBuilder
    private var shellToolbar: some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup(placement: .topBarTrailing) {
            toolbarButtons
        }
        #else
        ToolbarItemGroup {
            toolbarButtons
        }
        #endif
    }

    @ViewBuilder
    private var toolbarButtons: some View {
        Button {
            isImportingFile = true
        } label: {
            Label("Open", systemImage: "folder")
        }
        .disabled(!model.isPageReady)

        Button {
            model.loadDemo()
        } label: {
            Label("Demo", systemImage: "sparkles")
        }
        .disabled(!model.isPageReady)

        Button {
            model.loadBundledStudio()
        } label: {
            Label("Home", systemImage: "house")
        }
        .disabled(!model.isConnected)

        Button {
            model.reload()
        } label: {
            Label("Reload", systemImage: "arrow.clockwise")
        }
        .disabled(!model.isPageReady)
    }

    private var nativeContextBar: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                expandedContextBar
                compactContextBar
            }
            Divider()
                .opacity(0.35)
        }
        .background(.thinMaterial)
    }

    private var expandedContextBar: some View {
        HStack(spacing: 12) {
            contextHeading
            Spacer(minLength: 12)
            contextChip(icon: "shippingbox", text: model.sourceSummary)
            statusChip
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var compactContextBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            contextHeading
            HStack(spacing: 8) {
                contextChip(icon: "shippingbox", text: model.sourceSummary)
                statusChip
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var contextHeading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.pageTitle)
                .font(.headline)
                .lineLimit(1)
            Text(model.breadcrumb)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var statusChip: some View {
        HStack(spacing: 8) {
            if model.statusLevel == "loading" {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: statusSymbolName)
                    .font(.caption.weight(.semibold))
            }

            Text(model.statusText)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusBackground, in: Capsule())
        .foregroundStyle(statusForeground)
    }

    private func contextChip(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .lineLimit(1)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.45), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private var statusSymbolName: String {
        switch model.statusLevel {
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
        switch model.statusLevel {
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
        switch model.statusLevel {
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
