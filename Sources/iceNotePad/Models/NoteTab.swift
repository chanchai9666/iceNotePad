import Foundation

public struct NoteTab: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var fileURL: URL?
    public var isModified: Bool
    public var cursorLine: Int
    public var cursorColumn: Int

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        fileURL: URL? = nil,
        isModified: Bool = false,
        cursorLine: Int = 1,
        cursorColumn: Int = 1
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.fileURL = fileURL
        self.isModified = isModified
        self.cursorLine = cursorLine
        self.cursorColumn = cursorColumn
    }

    public static func == (lhs: NoteTab, rhs: NoteTab) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.content == rhs.content &&
               lhs.fileURL == rhs.fileURL &&
               lhs.isModified == rhs.isModified &&
               lhs.cursorLine == rhs.cursorLine &&
               lhs.cursorColumn == rhs.cursorColumn
    }
}

public struct SessionState: Codable {
    public var tabs: [NoteTab]
    public var activeTabId: UUID?
    public var untitledCounter: Int

    public init(tabs: [NoteTab], activeTabId: UUID?, untitledCounter: Int) {
        self.tabs = tabs
        self.activeTabId = activeTabId
        self.untitledCounter = untitledCounter
    }
}

