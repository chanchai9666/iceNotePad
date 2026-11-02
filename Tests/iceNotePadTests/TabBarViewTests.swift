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

    func testMultipleTabsLayoutRendersWithoutCrash() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        for i in 1...15 {
            tabManager.newTab(title: "Tab \(i)", content: "Content \(i)")
        }

        let tabBarView = TabBarView(tabManager: tabManager)
        let hostingView = NSHostingView(rootView: tabBarView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 34)
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertEqual(tabManager.tabs.count, 15)
        XCTAssertNotNil(hostingView)
    }

    func testTabSwitchingPreservesModifiedState() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tab1 = tabManager.newTab(title: "File 1", content: "Original 1")
        let tab2 = tabManager.newTab(title: "File 2", content: "Original 2")

        XCTAssertFalse(tab1.isModified)
        XCTAssertFalse(tab2.isModified)

        let mainWindow = MainWindowView(tabManager: tabManager)
        let hostingView = NSHostingView(rootView: mainWindow)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        hostingView.layoutSubtreeIfNeeded()

        // Switch to tab 1
        tabManager.selectTab(id: tab1.id)
        hostingView.layoutSubtreeIfNeeded()

        // Switch to tab 2
        tabManager.selectTab(id: tab2.id)
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertFalse(tabManager.tabs.first(where: { $0.id == tab1.id })?.isModified ?? true, "Tab 1 must not be marked modified on tab switch")
        XCTAssertFalse(tabManager.tabs.first(where: { $0.id == tab2.id })?.isModified ?? true, "Tab 2 must not be marked modified on tab switch")
    }

    func testCalculateTabMetricsSingleRowVsTwoRows() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tabBarView = TabBarView(tabManager: tabManager)

        // 3 tabs in 800px width should stay in 1 row
        let tabs3 = (1...3).map { NoteTab(title: "Tab \($0)") }
        let metrics3 = tabBarView.calculateTabMetrics(availableWidth: 800, tabs: tabs3)
        XCTAssertFalse(metrics3.isTwoRows)
        XCTAssertEqual(metrics3.row1Tabs.count, 3)
        XCTAssertEqual(metrics3.row2Tabs.count, 0)
        XCTAssertFalse(metrics3.row1NeedsScroll)

        // 10 tabs in 800px width should split into 2 rows
        let tabs10 = (1...10).map { NoteTab(title: "Tab \($0)") }
        let metrics10 = tabBarView.calculateTabMetrics(availableWidth: 800, tabs: tabs10)
        XCTAssertTrue(metrics10.isTwoRows)
        XCTAssertEqual(metrics10.row1Tabs.count, 5)
        XCTAssertEqual(metrics10.row2Tabs.count, 5)
    }

    func testTabItemViewTooltipText() {
        let untitledTab = NoteTab(title: "Untitled 1")
        let item1 = TabItemView(tab: untitledTab, isActive: true, onSelect: {}, onClose: {}, onDuplicate: {}, onRename: {})
        XCTAssertEqual(item1.tooltipText, "Untitled 1")

        let fileURL = URL(fileURLWithPath: "/tmp/documents/report.txt")
        let savedTab = NoteTab(title: "report.txt", fileURL: fileURL)
        let item2 = TabItemView(tab: savedTab, isActive: false, onSelect: {}, onClose: {}, onDuplicate: {}, onRename: {})
        XCTAssertEqual(item2.tooltipText, "report.txt\n/tmp/documents/report.txt")
    }
}

