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
}

public struct PlainTextEditorView: NSViewRepresentable {
    @Binding public var text: String
    public var fontSize: Double
    public var isMonospace: Bool
    public var wordWrap: Bool
    public var onCursorChange: ((Int, Int) -> Void)?

    public init(
        text: Binding<String>,
        fontSize: Double = 14.0,
        isMonospace: Bool = true,
        wordWrap: Bool = true,
        onCursorChange: ((Int, Int) -> Void)? = nil
    ) {
        self._text = text
        self.fontSize = fontSize
        self.isMonospace = isMonospace
        self.wordWrap = wordWrap
        self.onCursorChange = onCursorChange
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

        let font = isMonospace ? NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
                               : NSFont.systemFont(ofSize: CGFloat(fontSize))
        textView.font = font
        textView.textColor = .textColor
        textView.string = text

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
        let font = isMonospace ? NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
                               : NSFont.systemFont(ofSize: CGFloat(fontSize))
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
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            if selectedRange.location <= (text as NSString).length {
                textView.setSelectedRange(selectedRange)
            }
        }
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditorView
        weak var textView: PlainTextView?

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

