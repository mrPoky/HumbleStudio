import SwiftUI
import WebKit

final class StudioWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    fileprivate static let shellMessageHandlerName = "studioShell"

    private let model: StudioShellModel
    private weak var webView: WKWebView?
    private var hasResumedPreferredSource = false

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
                loadDemo: { [weak self] in
                    self?.loadDemo()
                },
                importPayload: { [weak self] fileName, data in
                    self?.loadNativePayload(fileName: fileName, data: data)
                },
                loadRemoteURL: { [weak self] url in
                    self?.loadRemoteURL(url)
                },
                navigateBack: { [weak self] in
                    self?.navigateBack()
                },
                navigateForward: { [weak self] in
                    self?.navigateForward()
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
        model.markPageReady()
        runJavaScript("if (window.syncNativeShellState) { window.syncNativeShellState(); }")
        if !hasResumedPreferredSource {
            hasResumedPreferredSource = true
            model.resumePreferredSourceAfterLaunch()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        model.report(error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        model.report(error: error)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == Self.shellMessageHandlerName,
            let body = message.body as? [String: Any],
            let type = body["type"] as? String,
            type == "shellState",
            let payload = body["payload"] as? [String: Any]
        else {
            return
        }

        model.updateShellState(
            title: payload["title"] as? String,
            breadcrumb: payload["breadcrumb"] as? String,
            sourceLabel: payload["sourceLabel"] as? String,
            sourceValue: payload["sourceValue"] as? String,
            statusText: payload["statusText"] as? String,
            statusLevel: payload["statusLevel"] as? String,
            canGoBack: payload["canGoBack"] as? Bool,
            canGoForward: payload["canGoForward"] as? Bool
        )
    }

    private func loadDemo() {
        runJavaScript("loadDemo();")
    }

    private func loadRemoteURL(_ url: String) {
        do {
            let urlLiteral = try makeJavaScriptStringLiteral(url)
            runJavaScript("""
            (async function() {
                const input = document.getElementById('urlInput');
                if (input) input.value = \(urlLiteral);
                await loadFromUrl();
            })();
            """)
        } catch {
            model.report(error: error)
        }
    }

    private func loadNativePayload(fileName: String, data: Data) {
        do {
            let fileNameLiteral = try makeJavaScriptStringLiteral(fileName)
            let dataLiteral = try makeJavaScriptStringLiteral(data.base64EncodedString())
            runJavaScript("loadNativePayload(\(fileNameLiteral), \(dataLiteral));")
        } catch {
            model.report(error: error)
        }
    }

    private func navigateBack() {
        runJavaScript("if (window.navigateBack) { window.navigateBack(); }")
    }

    private func navigateForward() {
        runJavaScript("if (window.navigateForward) { window.navigateForward(); }")
    }

    private func runJavaScript(_ script: String) {
        let wrappedScript = """
        (function() {
            \(script)
            return true;
        })();
        """

        webView?.evaluateJavaScript(wrappedScript) { [weak self] _, error in
            if let error {
                self?.model.report(error: error)
            }
        }
    }

    private func makeJavaScriptStringLiteral(_ value: String) throws -> String {
        let encoded = try JSONSerialization.data(withJSONObject: [value], options: [])
        let arrayLiteral = String(decoding: encoded, as: UTF8.self)
        return String(arrayLiteral.dropFirst().dropLast())
    }
}

#if os(iOS)
struct StudioWebView: UIViewRepresentable {
    @ObservedObject var model: StudioShellModel

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
    @ObservedObject var model: StudioShellModel

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
        configuration.userContentController.add(coordinator, name: StudioWebCoordinator.shellMessageHandlerName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true
        coordinator.attach(webView: webView)
        coordinator.loadBundledStudio()
        return webView
    }
}
