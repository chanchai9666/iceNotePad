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

    func testCalculateTabMetricsWideScreenSupportsManyTabsInSingleRow() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tabBarView = TabBarView(tabManager: tabManager)

        // 13 tabs on a 1600px wide window (like fullscreen or wide monitor) should stay in 1 row
        let tabs13 = (1...13).map { NoteTab(title: "Tab \($0)") }
        let metrics13 = tabBarView.calculateTabMetrics(availableWidth: 1600, tabs: tabs13)
        XCTAssertFalse(metrics13.isTwoRows, "13 tabs should easily fit in 1 row at 1600px width")
        XCTAssertEqual(metrics13.row1Tabs.count, 13)
        XCTAssertEqual(metrics13.row2Tabs.count, 0)
        XCTAssertFalse(metrics13.row1NeedsScroll)
        XCTAssertGreaterThanOrEqual(metrics13.row1TabWidth, 90)
        XCTAssertLessThanOrEqual(metrics13.row1TabWidth, 180)
    }

    func testCalculateTabMetricsRowWidthNeverExceedsAvailableWidthDueToRounding() {
        let tabManager = TabManager(storageURL: sessionFileURL, autoLoad: false)
        let tabBarView = TabBarView(tabManager: tabManager)

        for width in stride(from: 600.0, through: 2000.0, by: 100.0) {
            for count in 1...20 {
                let tabs = (1...count).map { NoteTab(title: "Tab \($0)") }
                let metrics = tabBarView.calculateTabMetrics(availableWidth: width, tabs: tabs)

                if !metrics.isTwoRows {
                    let spacing = CGFloat(count) * 2.0
                    let tabsTotal = CGFloat(count) * metrics.row1TabWidth
                    let totalNeeded = tabsTotal + spacing + 40.0
                    if !metrics.row1NeedsScroll {
                        XCTAssertLessThanOrEqual(totalNeeded, width + 0.001, "Row 1 total content must not exceed available width (\(width)) for count \(count)")
                    }
                } else {
                    let r1Count = metrics.row1Tabs.count
                    let r1Spacing = CGFloat(max(0, r1Count - 1)) * 2.0
                    let r1Total = CGFloat(r1Count) * metrics.row1TabWidth + r1Spacing + 8.0
                    if !metrics.row1NeedsScroll {
                        XCTAssertLessThanOrEqual(r1Total, width + 0.001, "Two-row Row 1 total content must not exceed available width (\(width))")
                    }

                    let r2Count = metrics.row2Tabs.count
                    let r2Spacing = CGFloat(r2Count) * 2.0
                    let r2Total = CGFloat(r2Count) * metrics.row2TabWidth + r2Spacing + 40.0
                    if !metrics.row2NeedsScroll {
                        XCTAssertLessThanOrEqual(r2Total, width + 0.001, "Two-row Row 2 total content must not exceed available width (\(width))")
                    }
                }
            }
        }
    }

    func testTabBarWidthPreferenceKeyReductionPreservesValidWidth() {
        var value: CGFloat = 0
        TabBarWidthPreferenceKey.reduce(value: &value) { 1440.0 }
        XCTAssertEqual(value, 1440.0)

        // Empty branch or default returning 0 must not overwrite the valid value
        TabBarWidthPreferenceKey.reduce(value: &value) { 0.0 }
        XCTAssertEqual(value, 1440.0)

        // Subsequent valid update should overwrite
        TabBarWidthPreferenceKey.reduce(value: &value) { 1600.0 }
        XCTAssertEqual(value, 1600.0)
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

