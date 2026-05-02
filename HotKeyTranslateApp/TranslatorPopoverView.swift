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
    var onOpenSettings: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TranslateWebView(state: state)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .background(.regularMaterial, in: Circle())
            .help("Settings")
            .padding(8)
        }
        .frame(width: 760, height: 450)
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
        webView.navigationDelegate = context.coordinator
        context.coordinator.loadOrInsertTextIfNeeded(
            state.clipboardText,
            version: state.clipboardVersion,
            into: webView
        )
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.loadOrInsertTextIfNeeded(
            state.clipboardText,
            version: state.clipboardVersion,
            into: nsView
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        private var loadedVersion = -1
        private var isPageLoaded = false
        private var pendingText = ""

        func loadOrInsertTextIfNeeded(_ text: String, version: Int, into webView: WKWebView) {
            guard version != loadedVersion else { return }
            loadedVersion = version
            pendingText = text

            if webView.url == nil {
                webView.load(URLRequest(url: TranslateWebView.translateURL))
                return
            }

            insertPendingText(into: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            insertPendingText(into: webView)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isPageLoaded = false
        }

        private func insertPendingText(into webView: WKWebView) {
            guard isPageLoaded else { return }

            let encodedText: String
            do {
                let data = try JSONEncoder().encode(pendingText)
                encodedText = String(data: data, encoding: .utf8) ?? "\"\""
            } catch {
                encodedText = "\"\""
            }

            webView.evaluateJavaScript(Self.insertTextScript(forEncodedText: encodedText))
        }

        private static func insertTextScript(forEncodedText encodedText: String) -> String {
            """
            (function() {
                const text = \(encodedText);
                const selectors = [
                    'textarea',
                    '[contenteditable="true"]',
                    '[role="textbox"]'
                ];

                function setNativeValue(element, value) {
                    const prototype = Object.getPrototypeOf(element);
                    const descriptor = Object.getOwnPropertyDescriptor(prototype, 'value');

                    if (descriptor && descriptor.set) {
                        descriptor.set.call(element, value);
                    } else {
                        element.value = value;
                    }
                }

                function dispatchInputEvents(element) {
                    element.dispatchEvent(new InputEvent('input', {
                        bubbles: true,
                        cancelable: true,
                        inputType: 'insertText',
                        data: text
                    }));
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                    element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true }));
                }

                function insertInto(element) {
                    element.focus();

                    if (element.isContentEditable) {
                        element.textContent = text;
                    } else {
                        setNativeValue(element, text);
                    }

                    dispatchInputEvents(element);
                    return true;
                }

                function findInput() {
                    for (const selector of selectors) {
                        const element = document.querySelector(selector);
                        if (element) { return element; }
                    }

                    return null;
                }

                let attempts = 0;
                const timer = setInterval(() => {
                    attempts += 1;
                    const input = findInput();

                    if (input && insertInto(input)) {
                        clearInterval(timer);
                        return;
                    }

                    if (attempts >= 40) {
                        clearInterval(timer);
                    }
                }, 250);
            })();
            """
        }
    }
}
