import AppKit
import WebKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var webView: WKWebView?
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

            #translate_content {
                box-sizing: border-box;
                min-height: 360px;
                padding: 16px;
                overflow: auto;
                border: 1px solid color-mix(in srgb, CanvasText 20%, transparent);
                border-radius: 8px;
                line-height: 1.45;
                outline: none;
                white-space: pre-wrap;
            }

            #translate_content:focus {
                border-color: -webkit-focus-ring-color;
            }
        </style>
    </head>
    <body>
        <main>
            <div id="google_translate_element"></div>
            <div id="translate_content" contenteditable="true" spellcheck="true">
                Paste text here, then choose a language from the Google Translate selector above.
            </div>
        </main>
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = item.button {
            button.image = NSImage(named: NSImage.statusAvailableName)
            button.image?.isTemplate = true
            button.toolTip = "StatusBarApp"
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        statusItem = item
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        if popover == nil {
            let webView = WKWebView(frame: .zero)
            webView.autoresizingMask = [.width, .height]
            webView.loadHTMLString(
                Self.translateElementHTML,
                baseURL: Self.translateElementBaseURL
            )

            let contentViewController = NSViewController()
            contentViewController.view = webView
            contentViewController.preferredContentSize = NSSize(width: 480, height: 560)

            let popover = NSPopover()
            popover.behavior = .transient
            popover.animates = true
            popover.contentViewController = contentViewController

            self.popover = popover
            self.webView = webView
        }

        NSApp.activate(ignoringOtherApps: true)
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func showStatusMenu() {
        guard let button = statusItem?.button else {
            return
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(
            title: "Выйти",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
