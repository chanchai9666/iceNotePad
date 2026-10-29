import SwiftUI

public struct TabBarView: View {
    @ObservedObject public var tabManager: TabManager

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
    }
}

public struct TabItemView: View {
    public let tab: NoteTab
    public let isActive: Bool
    public let onSelect: () -> Void
    public let onClose: () -> Void

    @State private var isHovering = false

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
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

