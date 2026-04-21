import SwiftUI

struct StudioShellView: View {
    @State private var model = StudioShellModel()

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
        .disabled(!model.isConnected)
    }
}
