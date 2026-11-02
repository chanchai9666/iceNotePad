import SwiftUI

public struct TabBarWidthPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 800
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct TabBarView: View {
    @ObservedObject public var tabManager: TabManager
    public let onDoubleClickEmptyArea: (() -> Void)?

    @State private var availableWidth: CGFloat = 800
    @State private var tabToRename: NoteTab?
    @State private var renameInput: String = ""
    @State private var isShowingRenameAlert: Bool = false
    @State private var renameErrorMessage: String?
    @State private var isShowingErrorAlert: Bool = false

    public struct TabMetrics {
        public let isTwoRows: Bool
        public let row1Tabs: [NoteTab]
        public let row2Tabs: [NoteTab]
        public let row1TabWidth: CGFloat
        public let row2TabWidth: CGFloat
        public let row1NeedsScroll: Bool
        public let row2NeedsScroll: Bool
    }

    public init(tabManager: TabManager, onDoubleClickEmptyArea: (() -> Void)? = nil) {
        self.tabManager = tabManager
        self.onDoubleClickEmptyArea = onDoubleClickEmptyArea
    }

    public func handleEmptyAreaDoubleClick() {
        if let onDoubleClickEmptyArea = onDoubleClickEmptyArea {
            onDoubleClickEmptyArea()
        } else {
            tabManager.newTab()
        }
    }

    public func calculateTabMetrics(availableWidth: CGFloat, tabs: [NoteTab]) -> TabMetrics {
        let tabCount = tabs.count
        guard tabCount > 0 else {
            return TabMetrics(
                isTwoRows: false,
                row1Tabs: [],
                row2Tabs: [],
                row1TabWidth: 180,
                row2TabWidth: 180,
                row1NeedsScroll: false,
                row2NeedsScroll: false
            )
        }

        let reservedPlusWidth: CGFloat = 40
        let spacing: CGFloat = 2
        let minTabWidth: CGFloat = 90
        let maxTabWidth: CGFloat = 180

        let singleRowSpacing = CGFloat(max(0, tabCount - 1)) * spacing
        let singleRowNeeded = CGFloat(tabCount) * minTabWidth + singleRowSpacing + reservedPlusWidth
        let isTwoRows = tabCount >= 6 && singleRowNeeded > availableWidth

        if !isTwoRows {
            let availableForTabs = max(0, availableWidth - reservedPlusWidth - singleRowSpacing)
            let dynamicWidth = availableForTabs / CGFloat(tabCount)
            let tabWidth = max(minTabWidth, min(maxTabWidth, dynamicWidth))
            let totalNeeded = CGFloat(tabCount) * tabWidth + singleRowSpacing + reservedPlusWidth
            let needsScroll = totalNeeded > availableWidth

            return TabMetrics(
                isTwoRows: false,
                row1Tabs: tabs,
                row2Tabs: [],
                row1TabWidth: tabWidth,
                row2TabWidth: tabWidth,
                row1NeedsScroll: needsScroll,
                row2NeedsScroll: false
            )
        } else {
            let splitIndex = (tabCount + 1) / 2
            let r1 = Array(tabs[0..<splitIndex])
            let r2 = Array(tabs[splitIndex..<tabCount])

            // Row 1 (no plus button, reserved margin 8)
            let spacing1 = CGFloat(max(0, r1.count - 1)) * spacing
            let avail1 = max(0, availableWidth - 8 - spacing1)
            let dyn1 = avail1 / CGFloat(max(1, r1.count))
            let w1 = max(minTabWidth, min(maxTabWidth, dyn1))
            let needed1 = CGFloat(r1.count) * w1 + spacing1 + 8
            let scroll1 = needed1 > availableWidth

            // Row 2 (with plus button 40)
            let spacing2 = CGFloat(max(0, r2.count - 1)) * spacing
            let avail2 = max(0, availableWidth - reservedPlusWidth - spacing2)
            let dyn2 = avail2 / CGFloat(max(1, r2.count))
            let w2 = max(minTabWidth, min(maxTabWidth, dyn2))
            let needed2 = CGFloat(r2.count) * w2 + spacing2 + reservedPlusWidth
            let scroll2 = needed2 > availableWidth

            return TabMetrics(
                isTwoRows: true,
                row1Tabs: r1,
                row2Tabs: r2,
                row1TabWidth: w1,
                row2TabWidth: w2,
                row1NeedsScroll: scroll1,
                row2NeedsScroll: scroll2
            )
        }
    }

    private var newTabButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                _ = tabManager.newTab()
            }
        }) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .help("New Tab (Cmd+T)")
    }

    @ViewBuilder
    private func renderTabRow(
        tabs: [NoteTab],
        tabWidth: CGFloat,
        needsScroll: Bool,
        showPlusButton: Bool
    ) -> some View {
        HStack(spacing: 0) {
            if needsScroll {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(tabs) { tab in
                                TabItemView(
                                    tab: tab,
                                    width: tabWidth,
                                    isActive: tab.id == tabManager.activeTabId,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.12)) {
                                            tabManager.selectTab(id: tab.id)
                                        }
                                    },
                                    onClose: {
                                        withAnimation(.easeInOut(duration: 0.12)) {
                                            tabManager.closeTab(id: tab.id)
                                        }
                                    },
                                    onDuplicate: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            _ = tabManager.duplicateTab(id: tab.id)
                                        }
                                    },
                                    onRename: {
                                        tabToRename = tab
                                        renameInput = tab.title
                                        isShowingRenameAlert = true
                                    }
                                )
                                .id(tab.id)
                            }

                            if showPlusButton {
                                newTabButton
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    .onChange(of: tabManager.activeTabId) { activeId in
                        if let activeId = activeId, tabs.contains(where: { $0.id == activeId }) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(activeId, anchor: .center)
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 2) {
                    ForEach(tabs) { tab in
                        TabItemView(
                            tab: tab,
                            width: tabWidth,
                            isActive: tab.id == tabManager.activeTabId,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    tabManager.selectTab(id: tab.id)
                                }
                            },
                            onClose: {
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    tabManager.closeTab(id: tab.id)
                                }
                            },
                            onDuplicate: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    _ = tabManager.duplicateTab(id: tab.id)
                                }
                            },
                            onRename: {
                                tabToRename = tab
                                renameInput = tab.title
                                isShowingRenameAlert = true
                            }
                        )
                        .id(tab.id)
                    }

                    if showPlusButton {
                        newTabButton
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

                // Empty area for double-click
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        handleEmptyAreaDoubleClick()
                    }
            }
        }
        .frame(height: 34)
    }

    public var body: some View {
        let metrics = calculateTabMetrics(availableWidth: availableWidth, tabs: tabManager.tabs)

        VStack(spacing: 0) {
            if metrics.isTwoRows {
                renderTabRow(
                    tabs: metrics.row1Tabs,
                    tabWidth: metrics.row1TabWidth,
                    needsScroll: metrics.row1NeedsScroll,
                    showPlusButton: false
                )

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor).opacity(0.35))

                renderTabRow(
                    tabs: metrics.row2Tabs,
                    tabWidth: metrics.row2TabWidth,
                    needsScroll: metrics.row2NeedsScroll,
                    showPlusButton: true
                )
            } else {
                renderTabRow(
                    tabs: metrics.row1Tabs,
                    tabWidth: metrics.row1TabWidth,
                    needsScroll: metrics.row1NeedsScroll,
                    showPlusButton: true
                )
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: TabBarWidthPreferenceKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(TabBarWidthPreferenceKey.self) { newWidth in
            if newWidth > 0 && newWidth != availableWidth {
                availableWidth = newWidth
            }
        }
        .animation(.easeInOut(duration: 0.2), value: metrics.isTwoRows)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .alert("Rename File", isPresented: $isShowingRenameAlert) {
            TextField("New file name", text: $renameInput)
            Button("Rename") {
                if let tab = tabToRename {
                    do {
                        try tabManager.renameTab(id: tab.id, newName: renameInput)
                    } catch {
                        renameErrorMessage = error.localizedDescription
                        isShowingErrorAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let tab = tabToRename, tab.fileURL != nil {
                Text("Renaming will change the physical file on disk.")
            } else {
                Text("Specify a new name for this tab.")
            }
        }
        .alert("Failed to Rename File", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(renameErrorMessage ?? "An error occurred while renaming the file.")
        }
    }
}

public struct TabItemView: View {
    public let tab: NoteTab
    public var width: CGFloat? = nil
    public let isActive: Bool
    public let onSelect: () -> Void
    public let onClose: () -> Void
    public let onDuplicate: () -> Void
    public let onRename: () -> Void

    @State private var isHovering = false

    public init(
        tab: NoteTab,
        width: CGFloat? = nil,
        isActive: Bool,
        onSelect: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onRename: @escaping () -> Void
    ) {
        self.tab = tab
        self.width = width
        self.isActive = isActive
        self.onSelect = onSelect
        self.onClose = onClose
        self.onDuplicate = onDuplicate
        self.onRename = onRename
    }

    public var tooltipText: String {
        if let fileURL = tab.fileURL {
            return "\(tab.title)\n\(fileURL.path)"
        }
        return tab.title
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Unsaved indicator
            if tab.isModified {
                Circle()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 6, height: 6)
            }

            // Tab Title
            Text(tab.title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(isActive ? .primary : .secondary)
                .animation(.easeInOut(duration: 0.15), value: isActive)

            Spacer(minLength: 0)

            // Close button 'x'
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isHovering || isActive ? .primary : .secondary.opacity(0.7))
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering || isActive ? 1.0 : 0.6)
            .help("Close Tab (Cmd+W)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(width: width, height: 26)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(NSColor.controlBackgroundColor) : (isHovering ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color.clear))
                .animation(.easeInOut(duration: 0.15), value: isActive)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color(NSColor.separatorColor).opacity(0.5) : Color.clear, lineWidth: 1)
                .animation(.easeInOut(duration: 0.15), value: isActive)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .help(tooltipText)
        .contextMenu {
            Button(action: onRename) {
                Label("Rename File...", systemImage: "pencil")
            }
            Button(action: onDuplicate) {
                Label("Duplicate Tab", systemImage: "doc.on.doc")
            }
            Divider()
            Button(action: onClose) {
                Label("Close Tab", systemImage: "xmark")
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
