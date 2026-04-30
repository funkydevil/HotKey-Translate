import SwiftUI

struct HotKeyTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "character.bubble",
            accessibilityDescription: "HotKey Translate"
        )
        item.button?.image?.isTemplate = true
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        statusItem = item
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 760, height: 500)
        popover.contentViewController = NSHostingController(rootView: TranslatorPopoverView())
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(
            relativeTo: sender.bounds,
            of: sender,
            preferredEdge: .minY
        )
        popover.contentViewController?.view.window?.makeKey()
    }
}

HotKeyTranslateApp.main()
