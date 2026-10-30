import XCTest
import SwiftUI
@testable import iceNotePad

@MainActor
final class TabBarViewTests: XCTestCase {
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

    func testDoubleClickEmptyAreaCreatesNewTab() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let initialTabCount = tabManager.tabs.count

        let tabBarView = TabBarView(tabManager: tabManager)
        tabBarView.handleEmptyAreaDoubleClick()

        XCTAssertEqual(tabManager.tabs.count, initialTabCount + 1)
        XCTAssertEqual(tabManager.activeTabId, tabManager.tabs.last?.id)
    }

    func testCustomDoubleClickEmptyAreaHandlerIsCalled() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        var customHandlerCalled = false

        let tabBarView = TabBarView(tabManager: tabManager, onDoubleClickEmptyArea: {
            customHandlerCalled = true
        })
        tabBarView.handleEmptyAreaDoubleClick()

        XCTAssertTrue(customHandlerCalled)
    }
}

