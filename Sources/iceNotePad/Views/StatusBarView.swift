import SwiftUI

public struct StatusBarView: View {
    public let line: Int
    public let column: Int
    public let text: String
    @ObservedObject public var settings: AppSettings

    public init(line: Int, column: Int, text: String, settings: AppSettings) {
        self.line = line
        self.column = column
        self.text = text
        self.settings = settings
    }

    private var lineEnding: String {
        if text.contains("\r\n") {
            return "Windows (CRLF)"
        } else if text.contains("\r") {
            return "Classic Mac (CR)"
        } else {
            return "Unix (LF)"
        }
    }

    private var characterCount: Int {
        text.count
    }

    public var body: some View {
        HStack(spacing: 16) {
            Text("Ln \(line), Col \(column)")
                .frame(minWidth: 90, alignment: .leading)

            Divider()
                .frame(height: 12)

            Text("\(characterCount) characters")
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            // Zoom level
            Menu {
                Button("Zoom In (Cmd +)") { settings.zoomIn() }
                Button("Zoom Out (Cmd -)") { settings.zoomOut() }
                Button("Reset Zoom (Cmd 0)") { settings.zoomReset() }
            } label: {
                Text("\(settings.zoomPercentage)%")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Divider()
                .frame(height: 12)

            Text(lineEnding)
                .fixedSize()

            Divider()
                .frame(height: 12)

            Text("UTF-8")
                .fixedSize()
        }
        .font(.system(size: 11))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 22)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .top
        )
    }
}

