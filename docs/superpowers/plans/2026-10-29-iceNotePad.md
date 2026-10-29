# iceNotePad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

iceNotePad is an ultra-lightweight, native macOS (Apple Silicon M1 optimized) text editor designed to match the simplicity and convenience of Windows Notepad, featuring:
- **Plain-text enforcement**: Automatically strips all rich text formatting on paste.
- **Multiple tabs**: Tab bar with new tab (`+`), close tab (`✕`), tab switching shortcuts (`Cmd+1..9`, `Cmd+T`, `Cmd+W`).
- **Session state persistence**: Automatically preserves all open tabs, contents, and active tab index across app restarts.
- **Windows Notepad parity**: Status bar (Line, Column, Characters, UTF-8, Line endings), Find/Replace (`Cmd+F`), Font Zoom (`Cmd+` / `Cmd-`), Open/Save/Save As (`Cmd+O`, `Cmd+S`, `Cmd+Shift+S`).
- **Native packaging**: Packaged into a standalone `iceNotePad.app` bundle that can be placed in `/Applications` or launched via dock/Spotlight.

---

## File Structure

```
iceNotePad/
├── Package.swift
├── Sources/
│   └── iceNotePad/
│       ├── App/
│       │   ├── iceNotePadApp.swift          // App entry point and window setup
│       │   └── MenuCommands.swift           // Native macOS menus and keyboard shortcuts
│       ├── Models/
│       │   ├── NoteTab.swift                // Tab data model (id, title, content, fileURL, isModified)
│       │   ├── TabManager.swift             // Tab lifecycle, switching, session persistence (load/save)
│       │   └── AppSettings.swift            // Font size, word wrap, settings storage
│       ├── Views/
│       │   ├── MainWindowView.swift         // Main container combining TabBar, Editor, and StatusBar
│       │   ├── TabBarView.swift             // Minimalist tab strip with '+' and tab items
│       │   ├── PlainTextEditorView.swift    // AppKit NSTextView wrapper enforcing pure plain-text
│       │   ├── FindReplaceBarView.swift     // In-editor search and replace bar
│       │   └── StatusBarView.swift          // Bottom bar: Ln, Col, Chars, Encoding, Zoom
│       └── Helpers/
│           └── FileOperations.swift         // Open, Save, Save As helper utilities
├── Tests/
│   └── iceNotePadTests/
│       ├── TabManagerTests.swift            // Tests for tab lifecycle and persistence
│       └── FileOperationsTests.swift        // Tests for file read/write
├── scripts/
│   ├── build_app.sh                         // Builds release binary and bundles into iceNotePad.app
│   └── generate_icon.swift                  // Generates native app icon (.icns)
└── docs/
    └── superpowers/plans/
        └── 2026-10-29-iceNotePad.md
```

---

## Task Decomposition

### Task 1: Swift Package Scaffolding & Data Models (TDD)
- **Files**: `Package.swift`, `Sources/iceNotePad/Models/NoteTab.swift`, `Sources/iceNotePad/Models/TabManager.swift`, `Tests/iceNotePadTests/TabManagerTests.swift`
- **Goal**: Establish the Swift package structure, `NoteTab` model, and `TabManager` with robust persistence logic (saving to and loading from JSON in Application Support).
- **Steps**:
  - [x] Initialize `Package.swift` with macOS 13+ target.
  - [x] Write unit tests in `TabManagerTests.swift` verifying:
    - Adding tabs, closing tabs, switching active tab.
    - Saving tabs to JSON and restoring tabs on reload.
    - Preserving unsaved tab contents when reopening.
  - [x] Implement `NoteTab.swift` (Codable, Identifiable, ObservableObject).
  - [x] Implement `TabManager.swift` with auto-save debounce and session restoration.
  - [x] Run `swift test` and ensure all tests pass.
  - [x] Git commit.

### Task 2: Plain Text Editor with Strict Format Stripping (AppKit NSTextView)
- **Files**: `Sources/iceNotePad/Views/PlainTextEditorView.swift`
- **Goal**: Create a native `NSTextView` wrapper in SwiftUI that:
  - Strictly forces plain text: intercepts pasteboard operations so any HTML/RTF/styling is instantly stripped to `NSPasteboard.PasteboardType.string`.
  - Disallows rich text formatting (`isRichText = false`, `importsGraphics = false`).
  - Reports cursor position (Line number, Column number) and selection changes to the parent model.
  - Supports dynamic font scaling (Zoom).
