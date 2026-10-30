import XCTest
@testable import iceNotePad

@MainActor
final class TabManagerTests: XCTestCase {
    var tempDirectory: URL!
    var sessionFileURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        sessionFileURL = tempDirectory.appendingPathComponent("test_session.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testInitialStateCreatesDefaultTab() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        manager.ensureAtLeastOneTab()

        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertEqual(manager.tabs.first?.title, "Untitled 1")
        XCTAssertEqual(manager.activeTabId, manager.tabs.first?.id)
    }

    func testAddNewTab() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        manager.ensureAtLeastOneTab()

        let tab2 = manager.newTab()
        XCTAssertEqual(manager.tabs.count, 2)
        XCTAssertEqual(tab2.title, "Untitled 2")
        XCTAssertEqual(manager.activeTabId, tab2.id)
    }

    func testCloseTab() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab1 = manager.newTab(title: "Tab 1")
        let tab2 = manager.newTab(title: "Tab 2")

        XCTAssertEqual(manager.activeTabId, tab2.id)

        manager.closeTab(id: tab2.id)
        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertEqual(manager.activeTabId, tab1.id)

        // Closing last tab should automatically create a fresh blank tab
        manager.closeTab(id: tab1.id)
        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertEqual(manager.tabs.first?.title, "Untitled 1")
    }

    func testSessionPersistenceAndRestoration() {
        let manager1 = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab1 = manager1.newTab(title: "Draft 1", content: "Hello world from tab 1")
        _ = manager1.newTab(title: "Draft 2", content: "Notes from Windows notepad")
        manager1.selectTab(id: tab1.id)

        manager1.saveSessionSync()

        XCTAssertTrue(FileManager.default.fileExists(atPath: sessionFileURL.path))

        // Create new manager that loads from the saved session
        let manager2 = TabManager(storageURL: sessionFileURL, autoLoad: true)
        XCTAssertEqual(manager2.tabs.count, 2)
        XCTAssertEqual(manager2.tabs[0].title, "Draft 1")
        XCTAssertEqual(manager2.tabs[0].content, "Hello world from tab 1")
        XCTAssertEqual(manager2.tabs[1].title, "Draft 2")
        XCTAssertEqual(manager2.tabs[1].content, "Notes from Windows notepad")
        XCTAssertEqual(manager2.activeTabId, tab1.id)
    }

    func testTabSwitchingByIndex() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab1 = manager.newTab(title: "Tab 1")
        let tab2 = manager.newTab(title: "Tab 2")
        let tab3 = manager.newTab(title: "Tab 3")

        manager.selectTab(index: 0)
        XCTAssertEqual(manager.activeTabId, tab1.id)

        manager.selectTab(index: 2)
        XCTAssertEqual(manager.activeTabId, tab3.id)

        manager.selectTab(index: 1)
        XCTAssertEqual(manager.activeTabId, tab2.id)
    }

    func testDuplicateTab() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab = manager.newTab(title: "MyDoc.txt", content: "Content of original tab")
        let dummyFileURL = tempDirectory.appendingPathComponent("MyDoc.txt")
        manager.markSaved(id: tab.id, fileURL: dummyFileURL)

        let duplicate = manager.duplicateTab(id: tab.id)
        XCTAssertNotNil(duplicate)
        XCTAssertEqual(duplicate?.title, "MyDoc.txt (Copy)")
        XCTAssertEqual(duplicate?.content, "Content of original tab")
        XCTAssertNil(duplicate?.fileURL)
        XCTAssertTrue(duplicate?.isModified == true)
        XCTAssertEqual(manager.activeTabId, duplicate?.id)
    }

    func testRenameTabWithoutPhysicalFile() throws {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab = manager.newTab(title: "Draft")
        try manager.renameTab(id: tab.id, newName: "RenamedDraft")

        let updated = manager.tabs.first(where: { $0.id == tab.id })
        XCTAssertEqual(updated?.title, "RenamedDraft")
        XCTAssertNil(updated?.fileURL)
    }

    func testRenameTabWithPhysicalFile() throws {
        let originalURL = tempDirectory.appendingPathComponent("original.txt")
        try "Test file content".write(to: originalURL, atomically: true, encoding: .utf8)

        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab = manager.newTab(title: "original.txt", content: "Test file content", fileURL: originalURL)

        let newFileName = "renamed.txt"
        let expectedNewURL = tempDirectory.appendingPathComponent(newFileName)

        try manager.renameTab(id: tab.id, newName: newFileName)

        let updated = manager.tabs.first(where: { $0.id == tab.id })
        XCTAssertEqual(updated?.title, newFileName)
        XCTAssertEqual(updated?.fileURL, expectedNewURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedNewURL.path))
    }

    func testRenameTabThrowsIfFileAlreadyExists() throws {
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        try "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Content 2".write(to: file2, atomically: true, encoding: .utf8)

        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab = manager.newTab(title: "file1.txt", content: "Content 1", fileURL: file1)

        XCTAssertThrowsError(try manager.renameTab(id: tab.id, newName: "file2.txt"))
    }

    func testDefaultStorageURLSafety() {
        let url = TabManager.defaultStorageURL
        XCTAssertFalse(url.path.isEmpty)
        XCTAssertTrue(url.path.contains("session.json"))
    }

    func testOpenDocumentReplacesEmptyTab() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        manager.ensureAtLeastOneTab()
        XCTAssertEqual(manager.tabs.count, 1)

        let testFile = tempDirectory.appendingPathComponent("sample.txt")
        manager.openDocument(url: testFile, content: "File content", encodingName: "UTF-8")

        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertEqual(manager.activeTab?.title, "sample.txt")
        XCTAssertEqual(manager.activeTab?.content, "File content")
        XCTAssertEqual(manager.activeTab?.fileURL, testFile)
        XCTAssertEqual(manager.activeTab?.encodingName, "UTF-8")
        XCTAssertFalse(manager.activeTab?.isModified ?? true)
    }

    func testOpenDocumentCreatesNewTabWhenActiveHasContent() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        _ = manager.newTab(title: "Draft", content: "Existing content")

        let testFile = tempDirectory.appendingPathComponent("another.txt")
        manager.openDocument(url: testFile, content: "New file content", encodingName: "Western (ISO Latin 1)")

        XCTAssertEqual(manager.tabs.count, 2)
        XCTAssertEqual(manager.activeTab?.title, "another.txt")
        XCTAssertEqual(manager.activeTab?.content, "New file content")
        XCTAssertEqual(manager.activeTab?.encodingName, "Western (ISO Latin 1)")
    }

    func testCursorPositionEncapsulation() {
        let manager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab = manager.newTab(title: "Cursor Test", content: "Line 1\nLine 2")

        manager.updateCursor(for: tab.id, position: TextPosition(line: 2, column: 5))

        let updated = manager.tabs.first(where: { $0.id == tab.id })
        XCTAssertEqual(updated?.cursorPosition, TextPosition(line: 2, column: 5))
        XCTAssertEqual(updated?.cursorLine, 2)
        XCTAssertEqual(updated?.cursorColumn, 5)
    }
}
