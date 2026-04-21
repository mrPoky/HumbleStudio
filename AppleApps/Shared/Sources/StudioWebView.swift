import SwiftUI
import WebKit

final class StudioWebCoordinator: NSObject, WKNavigationDelegate {
    private let model: StudioShellModel
    private weak var webView: WKWebView?

    init(model: StudioShellModel) {
        self.model = model
    }

    func attach(webView: WKWebView) {
        self.webView = webView
        model.connect(
            actions: StudioShellActions(
                loadBundledStudio: { [weak self] in
                    self?.loadBundledStudio()
                },
                reload: { [weak self] in
                    self?.webView?.reload()
                }
            )
        )
    }

    func loadBundledStudio() {
        guard let webView else { return }

        do {
            let rootURL = try StudioBundleLocator.resourceRoot()
            let indexURL = try StudioBundleLocator.bundledIndexURL()
            model.clearError()
            webView.loadFileURL(indexURL, allowingReadAccessTo: rootURL)
        } catch {
            model.report(error: error)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        model.clearError()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        model.report(error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        model.report(error: error)
    }
}

#if os(iOS)
struct StudioWebView: UIViewRepresentable {
    @Bindable var model: StudioShellModel

    func makeCoordinator() -> StudioWebCoordinator {
        StudioWebCoordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = makeConfiguredWebView(coordinator: context.coordinator)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#else
struct StudioWebView: NSViewRepresentable {
    @Bindable var model: StudioShellModel

    func makeCoordinator() -> StudioWebCoordinator {
        StudioWebCoordinator(model: model)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeConfiguredWebView(coordinator: context.coordinator)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

private extension StudioWebView {
    func makeConfiguredWebView(coordinator: StudioWebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true
        coordinator.attach(webView: webView)
        coordinator.loadBundledStudio()
        return webView
    }
}
