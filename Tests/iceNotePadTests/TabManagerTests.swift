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
}
