import SwiftUI
import Combine

@MainActor
public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @AppStorage("fontSize") public var fontSize: Double = 14.0
    @AppStorage("isMonospace") public var isMonospace: Bool = true
    @AppStorage("wordWrap") public var wordWrap: Bool = true

    public let defaultFontSize: Double = 14.0
    public let minFontSize: Double = 8.0
    public let maxFontSize: Double = 48.0

    public func zoomIn() {
        fontSize = min(fontSize + 2.0, maxFontSize)
    }

    public func zoomOut() {
        fontSize = max(fontSize - 2.0, minFontSize)
    }

    public func zoomReset() {
        fontSize = defaultFontSize
    }

    public var zoomPercentage: Int {
        Int((fontSize / defaultFontSize) * 100)
    }

    public func font(for size: CGFloat) -> NSFont {
        if isMonospace {
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        } else {
            return NSFont.systemFont(ofSize: size)
        }
    }
}

