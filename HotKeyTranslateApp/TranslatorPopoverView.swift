import SwiftUI
import WebKit

struct TranslatorWindowView: View {
    var body: some View {
        VStack(spacing: 0) {
            TranslateWebView()

            Divider()

            HStack {
                Spacer()

                Button("Выйти") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 760, minHeight: 560)
        .background(WindowFrameConfigurator())
    }
}

private struct WindowFrameConfigurator: NSViewRepresentable {
    private static var didConfigureInitialFrame = false

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            configure(window: view.window)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }

        window.title = "HotKey Translate"
        window.minSize = NSSize(width: 760, height: 560)

        guard !Self.didConfigureInitialFrame else { return }
        Self.didConfigureInitialFrame = true

        let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame ?? NSRect(
            x: 0,
            y: 0,
            width: 1440,
            height: 900
        )
        let width = max(760, visibleFrame.width * 0.5)
        let height = max(560, visibleFrame.height * 0.8)
        let frame = NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )

        window.setFrame(frame, display: true)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct TranslateWebView: NSViewRepresentable {
    private static let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    private static let translateURL = URL(string: "https://translate.google.com/m?sl=auto&tl=ru")!

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.customUserAgent = Self.mobileUserAgent
        webView.load(URLRequest(url: Self.translateURL))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
