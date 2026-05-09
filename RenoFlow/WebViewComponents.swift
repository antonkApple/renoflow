import Combine
import SwiftUI
import WebKit

struct ProductWebView: View {
    let url: URL
    let onAddItem: (URL) -> Void
    @StateObject private var browser = BrowserState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            browserToolbar

            if browser.isLoading {
                RenoProgressBar(value: browser.estimatedProgress, height: 3)
            }

            WebView(url: url, state: browser)
                .background(RenoTheme.ColorToken.background)

            Button {
                onAddItem(browser.currentURL ?? url)
                dismiss()
            } label: {
                Label("Save Product", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RenoPrimaryButtonStyle())
            .padding(RenoTheme.Spacing.lg)
            .background(RenoTheme.ColorToken.background)
        }
        .background(RenoTheme.ColorToken.background.ignoresSafeArea())
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
        .tint(RenoTheme.ColorToken.accent)
    }

    private var browserToolbar: some View {
        HStack(spacing: RenoTheme.Spacing.sm) {
            Button { browser.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!browser.canGoBack)
            Button { browser.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!browser.canGoForward)
            Button { browser.reload() } label: { Image(systemName: "arrow.clockwise") }
            Text(browser.currentURL?.absoluteString ?? url.absoluteString)
                .font(.caption)
                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, RenoTheme.Spacing.sm)
                .padding(.vertical, RenoTheme.Spacing.xs)
                .background(RenoTheme.ColorToken.secondarySurface, in: Capsule())
            Spacer(minLength: 0)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(RenoTheme.ColorToken.text)
        .padding(.horizontal, RenoTheme.Spacing.lg)
        .padding(.vertical, RenoTheme.Spacing.md)
        .background(RenoTheme.ColorToken.background)
    }
}

@MainActor
final class BrowserState: NSObject, ObservableObject, WKNavigationDelegate {
    weak var webView: WKWebView?
    @Published var currentURL: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress = 0.0

    private var progressObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        update(webView)
        progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.estimatedProgress = webView.estimatedProgress
            }
        }
        loadingObservation = webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.isLoading = webView.isLoading
            }
        }
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { update(webView) }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { update(webView) }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { update(webView) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { update(webView) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { update(webView) }

    private func update(_ webView: WKWebView) {
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        estimatedProgress = webView.estimatedProgress
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let state: BrowserState

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WebViewConfigurationFactory.makeConfiguration())
        webView.navigationDelegate = state
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        state.attach(webView)
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
enum WebViewPrewarmer {
    private static var prewarmedWebView: WKWebView?

    static func prewarm() {
        guard prewarmedWebView == nil else { return }
        let webView = WKWebView(frame: .zero, configuration: WebViewConfigurationFactory.makeConfiguration())
        prewarmedWebView = webView
        webView.loadHTMLString("<html><body></body></html>", baseURL: URL(string: "https://renoflow.local"))
    }
}

enum WebViewConfigurationFactory {
    private static let processPool = WKProcessPool()

    static func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = processPool
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        return configuration
    }
}
