# iceNotePad System Refinement & Spec Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the iceNotePad codebase to address all code-review findings (safe error handling, Find & Replace Next/Previous with native text view navigation, accurate encoding display, test coverage, and repository cleanup) while preserving newly added features (Duplicate Tab, Rename File, Tab Bar Double-Click) and ensuring ultra-lightweight, blazing-fast performance.

**Architecture:** Maintain strict pure AppKit/SwiftUI separation. AppKit `NSTextView` handles text rendering, pasteboard sanitization, and native find indicator navigation without overhead; SwiftUI handles declarative layouts and reactive state binding; `TabManager` and `NoteTab` manage persistence and lifecycle safely without force-unwrapping.

**Tech Stack:** Swift 5.9+ / Swift 6, AppKit (`NSTextView`, `NSViewRepresentable`), SwiftUI, XCTest. Target OS: macOS 13.0+.

**Spec:** `docs/superpowers/plans/2026-10-29-iceNotePad.md` and `GEMINI.md`.

## Global Constraints

- Native macOS 13.0+ (Ventura or newer), optimized for Apple Silicon (M1/M2/M3/M4).
- Zero third-party dependencies — standard library, Foundation, AppKit, and SwiftUI only.
- Pure plain-text enforcement (no rich text attributes, HTML, or RTF retained on paste).
- Lightweight & Fast: No heavy polling, minimal memory footprint, instant startup.
- Preserve User Requirements: Retain Duplicate Tab, Rename File, and Tab Bar Double-Click features exactly as introduced.

## Review Focus

1. **Find & Replace with zero or multiple matches**: Navigation when 0 matches exist must not crash or select out-of-bounds ranges; wrapping from last match to first match must cycle smoothly.
2. **Tab closure on the final remaining tab via Cmd+W**: Must close the window (`performClose(nil)`) when triggered from the menu/shortcut, matching macOS native editor conventions, while preserving clean state.
3. **Session path resolution failure**: If `.applicationSupportDirectory` resolution encounters permissions or sandbox restrictions, fallback gracefully to temporary directory without crashing.
4. **Non-UTF-8 file loading**: Files encoded in ISO-8859-1 (Latin-1) must load correctly and report "Western (ISO Latin 1)" on the status bar instead of hardcoding "UTF-8".
5. **Rename file collision / invalid characters**: Attempting to rename a file to an existing name or with invalid characters must show a non-fatal error dialog and preserve existing tab state.

---

### Task 1: Clean Repository Tracking & Binary Artifacts

**Files:**
- Modify: `.gitignore`
- Remove from Git: `build/iceNotePad.app`, `build/iceNotePad.dmg`, `build/iceNotePad.zip`

**Interfaces:**
- Consumes: Existing git tracking state.
- Produces: Clean git status without tracking 2.7MB of compiled release binaries.

- [ ] **Step 1: Update `.gitignore` to ignore the `build/` output directory**

Add `build/` to `.gitignore`.

- [ ] **Step 2: Untrack compiled binaries from git index**

Run: `git rm -r --cached build/`

- [ ] **Step 3: Verify git status**

Run: `git status -s`
Expected: `D build/...` (staged for deletion in index) and `M .gitignore`.

- [ ] **Step 4: Commit repository cleanup**

```bash
git commit -m "chore: remove compiled release binaries from git tracking and ignore build/"
```

---

### Task 2: Robust Data Models & Safe Session Persistence

**Files:**
- Modify: `Sources/iceNotePad/Models/NoteTab.swift`
- Modify: `Sources/iceNotePad/Models/TabManager.swift`
- Modify: `Tests/iceNotePadTests/TabManagerTests.swift`

**Interfaces:**
- Produces:
  - `struct TextPosition: Codable, Equatable`: Bundles `line: Int` and `column: Int`.
  - `NoteTab.cursorPosition: TextPosition` (replaces loose `cursorLine` and `cursorColumn`).
  - `NoteTab.encodingName: String` (defaults to `"UTF-8"`).
  - `TabManager.defaultStorageURL: URL`: Safe resolution without force-unwrap (`!`).
  - `TabManager.openDocument(url: URL, content: String, encodingName: String)`: Centralizes document opening logic from `MenuCommands`.

- [ ] **Step 1: Write failing tests in `TabManagerTests.swift`**

