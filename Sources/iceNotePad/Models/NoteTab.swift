import Foundation

public struct TextPosition: Codable, Equatable {
    public var line: Int
    public var column: Int

    public init(line: Int = 1, column: Int = 1) {
        self.line = line
        self.column = column
    }
}

public struct NoteTab: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var fileURL: URL?
    public var isModified: Bool
    public var cursorPosition: TextPosition
    public var encodingName: String

    public var cursorLine: Int {
        get { cursorPosition.line }
        set { cursorPosition.line = newValue }
    }

    public var cursorColumn: Int {
        get { cursorPosition.column }
        set { cursorPosition.column = newValue }
    }

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        fileURL: URL? = nil,
        isModified: Bool = false,
        cursorPosition: TextPosition = TextPosition(line: 1, column: 1),
        encodingName: String = "UTF-8"
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.fileURL = fileURL
        self.isModified = isModified
        self.cursorPosition = cursorPosition
        self.encodingName = encodingName
    }

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        fileURL: URL? = nil,
        isModified: Bool = false,
        cursorLine: Int = 1,
        cursorColumn: Int = 1,
        encodingName: String = "UTF-8"
    ) {
        self.init(
            id: id,
            title: title,
            content: content,
            fileURL: fileURL,
            isModified: isModified,
            cursorPosition: TextPosition(line: cursorLine, column: cursorColumn),
            encodingName: encodingName
        )
    }

    public static func == (lhs: NoteTab, rhs: NoteTab) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.content == rhs.content &&
               lhs.fileURL == rhs.fileURL &&
               lhs.isModified == rhs.isModified &&
               lhs.cursorPosition == rhs.cursorPosition &&
               lhs.encodingName == rhs.encodingName
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
