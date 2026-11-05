import Foundation

/// The text encodings iceNotePad can read and write.
///
/// The raw value is the user-facing name shown in the status bar and stored in
/// `session.json`, so existing sessions keep decoding unchanged.
public enum TextEncoding: String, Codable, CaseIterable, Sendable {
    case utf8 = "UTF-8"
    case isoLatin1 = "Western (ISO Latin 1)"

    public var displayName: String { rawValue }

    public var stringEncoding: String.Encoding {
        switch self {
        case .utf8:
            return .utf8
        case .isoLatin1:
            return .isoLatin1
        }
    }
}
