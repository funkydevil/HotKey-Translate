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
private final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let popover = NSPopover()
    private let settingsPopover = NSPopover()
    private let translatorState = TranslatorState()
    private let hotKeySettings = HotKeySettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        configureSettingsPopover()
        configureHotKeySettings()
        installHotKeyHandler()
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
        item.button?.action = #selector(handleStatusItemClick(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 760, height: 450)
        popover.contentViewController = NSHostingController(
            rootView: TranslatorPopoverView(state: translatorState) { [weak self] in
                self?.showSettingsPopover()
            }
        )
    }

    private func configureSettingsPopover() {
        settingsPopover.behavior = .transient
        settingsPopover.delegate = self
        settingsPopover.contentSize = NSSize(width: 420, height: 180)
        settingsPopover.contentViewController = NSHostingController(rootView: SettingsView(settings: hotKeySettings))
    }

    private func configureHotKeySettings() {
        hotKeySettings.onChange = { [weak self] in
            guard self?.settingsPopover.isShown != true else { return }
            self?.registerHotKey()
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu(from: sender)
            return
        }

        if popover.isShown {
            popover.performClose(sender)
            return
        }

        showPopover(relativeTo: sender)
    }

    private func showStatusMenu(from sender: NSStatusBarButton) {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(showSettingsPopover),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: sender.bounds.height + 4),
            in: sender
        )
    }

    @objc private func showSettingsPopover() {
        guard let button = statusItem?.button else { return }

        if settingsPopover.isShown {
            settingsPopover.performClose(nil)
            return
        }

        popover.performClose(nil)
        unregisterHotKey()
        settingsPopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        settingsPopover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        if notification.object as? NSPopover === settingsPopover {
            registerHotKey()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showPopover(relativeTo sender: NSStatusBarButton) {
        settingsPopover.performClose(nil)

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

    private func installHotKeyHandler() {
        guard eventHandlerRef == nil else { return }

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

    private func registerHotKey() {
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(
            signature: Self.fourCharCode("HTKT"),
            id: 1
        )
        let shortcut = hotKeySettings.shortcut

        RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
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

@MainActor
final class HotKeySettings: ObservableObject {
    @Published private(set) var shortcut: HotKeyShortcut {
        didSet {
            save()
            onChange?()
        }
    }

    var onChange: (() -> Void)?

    private let defaults = UserDefaults.standard
    private let keyCodeKey = "hotKey.keyCode"
    private let modifiersKey = "hotKey.modifiers"

    init() {
        let defaultShortcut = HotKeyShortcut(
            keyCode: UInt32(kVK_ANSI_X),
            carbonModifiers: UInt32(controlKey | cmdKey)
        )

        let keyCode = defaults.object(forKey: keyCodeKey) as? Int
        let modifiers = defaults.object(forKey: modifiersKey) as? Int

        if let keyCode, let modifiers {
            shortcut = HotKeyShortcut(
                keyCode: UInt32(keyCode),
                carbonModifiers: UInt32(modifiers)
            )
        } else {
            shortcut = defaultShortcut
        }
    }

    func update(shortcut: HotKeyShortcut) {
        self.shortcut = shortcut
    }

    func resetToDefault() {
        shortcut = HotKeyShortcut(
            keyCode: UInt32(kVK_ANSI_X),
            carbonModifiers: UInt32(controlKey | cmdKey)
        )
    }

    private func save() {
        defaults.set(Int(shortcut.keyCode), forKey: keyCodeKey)
        defaults.set(Int(shortcut.carbonModifiers), forKey: modifiersKey)
    }
}

struct HotKeyShortcut: Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    var displayText: String {
        "\(modifierDisplayText)\(Self.keyDisplayText(for: keyCode))"
    }

    private var modifierDisplayText: String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        return parts.joined()
    }

    private static func keyDisplayText(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Escape: return "Esc"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        default: return "Key \(keyCode)"
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: HotKeySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)

            Text("Current hotkey: \(settings.shortcut.displayText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Text("Hotkey")
                    .frame(width: 80, alignment: .leading)

                ShortcutRecorderView(shortcut: settings.shortcut) { shortcut in
                    settings.update(shortcut: shortcut)
                }
                .frame(width: 180, height: 34)

                Button("Reset") {
                    settings.resetToDefault()
                }
            }

            Spacer()
        }
        .padding(22)
        .frame(width: 420, height: 180)
    }
}

private struct ShortcutRecorderView: NSViewRepresentable {
    var shortcut: HotKeyShortcut
    var onChange: (HotKeyShortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onChange = onChange
        view.shortcut = shortcut
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.onChange = onChange
        nsView.shortcut = shortcut
    }
}

private final class ShortcutRecorderNSView: NSView {
    private let button = ShortcutRecorderButton(frame: .zero)

    var shortcut = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_X),
        carbonModifiers: UInt32(controlKey | cmdKey)
    ) {
        didSet {
            button.shortcut = shortcut
        }
    }

    var onChange: ((HotKeyShortcut) -> Void)? {
        didSet {
            button.onChange = onChange
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        button.frame = bounds
    }
}

private final class ShortcutRecorderButton: NSButton {
    var shortcut = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_X),
        carbonModifiers: UInt32(controlKey | cmdKey)
    ) {
        didSet {
            updateTitle()
        }
    }

    var onChange: ((HotKeyShortcut) -> Void)?
    private var isRecording = false {
        didSet {
            updateTitle()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(startRecording)
        focusRingType = .default
        font = .monospacedSystemFont(ofSize: 15, weight: .medium)
        updateTitle()
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard isRecording, modifiers != 0 else {
            super.keyDown(with: event)
            return
        }

        let nextShortcut = HotKeyShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: modifiers
        )
        shortcut = nextShortcut
        onChange?(nextShortcut)
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    private func updateTitle() {
        title = isRecording ? "Press shortcut" : shortcut.displayText
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }
}

HotKeyTranslateApp.main()
