import Foundation

public struct TextPosition: Codable, Equatable, Sendable {
    public var line: Int
    public var column: Int

    public init(line: Int = 1, column: Int = 1) {
        self.line = line
        self.column = column
    }
}

public struct NoteTab: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var content: String
    public var fileURL: URL?
    public var isModified: Bool
    public var cursorPosition: TextPosition
    public var encoding: TextEncoding

    /// User-facing encoding name, kept for the status bar and legacy call sites.
    public var encodingName: String { encoding.rawValue }

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
        encoding: TextEncoding = .utf8
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.fileURL = fileURL
        self.isModified = isModified
        self.cursorPosition = cursorPosition
        self.encoding = encoding
    }

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        fileURL: URL? = nil,
        isModified: Bool = false,
        cursorLine: Int = 1,
        cursorColumn: Int = 1,
        encoding: TextEncoding = .utf8
    ) {
        self.init(
            id: id,
            title: title,
            content: content,
            fileURL: fileURL,
            isModified: isModified,
            cursorPosition: TextPosition(line: cursorLine, column: cursorColumn),
            encoding: encoding
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

        self.encoding = TextEncoding(rawValue: try container.decodeIfPresent(String.self, forKey: .encodingName) ?? "") ?? .utf8
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encode(isModified, forKey: .isModified)
        try container.encode(cursorPosition, forKey: .cursorPosition)
        try container.encode(encoding.rawValue, forKey: .encodingName)
    }

    public static func == (lhs: NoteTab, rhs: NoteTab) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.content == rhs.content &&
               lhs.fileURL == rhs.fileURL &&
               lhs.isModified == rhs.isModified &&
               lhs.cursorPosition == rhs.cursorPosition &&
               lhs.encoding == rhs.encoding
    }
}

public struct SessionState: Codable, Sendable {
    public var tabs: [NoteTab]
    public var activeTabId: UUID?
    public var untitledCounter: Int

    private enum CodingKeys: String, CodingKey {
        case tabs
        case activeTabId
        case untitledCounter
    }

    public init(tabs: [NoteTab], activeTabId: UUID?, untitledCounter: Int) {
        self.tabs = tabs
        self.activeTabId = activeTabId
        self.untitledCounter = untitledCounter
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tabs = try container.decodeIfPresent([NoteTab].self, forKey: .tabs) ?? []
        self.tabs = tabs
        self.activeTabId = try container.decodeIfPresent(UUID.self, forKey: .activeTabId)
        // Sessions written before untitledCounter existed must still load
        // instead of failing the whole decode and dropping every tab.
        self.untitledCounter = try container.decodeIfPresent(Int.self, forKey: .untitledCounter)
            ?? max(tabs.count + 1, 1)
    }
}
