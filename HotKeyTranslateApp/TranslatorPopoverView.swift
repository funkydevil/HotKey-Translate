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
    private static let translateURL = URL(string: "https://translate.google.com/?sl=auto&tl=ru&op=translate")!
    private static let hideHeaderScript = """
    (function() {
        const styleId = 'hotkey-translate-hide-header';
        const hiddenLabels = new Set([
            'history',
            'saved',
            'send feedback',
            'send us feedback',
            'история',
            'сохраненные',
            'сохранённые',
            'сохранено',
            'отправить отзыв',
            'отправить отзыв о google переводчике'
        ]);

        function normalize(value) {
            return (value || '').trim().toLowerCase();
        }

        function hideHistoryAndSavedButtons() {
            document.querySelectorAll('a, button, [role="button"], [role="link"]').forEach((element) => {
                const labels = [
                    element.getAttribute('aria-label'),
                    element.getAttribute('title'),
                    element.getAttribute('data-tooltip'),
                    element.textContent
                ].map(normalize);

                if (labels.some((label) => hiddenLabels.has(label))) {
                    element.style.setProperty('display', 'none', 'important');
                }
            });
        }

        if (window.hotkeyTranslateCleanupObserver) {
            window.hotkeyTranslateCleanupObserver.disconnect();
        }

        if (!document.getElementById(styleId)) {
            const style = document.createElement('style');
            style.id = styleId;
            style.textContent = `
                header,
                [role="banner"],
                #gb,
                .gb_wa,
                .gb_xa,
                .gb_za,
                .gb_1a,
                .gb_2a,
                .gb_3a,
                a[href*="history"],
                a[href*="saved"],
                button[aria-label="History"],
                button[aria-label="Saved"],
                button[aria-label="Send feedback"],
                button[aria-label="Send us feedback"],
                [aria-label="History"],
                [aria-label="Saved"],
                [aria-label="Send feedback"],
                [aria-label="Send us feedback"],
                [data-tooltip="History"],
                [data-tooltip="Saved"],
                [data-tooltip="Send feedback"],
                [data-tooltip="Send us feedback"] {
                    display: none !important;
                }

                html,
                body {
                    margin-top: 0 !important;
                    padding-top: 0 !important;
                }
            `;
            document.documentElement.appendChild(style);
        }

        hideHistoryAndSavedButtons();
        window.hotkeyTranslateCleanupObserver = new MutationObserver(hideHistoryAndSavedButtons);
        window.hotkeyTranslateCleanupObserver.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
    })();
    """

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let hideHeaderUserScript = WKUserScript(
            source: Self.hideHeaderScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(hideHeaderUserScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.load(URLRequest(url: Self.translateURL))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
