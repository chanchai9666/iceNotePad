import SwiftUI

@MainActor
public struct MainWindowView: View {
    @ObservedObject public var tabManager: TabManager
    @ObservedObject public var settings: AppSettings

    @State private var isFindPresented: Bool = false

    public init(tabManager: TabManager, settings: AppSettings? = nil) {
        self.tabManager = tabManager
        self.settings = settings ?? .shared
    }

    private var activeTabBinding: Binding<NoteTab>? {
        guard let activeId = tabManager.activeTabId,
              let index = tabManager.tabs.firstIndex(where: { $0.id == activeId }) else {
            return nil
        }
        return $tabManager.tabs[index]
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            TabBarView(tabManager: tabManager)

            // Find and Replace Bar (when Cmd+F is pressed)
            if isFindPresented, let tabBinding = activeTabBinding {
                FindReplaceBarView(isPresented: $isFindPresented, text: tabBinding.content)
            }

            // Text Editor Area
            if let tabBinding = activeTabBinding {
                PlainTextEditorView(
                    text: tabBinding.content,
                    fontSize: settings.fontSize,
                    isMonospace: settings.isMonospace,
                    wordWrap: settings.wordWrap,
                    onCursorChange: { line, col in
                        tabManager.updateCursor(for: tabBinding.wrappedValue.id, line: line, column: col)
                    }
                )
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: tabBinding.wrappedValue.content) { _ in
                    tabBinding.wrappedValue.isModified = true
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
                    settings: settings
                )
            }
        }
        .frame(minWidth: 500, minHeight: 350)
        // Keyboard Shortcuts
        .background(
            ZStack {
                Button("") {
                    withAnimation {
                        isFindPresented.toggle()
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
