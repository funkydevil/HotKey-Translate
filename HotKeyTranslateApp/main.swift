import Carbon.HIToolbox
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
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let popover = NSPopover()
    private let translatorState = TranslatorState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        registerHotKey()
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
        popover.contentViewController = NSHostingController(rootView: TranslatorPopoverView(state: translatorState))
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        showPopover(relativeTo: sender)
    }

    private func showPopover(relativeTo sender: NSStatusBarButton) {
        if popover.isShown {
            popover.contentViewController?.view.window?.makeKey()
            return
        }

        popover.show(
            relativeTo: sender.bounds,
            of: sender,
            preferredEdge: .minY
        )
        popover.contentViewController?.view.window?.makeKey()
    }

    private func registerHotKey() {
        let hotKeyID = EventHotKeyID(
            signature: Self.fourCharCode("HTKT"),
            id: 1
        )
        let modifiers = UInt32(controlKey | optionKey | cmdKey)

        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return noErr }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr, hotKeyID.id == 1 else { return status }

            let appDelegate = Unmanaged<AppDelegate>
                .fromOpaque(userData)
                .takeUnretainedValue()
            Task { @MainActor in
                appDelegate.openTranslatorFromHotKey()
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
    }

    private func openTranslatorFromHotKey() {
        let clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
        translatorState.setClipboardText(clipboardText)

        guard let button = statusItem?.button else { return }
        showPopover(relativeTo: button)
    }

    private static func fourCharCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}

HotKeyTranslateApp.main()
