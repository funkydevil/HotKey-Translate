import SwiftUI

struct HotKeyTranslateApp: App {
    var body: some Scene {
        Window("HotKey Translate", id: "translator") {
            TranslatorWindowView()
        }
        .defaultSize(width: 900, height: 700)

        MenuBarExtra("HotKey Translate", systemImage: "character.bubble") {
            OpenTranslatorWindowButton()

            Divider()

            Button("Выйти") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

private struct OpenTranslatorWindowButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Открыть переводчик") {
            openWindow(id: "translator")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("o")
    }
}

HotKeyTranslateApp.main()