Add tests in `TabManagerTests.swift`:
- `testDefaultStorageURLSafety`: Verifies `TabManager.defaultStorageURL` returns a valid URL without crashing.
- `testOpenDocumentReplacesEmptyTab`: Verifies `openDocument` replaces an untitled empty tab.
- `testOpenDocumentCreatesNewTabWhenActiveHasContent`: Verifies `openDocument` creates a new tab when active tab has content.
- `testCursorPositionEncapsulation`: Verifies `tab.cursorPosition` updates and persists correctly.

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter TabManagerTests`
Expected: FAIL due to missing `TextPosition`, `openDocument`, or `cursorPosition`.

- [ ] **Step 3: Implement `TextPosition` and safe storage URL**

In `NoteTab.swift`:
- Define `public struct TextPosition: Codable, Equatable { public var line: Int; public var column: Int }`
- Add `public var cursorPosition: TextPosition = TextPosition(line: 1, column: 1)`
- Add `public var encodingName: String = "UTF-8"`
- Provide backwards-compatible coding keys / properties if needed.

In `TabManager.swift`:
- Refactor `defaultStorageURL`:
  ```swift
  nonisolated public static var defaultStorageURL: URL {
      let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
          ?? FileManager.default.temporaryDirectory
      let dir = appSupport.appendingPathComponent("iceNotePad", isDirectory: true)
      return dir.appendingPathComponent("session.json")
  }
  ```
- Implement `openDocument(url: URL, content: String, encodingName: String = "UTF-8")`:
  ```swift
  public func openDocument(url: URL, content: String, encodingName: String = "UTF-8") {
      if let active = activeTab, active.content.isEmpty, active.fileURL == nil {
          updateContent(for: active.id, newContent: content)
          markSaved(id: active.id, fileURL: url)
          if let idx = tabs.firstIndex(where: { $0.id == active.id }) {
              tabs[idx].encodingName = encodingName
          }
      } else {
          let tab = newTab(title: url.lastPathComponent, content: content, fileURL: url)
          if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
              tabs[idx].encodingName = encodingName
          }
          markSaved(id: tab.id, fileURL: url)
      }
  }
  ```
- Update `updateCursor(for: UUID, position: TextPosition)` in `TabManager`.

- [ ] **Step 4: Run tests to verify pass**

Run: `swift test --filter TabManagerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/iceNotePad/Models/ Tests/iceNotePadTests/TabManagerTests.swift
git commit -m "refactor: encapsulate TextPosition, safe session URL, and centralize openDocument in TabManager"
```

---

### Task 3: FileOperations Refactoring & Test Suite

**Files:**
- Modify: `Sources/iceNotePad/Helpers/FileOperations.swift`
- Create: `Tests/iceNotePadTests/FileOperationsTests.swift`

**Interfaces:**
- Produces:
  - `FileOperations.openFile(completion: (URL, String, String) -> Void)`: Passes `(url, content, encodingName)`.
  - `FileOperations.showErrorAlert(title: String, message: String)`: Deduplicated alert display.
  - Full automated unit tests in `FileOperationsTests.swift`.

- [ ] **Step 1: Write failing test in `FileOperationsTests.swift`**

Create `Tests/iceNotePadTests/FileOperationsTests.swift` testing:
- Saving string to temporary URL and reading back via UTF-8.
- Reading ISO Latin-1 text with fallback encoding.
- Verifying encoding name reported ("UTF-8" vs "Western (ISO Latin 1)").

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FileOperationsTests`
Expected: FAIL (file or signatures missing).

- [ ] **Step 3: Implement deduplicated error alert & encoding detection in `FileOperations.swift`**

- Extract helper `private static func showErrorAlert(title: String, message: String)` to eliminate duplicated `NSAlert` code in `saveFile` and `saveFileAs`.
- Update `readFileContent(from url: URL) -> (content: String, encoding: String)?` to return detected encoding string.
- Update `openFile(completion: @escaping (URL, String, String) -> Void)`.

- [ ] **Step 4: Run test to verify pass**

Run: `swift test --filter FileOperationsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/iceNotePad/Helpers/FileOperations.swift Tests/iceNotePadTests/FileOperationsTests.swift
git commit -m "feat: add FileOperationsTests, deduplicate alert presentation, and track file encoding"
```

---

### Task 4: Interactive Find & Replace with Next/Previous & Native Text View Highlight

**Files:**
- Modify: `Sources/iceNotePad/Views/PlainTextEditorView.swift`
- Modify: `Sources/iceNotePad/Views/FindReplaceBarView.swift`
- Modify: `Sources/iceNotePad/Views/MainWindowView.swift`

**Interfaces:**
- Produces:
  - `PlainTextEditorView`: Accepts `@Binding var searchTargetRange: NSRange?`. When set, triggers `nsView.scrollRangeToVisible(range)`, `nsView.showFindIndicator(for: range)`, and `nsView.setSelectedRange(range)`.
  - `FindReplaceBarView`: Adds "Previous" (`ChevronUp`) and "Next" (`ChevronDown`) buttons, cycles `currentMatchIndex`, highlights match in editor, and replaces selected occurrence cleanly.

- [ ] **Step 1: Update `PlainTextEditorView.swift` to support `searchTargetRange`**

