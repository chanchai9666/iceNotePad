import SwiftUI

public struct TabBarView: View {
    @ObservedObject public var tabManager: TabManager

    @State private var tabToRename: NoteTab?
    @State private var renameInput: String = ""
    @State private var isShowingRenameAlert: Bool = false
    @State private var renameErrorMessage: String?
    @State private var isShowingErrorAlert: Bool = false

    public init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTabId,
                            onSelect: {
                                tabManager.selectTab(id: tab.id)
                            },
                            onClose: {
                                tabManager.closeTab(id: tab.id)
                            },
                            onDuplicate: {
                                tabManager.duplicateTab(id: tab.id)
                            },
                            onRename: {
                                tabToRename = tab
                                renameInput = tab.title
                                isShowingRenameAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }

            // '+' New Tab button
            Button(action: {
                tabManager.newTab()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            .help("New Tab (Cmd+T)")

            Spacer(minLength: 0)
        }
        .frame(height: 34)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .alert("เปลี่ยนชื่อไฟล์", isPresented: $isShowingRenameAlert) {
            TextField("ชื่อไฟล์ใหม่", text: $renameInput)
            Button("เปลี่ยนชื่อ") {
                if let tab = tabToRename {
                    do {
                        try tabManager.renameTab(id: tab.id, newName: renameInput)
                    } catch {
                        renameErrorMessage = error.localizedDescription
                        isShowingErrorAlert = true
                    }
                }
            }
            Button("ยกเลิก", role: .cancel) { }
        } message: {
            if let tab = tabToRename, tab.fileURL != nil {
                Text("การเปลี่ยนชื่อจะแก้ไขชื่อไฟล์จริงบนเครื่องด้วย")
            } else {
                Text("ระบุชื่อใหม่สำหรับแท็บนี้")
            }
        }
        .alert("ไม่สามารถเปลี่ยนชื่อไฟล์ได้", isPresented: $isShowingErrorAlert) {
            Button("ตกลง", role: .cancel) { }
        } message: {
            Text(renameErrorMessage ?? "เกิดข้อผิดพลาดในการเปลี่ยนชื่อไฟล์")
        }
    }
}

public struct TabItemView: View {
    public let tab: NoteTab
    public let isActive: Bool
    public let onSelect: () -> Void
    public let onClose: () -> Void
    public let onDuplicate: () -> Void
    public let onRename: () -> Void

    @State private var isHovering = false

    public init(
        tab: NoteTab,
        isActive: Bool,
        onSelect: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onRename: @escaping () -> Void
    ) {
        self.tab = tab
        self.isActive = isActive
        self.onSelect = onSelect
        self.onClose = onClose
        self.onDuplicate = onDuplicate
        self.onRename = onRename
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
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(minWidth: 90, maxWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(NSColor.controlBackgroundColor) : (isHovering ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color(NSColor.separatorColor).opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button(action: onRename) {
                Label("เปลี่ยนชื่อไฟล์...", systemImage: "pencil")
            }
            Button(action: onDuplicate) {
                Label("ทำซ้ำแท็บ", systemImage: "doc.on.doc")
            }
            Divider()
            Button(action: onClose) {
                Label("ปิดแท็บ", systemImage: "xmark")
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

