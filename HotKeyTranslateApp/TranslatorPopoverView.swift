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
    private static let translateElementBaseURL = URL(string: "https://translate.google.com")!
    private static let translateElementHTML = """
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Google Translate</title>
        <style>
            :root {
                color-scheme: light dark;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                background: Canvas;
                color: CanvasText;
            }

            body {
                margin: 0;
                min-height: 100vh;
            }

            main {
                box-sizing: border-box;
                display: grid;
                grid-template-rows: auto 1fr;
                gap: 16px;
                min-height: 100vh;
                padding: 24px;
            }

            #google_translate_element {
                min-height: 40px;
            }

            .panes {
                display: grid;
                grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
                gap: 16px;
                min-height: 0;
            }

            .pane {
                display: grid;
                grid-template-rows: auto 1fr;
                min-width: 0;
                min-height: 0;
            }

            .pane_header {
                color: color-mix(in srgb, CanvasText 68%, transparent);
                font-size: 12px;
                font-weight: 600;
                letter-spacing: 0.04em;
                margin-bottom: 8px;
                text-transform: uppercase;
            }

            .text_box {
                box-sizing: border-box;
                min-height: 0;
                padding: 16px;
                overflow: auto;
                border: 1px solid color-mix(in srgb, CanvasText 20%, transparent);
                border-radius: 8px;
                line-height: 1.45;
                outline: none;
                white-space: pre-wrap;
            }

            .text_box:focus {
                border-color: -webkit-focus-ring-color;
            }

            #translation_text {
                background: color-mix(in srgb, CanvasText 4%, transparent);
            }

            @media (max-width: 760px) {
                .panes {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>
    <body>
        <main>
            <div id="google_translate_element" class="notranslate" translate="no"></div>
            <div class="panes">
                <section class="pane notranslate" translate="no">
                    <div class="pane_header">Оригинал</div>
                    <div id="source_text" class="text_box" contenteditable="true" spellcheck="true">
                        Paste source text here.
                    </div>
                </section>
                <section class="pane">
                    <div class="pane_header notranslate" translate="no">Перевод</div>
                    <div id="translation_text" class="text_box">
                        Paste source text here.
                    </div>
                </section>
            </div>
        </main>
        <script>
            const sourceText = document.getElementById('source_text');
            const translationText = document.getElementById('translation_text');

            sourceText.addEventListener('input', () => {
                translationText.textContent = sourceText.innerText;
            });
        </script>
        <script>
            function googleTranslateElementInit() {
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    layout: google.translate.TranslateElement.InlineLayout.HORIZONTAL,
                    autoDisplay: false
                }, 'google_translate_element');
            }
        </script>
        <script src="https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script>
    </body>
    </html>
    """

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.loadHTMLString(
            Self.translateElementHTML,
            baseURL: Self.translateElementBaseURL
        )
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
