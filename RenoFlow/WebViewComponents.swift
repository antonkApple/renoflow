import Combine
import SwiftUI
import WebKit

struct ProductWebView: View {
    let url: URL
    let onAddItem: (URL) -> Void
    @State private var browser = BrowserState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { browser.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!browser.canGoBack)
                Button { browser.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!browser.canGoForward)
                Button { browser.reload() } label: { Image(systemName: "arrow.clockwise") }
                Text(browser.currentURL?.absoluteString ?? url.absoluteString)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            WebView(url: url, state: browser)
            Button {
                onAddItem(browser.currentURL ?? url)
                dismiss()
            } label: {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Browser")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class BrowserState: NSObject, ObservableObject, WKNavigationDelegate {
    weak var webView: WKWebView?
    @Published var currentURL: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { update(webView) }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { update(webView) }

    private func update(_ webView: WKWebView) {
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let state: BrowserState

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = state
        state.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
