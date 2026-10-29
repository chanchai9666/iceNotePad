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
}
