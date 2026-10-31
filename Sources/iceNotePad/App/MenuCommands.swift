import SwiftUI

public struct IceNotePadCommands: Commands {
    @ObservedObject public var tabManager: TabManager
    @ObservedObject public var settings: AppSettings

    public init(tabManager: TabManager, settings: AppSettings? = nil) {
        self.tabManager = tabManager
        self.settings = settings ?? .shared
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab") {
                tabManager.newTab()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("New Window / Tab") {
                tabManager.newTab()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open...") {
                FileOperations.openFile { url, content, encoding in
                    tabManager.openDocument(url: url, content: content, encodingName: encoding)
                }
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Save") {
                if let active = tabManager.activeTab {
                    FileOperations.saveFile(tab: active, forceSaveAs: false) { savedURL in
                        tabManager.markSaved(id: active.id, fileURL: savedURL)
                        if let idx = tabManager.tabs.firstIndex(where: { $0.id == active.id }) {
                            tabManager.tabs[idx].encodingName = "UTF-8"
                        }
                    }
                }
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Save As...") {
                if let active = tabManager.activeTab {
                    FileOperations.saveFile(tab: active, forceSaveAs: true) { savedURL in
                        tabManager.markSaved(id: active.id, fileURL: savedURL)
                        if let idx = tabManager.tabs.firstIndex(where: { $0.id == active.id }) {
                            tabManager.tabs[idx].encodingName = "UTF-8"
                        }
                    }
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()

            Button("Close Tab") {
                if tabManager.tabs.count <= 1 {
                    NSApplication.shared.keyWindow?.performClose(nil)
                } else {
                    tabManager.closeCurrentTab()
                }
            }
            .keyboardShortcut("w", modifiers: .command)
        }

        CommandMenu("View") {
            Button("Zoom In") {
                settings.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                settings.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Restore Default Zoom") {
                settings.zoomReset()
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()

            Toggle("Word Wrap", isOn: $settings.wordWrap)
            Toggle("Monospaced Font", isOn: $settings.isMonospace)
        }

        CommandMenu("Tabs") {
            Button("Next Tab") {
                tabManager.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button("Previous Tab") {
                tabManager.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])

            Divider()

            ForEach(0..<min(tabManager.tabs.count, 9), id: \.self) { index in
                Button(tabManager.tabs[index].title) {
                    tabManager.selectTab(index: index)
                }
                .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(49 + index)!)), modifiers: .command)
            }
        }
    }
}
