# HotKey Translate Project Memory

## Purpose

HotKey Translate is a small macOS menu bar app for quick translation through Google Translate.
The app reads the current text from the system clipboard when the global hotkey is pressed, opens a compact popover from the status bar, and shows Google Translate inside a `WKWebView`.

## Current Behavior

- Runs as a macOS SwiftUI app with an `NSApplicationDelegate`.
- Shows a menu bar status item with a `character.bubble` SF Symbol.
- Left click opens or closes the translator popover.
- Right click opens a menu with Settings and Quit.
- Default global hotkey is `Control + Command + X`.
- The hotkey can be changed in the settings popover and is stored in `UserDefaults`.
- On hotkey press, the app reads `NSPasteboard.general.string(forType: .string)`.
- The clipboard text is stored in `TranslatorState` with a monotonically increasing `clipboardVersion`.
- Google Translate is loaded without putting the text into the URL query.
- After the page loads, JavaScript inserts the clipboard text into the active Google Translate input field and dispatches input/change events.

## Important Files

- `HotKeyTranslateApp/main.swift`
  - App entry point.
  - Status bar setup.
  - Global hotkey registration with Carbon APIs.
  - Settings popover.
  - Clipboard read on hotkey press.

- `HotKeyTranslateApp/TranslatorPopoverView.swift`
  - Translator popover SwiftUI view.
  - `WKWebView` bridge.
  - Google Translate UI cleanup script.
  - JavaScript text insertion into Google Translate.

- `HotKeyTranslateApp/Info.plist`
  - App metadata.

- `HotKeyTranslateApp.xcodeproj/project.pbxproj`
  - Xcode project configuration.

## Recent Design Decision

The app previously passed the text to Google Translate through a `text` URL query parameter.
This was changed so the URL no longer contains the translated text. The WebView now loads the normal Google Translate page and inserts the text through JavaScript after navigation finishes.

Reasons:

- Avoid exposing full clipboard text in the URL.
- Avoid URL length limits.
- Keep the WebView reusable for repeated translations.

Tradeoff:

- Google Translate DOM is external and may change. The JS insertion selectors may need updates if Google changes its page structure.

## Build Check

Use a workspace-local DerivedData directory so sandboxed builds do not need to write to `~/Library/Developer/Xcode/DerivedData`.

```sh
xcodebuild -project HotKeyTranslateApp.xcodeproj -scheme HotKeyTranslateApp -destination generic/platform=macOS CODE_SIGNING_ALLOWED=NO -derivedDataPath .derived build
```

## Suggested Memory Locations

Recommended current location:

- `PROJECT_MEMORY.md` at the repository root. Best for human-readable project memory that should be visible immediately.

Other reasonable options:

- `README.md` if this should become public-facing project documentation.
- `docs/PROJECT_MEMORY.md` if the project grows and documentation needs its own directory.
- `AGENTS.md` if the content should become operational instructions for coding agents rather than general project notes.

