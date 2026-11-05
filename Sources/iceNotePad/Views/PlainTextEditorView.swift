import SwiftUI
import AppKit

// Custom NSTextView ensuring pure plain text input and stripping rich text
public class PlainTextView: NSTextView {
    public var onCursorChange: ((Int, Int) -> Void)?

    public override func paste(_ sender: Any?) {
        // Enforce plain text paste: strip all styling/attributes
        if let string = NSPasteboard.general.string(forType: .string) {
            self.insertText(string, replacementRange: self.selectedRange())
        }
    }

    public override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        if type == .string, let string = pboard.string(forType: .string) {
            self.insertText(string, replacementRange: self.selectedRange())
            return true
        }
        return false
    }

    public override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return [.string]
    }

    public override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        return [.string, .fileURL]
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        if let string = pboard.string(forType: .string) {
            self.insertText(string, replacementRange: self.selectedRange())
            return true
        }
        return super.performDragOperation(sender)
    }

    public func calculateCursorPosition() {
        let text = self.string as NSString
        let location = min(self.selectedRange().location, text.length)
        let prefix = text.substring(to: location)
        let lines = prefix.components(separatedBy: "\n")
        let line = max(lines.count, 1)
        let column = max((lines.last?.utf16.count ?? 0) + 1, 1)
        onCursorChange?(line, column)
    }

    /// Paints a persistent find highlight without touching the text storage,
    /// so plain-text content and undo history stay untouched.
    public func setSearchHighlight(_ range: NSRange?) {
        guard let layoutManager = self.layoutManager else { return }

        let fullRange = NSRange(location: 0, length: (self.string as NSString).length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)

        guard let range = range,
              range.location != NSNotFound,
              range.length > 0,
              range.location + range.length <= fullRange.length else {
            return
        }

        layoutManager.addTemporaryAttribute(
            .backgroundColor,
            value: NSColor.findHighlightColor,
            forCharacterRange: range
        )
    }

    /// UTF-16 offset for a one-based line/column pair, clamped to the text length.
    public func characterOffset(for position: TextPosition) -> Int {
        let text = self.string as NSString
        let targetLine = max(1, position.line)
        var offset = 0
        var line = 1

        while line < targetLine {
            let remaining = NSRange(location: offset, length: text.length - offset)
            let newline = text.range(of: "\n", options: [], range: remaining)
            if newline.location == NSNotFound {
                return text.length
            }
            offset = newline.location + newline.length
            line += 1
        }

        return min(offset + max(0, position.column - 1), text.length)
    }
}

public struct PlainTextEditorView: NSViewRepresentable {
    @Binding public var text: String
    @Binding public var searchTargetRange: NSRange?
    public var fontSize: Double
    public var isMonospace: Bool
    public var wordWrap: Bool
    public var initialCursorPosition: TextPosition?
    public var onCursorChange: ((Int, Int) -> Void)?

    public init(
        text: Binding<String>,
        searchTargetRange: Binding<NSRange?> = .constant(nil),
        fontSize: Double = 14.0,
        isMonospace: Bool = true,
        wordWrap: Bool = true,
        initialCursorPosition: TextPosition? = nil,
        onCursorChange: ((Int, Int) -> Void)? = nil
    ) {
        self._text = text
        self._searchTargetRange = searchTargetRange
        self.fontSize = fontSize
        self.isMonospace = isMonospace
        self.wordWrap = wordWrap
        self.initialCursorPosition = initialCursorPosition
        self.onCursorChange = onCursorChange
    }

    private func applySearchHighlight(_ range: NSRange?, to textView: PlainTextView) {
        let length = (textView.string as NSString).length
        if let range = range,
           range.location != NSNotFound,
           range.location + range.length <= length {
            textView.scrollRangeToVisible(range)
            textView.setSearchHighlight(range)
        } else {
            textView.setSearchHighlight(nil)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wordWrap
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let contentSize = scrollView.contentSize
        let textView = PlainTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0.0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !wordWrap
        textView.autoresizingMask = wordWrap ? [.width] : []

        if wordWrap {
            textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = true
        } else {
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = false
        }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsImageEditing = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.drawsBackground = false

        textView.font = AppSettings.font(size: CGFloat(fontSize), isMonospace: isMonospace)
        textView.textColor = .textColor
        textView.string = text

        if let initialCursorPosition = initialCursorPosition {
            let offset = textView.characterOffset(for: initialCursorPosition)
            textView.setSelectedRange(NSRange(location: offset, length: 0))
        }

        textView.onCursorChange = { line, col in
            context.coordinator.parent.onCursorChange?(line, col)
        }

        context.coordinator.textView = textView
        scrollView.documentView = textView

        DispatchQueue.main.async {
            textView.calculateCursorPosition()
        }

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? PlainTextView else { return }

        // Update font if changed
        let font = AppSettings.font(size: CGFloat(fontSize), isMonospace: isMonospace)
        if textView.font?.pointSize != CGFloat(fontSize) || textView.font != font {
            textView.font = font
        }

        // Update word wrap if changed
        if nsView.hasHorizontalScroller == wordWrap {
            nsView.hasHorizontalScroller = !wordWrap
            textView.isHorizontallyResizable = !wordWrap
            textView.autoresizingMask = wordWrap ? [.width] : []
            if wordWrap {
                textView.textContainer?.containerSize = NSSize(width: nsView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
                textView.textContainer?.widthTracksTextView = true
            } else {
                textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textView.textContainer?.widthTracksTextView = false
            }
        }

        // Update text without disrupting cursor position
        var textDidChange = false
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textDidChange = true
            let strLength = (text as NSString).length
            if selectedRange.location + selectedRange.length <= strLength {
                textView.setSelectedRange(selectedRange)
            }
        }

        // Highlight the current search match with a temporary background attribute.
        // This keeps the colour constant regardless of which control has focus,
        // instead of mixing the transient find indicator with the selection colour.
        let target = searchTargetRange
        if target != context.coordinator.lastTargetRange {
            context.coordinator.lastTargetRange = target
            applySearchHighlight(target, to: textView)
        } else if textDidChange, let target = target {
            // Replacing the string clears temporary attributes, so repaint.
            applySearchHighlight(target, to: textView)
        }
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditorView
        weak var textView: PlainTextView?
        var lastTargetRange: NSRange?

        init(_ parent: PlainTextEditorView) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            let currentString = textView.string
            if parent.text != currentString {
                parent.text = currentString
            }
            textView.calculateCursorPosition()
        }

        public func textViewDidChangeSelection(_ notification: Notification) {
            textView?.calculateCursorPosition()
        }
    }
}
