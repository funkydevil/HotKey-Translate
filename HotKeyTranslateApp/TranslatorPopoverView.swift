import SwiftUI
import WebKit

@MainActor
final class TranslatorState: ObservableObject {
    @Published private(set) var clipboardText = ""
    @Published private(set) var clipboardVersion = 0

    func setClipboardText(_ text: String) {
        clipboardText = text
        clipboardVersion += 1
    }
}

struct TranslatorPopoverView: View {
    @ObservedObject var state: TranslatorState

    var body: some View {
        VStack(spacing: 0) {
            TranslateWebView(state: state)

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
        .frame(width: 760, height: 500)
    }
}

struct TranslateWebView: NSViewRepresentable {
    @ObservedObject var state: TranslatorState

    private static let translateURL = URL(string: "https://translate.google.com/?sl=auto&tl=en&op=translate")!
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
        const modeLabels = new Set([
            'text',
            'text translation',
            'images',
            'image translation',
            'documents',
            'document translation',
            'websites',
            'website translation',
            'текст',
            'изображения',
            'документы',
            'сайты',
            'веб-сайты'
        ]);

        function normalize(value) {
            return (value || '').trim().toLowerCase();
        }

        function labelsFor(element) {
            return [
                element.getAttribute('aria-label'),
                element.getAttribute('title'),
                element.getAttribute('data-tooltip'),
                element.textContent
            ].map(normalize);
        }

        function isModeSwitcherElement(element) {
            return labelsFor(element).some((label) => modeLabels.has(label));
        }

        function hideModeSwitcherBlock() {
            document.querySelectorAll('a, button, [role="button"], [role="link"], [role="tab"]').forEach((element) => {
                if (!isModeSwitcherElement(element)) { return; }

                let container = element;
                for (let depth = 0; depth < 6 && container.parentElement; depth += 1) {
                    const modeItemCount = Array.from(
                        container.querySelectorAll('a, button, [role="button"], [role="link"], [role="tab"]')
                    ).filter(isModeSwitcherElement).length;

                    const containerText = normalize(container.textContent);
                    if (modeItemCount >= 2 && (containerText.includes('text') || containerText.includes('текст'))) {
                        container.style.setProperty('display', 'none', 'important');
                        return;
                    }

                    container = container.parentElement;
                }

                element.style.setProperty('display', 'none', 'important');
            });
        }

        function hideNavigationByHeading(headingText) {
            document.querySelectorAll('nav, [role="navigation"]').forEach((navigation) => {
                const heading = navigation.querySelector('h1, h2, h3, [role="heading"]');
                if (normalize(heading?.textContent) === headingText) {
                    navigation.style.setProperty('display', 'none', 'important');
                }
            });
        }

        function compactTopSpacing() {
            const translationInput = document.querySelector('textarea, [contenteditable="true"], [role="textbox"]');
            const main = document.querySelector('main, [role="main"]');

            [main, translationInput].filter(Boolean).forEach((element) => {
                element.style.setProperty('margin-top', '0', 'important');
                element.style.setProperty('padding-top', '0', 'important');
            });

            let container = translationInput || main;
            for (let depth = 0; depth < 10 && container; depth += 1) {
                container.style.setProperty('margin-top', '0', 'important');
                container.style.setProperty('padding-top', '0', 'important');
                container.style.setProperty('top', '0', 'important');
                container = container.parentElement;
            }

            if (main) {
                main.style.setProperty('margin-top', '-64px', 'important');
                main.style.setProperty('transform', 'translateY(-64px)', 'important');
            }
        }

        function cleanupGoogleTranslateChrome() {
            document.querySelectorAll('a, button, [role="button"], [role="link"]').forEach((element) => {
                if (labelsFor(element).some((label) => hiddenLabels.has(label))) {
                    element.style.setProperty('display', 'none', 'important');
                }
            });
            hideNavigationByHeading('translation types');
            hideNavigationByHeading('side panels');
            hideModeSwitcherBlock();
            compactTopSpacing();
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

                main,
                c-wiz,
                [role="main"] {
                    margin-top: 0 !important;
                    padding-top: 0 !important;
                }

                nav[aria-label="Translation types"],
                nav[aria-label="Side panels"],
                [role="navigation"][aria-label="Translation types"],
                [role="navigation"][aria-label="Side panels"] {
                    display: none !important;
                }

                body > div,
                body > c-wiz {
                    margin-top: 0 !important;
                    padding-top: 0 !important;
                }

                main,
                [role="main"] {
                    margin-top: -64px !important;
                    transform: translateY(-64px) !important;
                }
            `;
            document.documentElement.appendChild(style);
        }

        cleanupGoogleTranslateChrome();
        window.hotkeyTranslateCleanupObserver = new MutationObserver(cleanupGoogleTranslateChrome);
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
        context.coordinator.loadTextIfNeeded(
            state.clipboardText,
            version: state.clipboardVersion,
            into: webView
        )
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.loadTextIfNeeded(
            state.clipboardText,
            version: state.clipboardVersion,
            into: nsView
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        private var loadedVersion = -1

        func loadTextIfNeeded(_ text: String, version: Int, into webView: WKWebView) {
            guard version != loadedVersion else { return }
            loadedVersion = version
            webView.load(URLRequest(url: Self.translateURL(for: text)))
        }

        private static func translateURL(for text: String) -> URL {
            guard !text.isEmpty,
                  var components = URLComponents(string: "https://translate.google.com/") else {
                return TranslateWebView.translateURL
            }

            components.queryItems = [
                URLQueryItem(name: "sl", value: "auto"),
                URLQueryItem(name: "tl", value: "en"),
                URLQueryItem(name: "text", value: text),
                URLQueryItem(name: "op", value: "translate")
            ]

            return components.url ?? TranslateWebView.translateURL
        }
    }
}