In `PlainTextEditorView.swift`:
- Add `@Binding public var searchTargetRange: NSRange?`
- In `Coordinator`, track `lastTargetRange: NSRange?`
- In `updateNSView`:
  ```swift
  if let target = searchTargetRange, target != context.coordinator.lastTargetRange {
      context.coordinator.lastTargetRange = target
      if target.location + target.length <= nsView.string.count {
          nsView.scrollRangeToVisible(target)
          nsView.showFindIndicator(for: target)
          nsView.setSelectedRange(target)
          nsView.calculateCursorPosition()
      }
  }
  ```

- [ ] **Step 2: Update `FindReplaceBarView.swift` with Next/Previous navigation**

In `FindReplaceBarView.swift`:
- Add `@Binding public var targetRange: NSRange?`
- Add navigation methods:
  - `selectNextMatch()`: Increments `currentMatchIndex` (with modulo wrapping `currentMatchIndex = (currentMatchIndex + 1) % matchCount`) and sets `targetRange`.
  - `selectPreviousMatch()`: Decrements `currentMatchIndex` (wrapping to `matchCount - 1`) and sets `targetRange`.
- Add UI controls:
  - Up arrow button ("Previous", shortcut `Shift+Enter` / `Cmd+Shift+G`).
  - Down arrow button ("Next", shortcut `Enter` / `Cmd+G`).
  - Match count indicator: `"\(matchCount == 0 ? 0 : currentMatchIndex + 1) of \(matchCount)"`.
- When `searchText` changes, automatically highlight the first match.

- [ ] **Step 3: Connect in `MainWindowView.swift`**

- In `MainWindowView.swift`, add `@State private var searchTargetRange: NSRange? = nil`.
- Pass `$searchTargetRange` to both `FindReplaceBarView` and `PlainTextEditorView`.

- [ ] **Step 4: Verify compilation & run tests**

Run: `swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/iceNotePad/Views/PlainTextEditorView.swift Sources/iceNotePad/Views/FindReplaceBarView.swift Sources/iceNotePad/Views/MainWindowView.swift
git commit -m "feat: add Next/Previous navigation and native NSTextView find indicator highlight to Find & Replace"
```

---

### Task 5: UI Refinement, Dynamic Status Bar Encoding & Window Close Polish

**Files:**
- Modify: `Sources/iceNotePad/Views/StatusBarView.swift`
- Modify: `Sources/iceNotePad/Views/TabBarView.swift`
- Modify: `Sources/iceNotePad/App/MenuCommands.swift`
- Modify: `Sources/iceNotePad/Views/MainWindowView.swift`

**Interfaces:**
- Produces:
  - `StatusBarView`: Displays `encoding` dynamically (`tab.encodingName`) instead of hardcoded `"UTF-8"`.
  - `TabBarView`: Retains Duplicate Tab, Rename File, and Double-Click while standardizing English labels (`"Rename File..."`, `"Duplicate Tab"`, `"Close Tab"`) and cleaning duplicated `.onTapGesture(count: 2)`.
  - `MenuCommands`: Uses `tabManager.openDocument` and implements window closing (`NSApplication.shared.keyWindow?.performClose(nil)`) when `Cmd+W` is pressed on the last tab.

- [ ] **Step 1: Update `StatusBarView.swift` to display dynamic encoding**

- Add `public var encoding: String = "UTF-8"` parameter to `StatusBarView`.
- In `StatusBarView.body`, replace `Text("UTF-8")` with `Text(encoding)`.
- In `MainWindowView.swift`, pass `tabBinding.wrappedValue.encodingName` to `StatusBarView`.

- [ ] **Step 2: Polish `TabBarView.swift` while preserving all user features**

- Retain Rename Tab (with Alert), Duplicate Tab, and Double-Click on empty tab bar area.
- Standardize Context Menu and Alert strings to clean localized/English labels consistent with macOS Notepad.
- Consolidate gesture handlers so empty area double-click has a single clean trigger and unused parameter `onDoubleClickEmptyArea` is removed.

- [ ] **Step 3: Update `MenuCommands.swift`**

- Use `tabManager.openDocument(url:content:encodingName:)` in `Button("Open...")`.
- Update `Button("Close Tab")`:
  ```swift
  Button("Close Tab") {
      if tabManager.tabs.count <= 1 {
          NSApplication.shared.keyWindow?.performClose(nil)
      } else {
          tabManager.closeCurrentTab()
      }
  }
  .keyboardShortcut("w", modifiers: .command)
  ```

- [ ] **Step 4: Run full test suite and verify build**

Run: `swift test`
Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/iceNotePad/Views/StatusBarView.swift Sources/iceNotePad/Views/TabBarView.swift Sources/iceNotePad/App/MenuCommands.swift Sources/iceNotePad/Views/MainWindowView.swift
git commit -m "refactor: polish dynamic status bar encoding, standardize tab menu labels, and handle window close on last tab"
```

