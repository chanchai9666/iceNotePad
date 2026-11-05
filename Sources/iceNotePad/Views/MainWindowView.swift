import SwiftUI

@MainActor
public struct MainWindowView: View {
    @ObservedObject public var tabManager: TabManager
    @ObservedObject public var settings: AppSettings

    @State private var isFindPresented: Bool = false
    @State private var searchTargetRange: NSRange? = nil
    @State private var findFocusTrigger: UUID = UUID()
    @State private var findNavigation: FindNavigationRequest? = nil

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
                guard let index = tabManager.tabs.firstIndex(where: { $0.id == activeId }) else {
                    return
                }
                // Keep the dirty-flag rule in TabManager so the binding does not
                // re-implement it differently from updateContent(for:newContent:).
                if tabManager.tabs[index].content != updatedTab.content {
                    tabManager.updateContent(for: activeId, newContent: updatedTab.content)
                }
                var updated = updatedTab
                updated.isModified = tabManager.tabs[index].isModified
                tabManager.tabs[index] = updated
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
                    focusTrigger: $findFocusTrigger,
                    navigationRequest: $findNavigation
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
                    initialCursorPosition: tabBinding.wrappedValue.cursorPosition,
                    onCursorChange: { line, col in
                        tabManager.updateCursor(for: activeId, line: line, column: col)
                    }
                )
                .id(activeId)
                .transition(.opacity)
                .background(Color(NSColor.textBackgroundColor))
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
        .animation(.easeInOut(duration: 0.12), value: tabManager.activeTabId)
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
                    navigateFind(.next)
                }
                .keyboardShortcut("g", modifiers: .command)
                .opacity(0)

                Button("") {
                    navigateFind(.previous)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .opacity(0)

                Button("") {
                    if isFindPresented {
                        withAnimation { isFindPresented = false }
                        searchTargetRange = nil
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
                .opacity(0)
            }
        )
    }

    private func navigateFind(_ direction: FindNavigationDirection) {
        guard isFindPresented else {
            withAnimation { isFindPresented = true }
            findFocusTrigger = UUID()
            return
        }
        findNavigation = FindNavigationRequest(direction: direction, token: UUID())
    }
}
