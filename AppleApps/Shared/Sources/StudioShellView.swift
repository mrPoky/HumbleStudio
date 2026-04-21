import SwiftUI
import UniformTypeIdentifiers

struct StudioShellView: View {
    @State private var model = StudioShellModel()
    @State private var isImportingFile = false

    var body: some View {
        NavigationStack {
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
}
