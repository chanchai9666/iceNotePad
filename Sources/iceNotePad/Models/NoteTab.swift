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

    enum CodingKeys: String, CodingKey {
        case id, title, content, fileURL, isModified, cursorPosition, encodingName
        case cursorLine, cursorColumn
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.fileURL = try container.decodeIfPresent(URL.self, forKey: .fileURL)
        self.isModified = try container.decode(Bool.self, forKey: .isModified)

        if let position = try container.decodeIfPresent(TextPosition.self, forKey: .cursorPosition) {
            self.cursorPosition = position
        } else {
            let line = try container.decodeIfPresent(Int.self, forKey: .cursorLine) ?? 1
            let col = try container.decodeIfPresent(Int.self, forKey: .cursorColumn) ?? 1
            self.cursorPosition = TextPosition(line: line, column: col)
        }

        self.encodingName = try container.decodeIfPresent(String.self, forKey: .encodingName) ?? "UTF-8"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encode(isModified, forKey: .isModified)
        try container.encode(cursorPosition, forKey: .cursorPosition)
        try container.encode(encodingName, forKey: .encodingName)
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
