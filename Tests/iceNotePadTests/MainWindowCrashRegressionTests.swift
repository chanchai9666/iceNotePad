import XCTest
import SwiftUI
@testable import iceNotePad

@MainActor
final class MainWindowCrashRegressionTests: XCTestCase {
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

    func testClosingActiveTabDoesNotCrashViewHierarchy() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        tabManager.ensureAtLeastOneTab()

        let tab2 = tabManager.newTab(title: "Tab 2", content: "Second tab content")
        XCTAssertEqual(tabManager.tabs.count, 2)
        XCTAssertEqual(tabManager.activeTabId, tab2.id)

        let mainWindow = MainWindowView(tabManager: tabManager)
        let hosting = NSHostingView(rootView: mainWindow)
        hosting.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        hosting.layoutSubtreeIfNeeded()

        // Close the active tab (index 1). In the previous code with $tabManager.tabs[index],
        // this triggers a crash in SwiftUI when reading old subscript binding.
        tabManager.closeTab(id: tab2.id)
        hosting.layoutSubtreeIfNeeded()

        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.activeTabId, tabManager.tabs.first?.id)
    }
}

