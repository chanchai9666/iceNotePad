import SwiftUI

@MainActor
public struct MainWindowView: View {
    @ObservedObject public var tabManager: TabManager
    @ObservedObject public var settings: AppSettings

    @State private var isFindPresented: Bool = false
    @State private var searchTargetRange: NSRange? = nil
    @State private var findFocusTrigger: UUID = UUID()

    public init(tabManager: TabManager, settings: AppSettings? = nil) {
        self.tabManager = tabManager
        self.settings = settings ?? .shared
    }

    private var activeTabBinding: Binding<NoteTab>? {
        guard let activeId = tabManager.activeTabId,
              tabManager.tabs.contains(where: { $0.id == activeId }) else {
            return nil
        }
        return Binding(
            get: {
                tabManager.tabs.first(where: { $0.id == activeId }) ?? NoteTab(id: activeId, title: "", content: "")
            },
            set: { updatedTab in
                if let index = tabManager.tabs.firstIndex(where: { $0.id == activeId }) {
                    if tabManager.tabs[index].content != updatedTab.content {
                        var modified = updatedTab
                        modified.isModified = true
                        tabManager.tabs[index] = modified
                    } else {
                        tabManager.tabs[index] = updatedTab
                    }
                }
            }
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            TabBarView(tabManager: tabManager)

            // Find and Replace Bar (when Cmd+F is pressed)
            if isFindPresented, let tabBinding = activeTabBinding {
                FindReplaceBarView(
                    isPresented: $isFindPresented,
                    text: tabBinding.content,
                    targetRange: $searchTargetRange,
                    focusTrigger: $findFocusTrigger
                )
                .id(tabBinding.wrappedValue.id)
            }

            // Text Editor Area
            if let tabBinding = activeTabBinding, let activeId = tabManager.activeTabId {
                PlainTextEditorView(
                    text: tabBinding.content,
                    searchTargetRange: $searchTargetRange,
                    fontSize: settings.fontSize,
                    isMonospace: settings.isMonospace,
                    wordWrap: settings.wordWrap,
                    onCursorChange: { line, col in
                        tabManager.updateCursor(for: activeId, line: line, column: col)
                    }
                )
                .id(activeId)
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: tabBinding.wrappedValue.content) { _ in
                    if let index = tabManager.tabs.firstIndex(where: { $0.id == activeId }) {
                        tabManager.tabs[index].isModified = true
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("No document open")
                        .foregroundColor(.secondary)
                    Button("New Tab") {
                        tabManager.newTab()
                    }
                    .padding(.top, 4)
                    Spacer()
                }
            }

            // Bottom Status Bar
            if let tab = tabManager.activeTab {
                StatusBarView(
                    line: tab.cursorLine,
                    column: tab.cursorColumn,
                    text: tab.content,
                    encoding: tab.encodingName,
                    settings: settings
                )
            }
        }
        .frame(minWidth: 500, minHeight: 350)
        .onChange(of: tabManager.activeTabId) { _ in
            searchTargetRange = nil
        }
        // Keyboard Shortcuts
        .background(
            ZStack {
                Button("") {
                    withAnimation {
                        isFindPresented = true
                        findFocusTrigger = UUID()
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)

                Button("") {
                    if isFindPresented {
                        withAnimation { isFindPresented = false }
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
                .opacity(0)
            }
        )
    }
}