- **Steps**:
  - [x] Create `PlainTextEditorView.swift` implementing `NSViewRepresentable`.
  - [x] Subclass `NSTextView` to override `paste(_:)` and `readSelection(from: [NSPasteboard.PasteboardType])` ensuring only plain string is inserted.
  - [x] Connect text storage changes and selection changes to update `NoteTab.content`, `cursorLine`, and `cursorColumn`.
  - [x] Run `swift build` to verify clean compilation.
  - [x] Git commit.

### Task 3: Multi-Tab Bar & Main UI Layout
- **Files**: `Sources/iceNotePad/Views/TabBarView.swift`, `Sources/iceNotePad/Views/StatusBarView.swift`, `Sources/iceNotePad/Views/FindReplaceBarView.swift`, `Sources/iceNotePad/Views/MainWindowView.swift`
- **Goal**: Build the complete visual UI matching Windows Notepad aesthetics:
  - Clean Tab Bar: Tab labels, modified indicators (`•`), close buttons (`✕`), and add tab button (`+`).
  - Status Bar: Line / Col, character count, encoding ("UTF-8"), line endings ("Windows (CRLF)" / "Unix (LF)"), Zoom percentage.
  - In-window Find & Replace bar with Next/Previous, Match case, and Replace All.
- **Steps**:
  - [x] Implement `TabBarView.swift` with smooth tab switching and hover close buttons.
  - [x] Implement `StatusBarView.swift` with live metrics.
  - [x] Implement `FindReplaceBarView.swift` with search term highlighting and text replacement.
  - [x] Assemble `MainWindowView.swift` coordinating tab bar, active editor, find bar, and status bar.
  - [x] Run `swift build` and test UI integration.
  - [x] Git commit.

### Task 4: File Operations, App Menu Commands & Global Shortcuts
- **Files**: `Sources/iceNotePad/Helpers/FileOperations.swift`, `Sources/iceNotePad/App/MenuCommands.swift`, `Sources/iceNotePad/App/iceNotePadApp.swift`
- **Goal**: Wire up full keyboard shortcuts and menu bar commands:
  - `Cmd+T`: New tab
  - `Cmd+W`: Close tab (or window if last tab)
  - `Cmd+1..9`: Jump to tab
  - `Cmd+O`: Open file
  - `Cmd+S`: Save file
  - `Cmd+Shift+S`: Save As
  - `Cmd+F`: Toggle Find/Replace
  - `Cmd++`, `Cmd+-`, `Cmd+0`: Zoom controls
- **Steps**:
  - [x] Implement `FileOperations.swift` with native `NSOpenPanel` and `NSSavePanel`.
  - [x] Implement `MenuCommands.swift` with standard keyboard shortcuts.
  - [x] Connect `iceNotePadApp.swift` to handle window lifecycle and persist session on quit.
  - [x] Run `swift build` and execute tests.
  - [x] Git commit.

### Task 5: Packaging into Standalone `iceNotePad.app` & Verification
- **Files**: `scripts/build_app.sh`, `scripts/generate_icon.swift`, `Info.plist`
- **Goal**: Bundle the compiled binary into a standalone macOS `.app` bundle with an icon, test launching it, verify tab persistence and format stripping.
- **Steps**:
  - [x] Create icon generator script to render a sleek Notepad-style icon and convert to `.icns`.
  - [x] Create `scripts/build_app.sh` that compiles in release mode (`-c release`), sets up `iceNotePad.app/Contents/MacOS`, `Info.plist`, and `Resources`.
  - [x] Run the build script to produce `build/iceNotePad.app`.
  - [x] Verify that opening `iceNotePad.app`, typing in multiple tabs, closing the app, and reopening it restores all tabs seamlessly.
  - [x] Verify rich text pasting strips all formatting into pure text.
  - [x] Provide user with clear instructions and install shortcut.
  - [x] Git commit.

