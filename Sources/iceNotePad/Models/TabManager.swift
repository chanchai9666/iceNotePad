import Foundation
import Combine

@MainActor
public class TabManager: ObservableObject {
    @Published public var tabs: [NoteTab] = []
    @Published public var activeTabId: UUID?
    @Published public var untitledCounter: Int = 1

    public let storageURL: URL
    private var saveCancellable: AnyCancellable?

    nonisolated public static var defaultStorageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("iceNotePad", isDirectory: true)
        return dir.appendingPathComponent("session.json")
    }

    public var activeTab: NoteTab? {
        guard let activeTabId = activeTabId else { return tabs.first }
        return tabs.first(where: { $0.id == activeTabId })
    }

    public var activeTabIndex: Int? {
        guard let activeTabId = activeTabId else { return nil }
        return tabs.firstIndex(where: { $0.id == activeTabId })
    }

    public init(storageURL: URL = TabManager.defaultStorageURL, autoLoad: Bool = true) {
        self.storageURL = storageURL

        if autoLoad {
            loadSession()
        }
        ensureAtLeastOneTab()

        // Debounce auto-save whenever tabs or activeTabId changes
        saveCancellable = $tabs
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSession()
            }
    }

    public func ensureAtLeastOneTab() {
        if tabs.isEmpty {
            _ = newTab()
        } else if activeTabId == nil || !tabs.contains(where: { $0.id == activeTabId }) {
            activeTabId = tabs.first?.id
        }
    }

    @discardableResult
    public func newTab(title: String? = nil, content: String = "", fileURL: URL? = nil) -> NoteTab {
        let tabTitle: String
        if let title = title {
            tabTitle = title
        } else {
            tabTitle = "Untitled \(untitledCounter)"
            untitledCounter += 1
        }

        let newTab = NoteTab(
            id: UUID(),
            title: tabTitle,
            content: content,
            fileURL: fileURL,
            isModified: false
        )

        tabs.append(newTab)
        activeTabId = newTab.id
        saveSession()
        return newTab
    }

    public func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        tabs.remove(at: index)

        if activeTabId == id {
            if tabs.isEmpty {
                _ = newTab()
            } else {
                let newIndex = min(index, tabs.count - 1)
                activeTabId = tabs[newIndex].id
            }
        }
        saveSession()
    }

    public func closeCurrentTab() {
        if let activeId = activeTabId {
            closeTab(id: activeId)
        }
    }

    public func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
            saveSession()
        }
    }

    public func selectTab(index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        activeTabId = tabs[index].id
        saveSession()
    }

    public func selectNextTab() {
        guard tabs.count > 1, let currentIdx = activeTabIndex else { return }
        let nextIdx = (currentIdx + 1) % tabs.count
        activeTabId = tabs[nextIdx].id
        saveSession()
    }

    public func selectPreviousTab() {
        guard tabs.count > 1, let currentIdx = activeTabIndex else { return }
        let prevIdx = (currentIdx - 1 + tabs.count) % tabs.count
        activeTabId = tabs[prevIdx].id
        saveSession()
    }

    public func updateContent(for id: UUID, newContent: String) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        if tabs[index].content != newContent {
            tabs[index].content = newContent
            tabs[index].isModified = true
        }
    }

    public func updateCursor(for id: UUID, line: Int, column: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].cursorLine = line
        tabs[index].cursorColumn = column
    }

    public func markSaved(id: UUID, fileURL: URL) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].fileURL = fileURL
        tabs[index].title = fileURL.lastPathComponent
        tabs[index].isModified = false
        saveSession()
    }

    @discardableResult
    public func duplicateTab(id: UUID) -> NoteTab? {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return nil }
        let original = tabs[index]

        let newTitle = "\(original.title) (Copy)"
        let duplicated = NoteTab(
            id: UUID(),
            title: newTitle,
            content: original.content,
            fileURL: nil,
            isModified: true,
            cursorLine: original.cursorLine,
            cursorColumn: original.cursorColumn
        )

        tabs.insert(duplicated, at: index + 1)
        activeTabId = duplicated.id
        saveSession()
        return duplicated
    }

    public func renameTab(id: UUID, newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        if let currentURL = tabs[index].fileURL {
            let directory = currentURL.deletingLastPathComponent()
            let newURL = directory.appendingPathComponent(trimmed)
            if newURL != currentURL {
                try FileManager.default.moveItem(at: currentURL, to: newURL)
                tabs[index].fileURL = newURL
            }
        }

        tabs[index].title = trimmed
        saveSession()
    }

    public func saveSession() {
        Task {
            saveSessionSync()
        }
    }

    public func saveSessionSync() {
        let state = SessionState(tabs: tabs, activeTabId: activeTabId, untitledCounter: untitledCounter)
        do {
            let dir = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(state)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    public func loadSession() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let state = try JSONDecoder().decode(SessionState.self, from: data)
            if !state.tabs.isEmpty {
                self.tabs = state.tabs
                self.activeTabId = state.activeTabId ?? state.tabs.first?.id
                self.untitledCounter = max(state.untitledCounter, state.tabs.count + 1)
            }
        } catch {
            print("Failed to load session: \(error)")
        }
    }
}