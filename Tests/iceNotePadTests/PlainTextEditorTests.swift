import XCTest
import AppKit
@testable import iceNotePad

@MainActor
final class PlainTextEditorTests: XCTestCase {
    func testPlainTextViewRejectsRichTextOnPaste() {
        let textView = PlainTextView()
        textView.isRichText = false

        // Place rich text in pasteboard with colors and attributes
        let pboard = NSPasteboard.general
        pboard.clearContents()

        let attributed = NSAttributedString(
            string: "Formatted Bold Red Text",
            attributes: [
                .foregroundColor: NSColor.red,
                .font: NSFont.boldSystemFont(ofSize: 24)
            ]
        )
        pboard.writeObjects([attributed])

        // Call paste on PlainTextView
        textView.paste(nil)

        // Text should be plain string, font should NOT be infected with red color or 24pt bold
        XCTAssertEqual(textView.string, "Formatted Bold Red Text")
        var dict: [NSAttributedString.Key: Any] = [:]
        if textView.textStorage?.length ?? 0 > 0 {
            dict = textView.textStorage?.attributes(at: 0, effectiveRange: nil) ?? [:]
        }
        // Should not have the rich red color from the pasteboard
        if let color = dict[.foregroundColor] as? NSColor {
            XCTAssertNotEqual(color, NSColor.red)
        }
    }

    func testCursorPositionCalculation() {
        let textView = PlainTextView()
        textView.string = "Line 1\nLine 2 text\nLine 3"

        var reportedLine: Int = 0
        var reportedCol: Int = 0
        textView.onCursorChange = { line, col in
            reportedLine = line
            reportedCol = col
        }

        // Set cursor to start of Line 2 (index 7: "Line 1\n")
        textView.setSelectedRange(NSRange(location: 7, length: 0))
        textView.calculateCursorPosition()

        XCTAssertEqual(reportedLine, 2)
        XCTAssertEqual(reportedCol, 1)

        // Set cursor to middle of Line 2 ("Line 2 ") -> location 14
        textView.setSelectedRange(NSRange(location: 14, length: 0))
        textView.calculateCursorPosition()

        XCTAssertEqual(reportedLine, 2)
        XCTAssertEqual(reportedCol, 8)
    }

    func testSearchHighlightUsesTemporaryAttributesWithoutTouchingTextStorage() throws {
        let textView = PlainTextView()
        textView.string = "hello world hello"

        let matchRange = NSRange(location: 12, length: 5)
        textView.setSearchHighlight(matchRange)

        let layoutManager = try XCTUnwrap(textView.layoutManager)

        var effectiveRange = NSRange()
        let highlight = layoutManager.temporaryAttribute(
            .backgroundColor,
            atCharacterIndex: matchRange.location,
            effectiveRange: &effectiveRange
        )
        XCTAssertNotNil(highlight)
        XCTAssertEqual(effectiveRange, matchRange)

        // Outside the match must stay unhighlighted.
        XCTAssertNil(layoutManager.temporaryAttribute(
            .backgroundColor,
            atCharacterIndex: 0,
            effectiveRange: nil
        ))

        // Plain-text guarantee: text storage keeps no background attribute.
        let storageAttributes = textView.textStorage?.attributes(at: matchRange.location, effectiveRange: nil) ?? [:]
        XCTAssertNil(storageAttributes[.backgroundColor])

        textView.setSearchHighlight(nil)
        XCTAssertNil(layoutManager.temporaryAttribute(
            .backgroundColor,
            atCharacterIndex: matchRange.location,
            effectiveRange: nil
        ))
    }

    func testSearchHighlightIgnoresOutOfBoundsRange() throws {
        let textView = PlainTextView()
        textView.string = "short"

        textView.setSearchHighlight(NSRange(location: 3, length: 10))

        let layoutManager = try XCTUnwrap(textView.layoutManager)
        XCTAssertNil(layoutManager.temporaryAttribute(
            .backgroundColor,
            atCharacterIndex: 0,
            effectiveRange: nil
        ))
    }
}
