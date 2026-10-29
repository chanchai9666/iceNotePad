import SwiftUI

public struct FindReplaceBarView: View {
    @Binding public var isPresented: Bool
    @Binding public var text: String

    @State private var searchText: String = ""
    @State private var replaceText: String = ""
    @State private var isReplaceExpanded: Bool = false
    @State private var matchCase: Bool = false
    @State private var matchCount: Int = 0
    @State private var currentMatchIndex: Int = 0

    public init(isPresented: Binding<Bool>, text: Binding<String>) {
        self._isPresented = isPresented
        self._text = text
    }

    private func findMatches() -> [Range<String.Index>] {
        guard !searchText.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = text.startIndex

        let options: String.CompareOptions = matchCase ? [] : [.caseInsensitive]

        while searchStartIndex < text.endIndex,
              let range = text.range(of: searchText, options: options, range: searchStartIndex..<text.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        return ranges
    }

    private func updateMatchCount() {
        let matches = findMatches()
        matchCount = matches.count
        if matchCount == 0 {
            currentMatchIndex = 0
        } else if currentMatchIndex >= matchCount {
            currentMatchIndex = 0
        }
    }

    private func replaceCurrent() {
        let matches = findMatches()
        guard !matches.isEmpty, currentMatchIndex < matches.count else { return }
        let range = matches[currentMatchIndex]
        text.replaceSubrange(range, with: replaceText)
        updateMatchCount()
    }

    private func replaceAll() {
        guard !searchText.isEmpty else { return }
        if matchCase {
            text = text.replacingOccurrences(of: searchText, with: replaceText)
        } else {
            text = text.replacingOccurrences(of: searchText, with: replaceText, options: .caseInsensitive)
        }
        updateMatchCount()
    }

    public var body: some View {
        VStack(spacing: 6) {
            // Find Row
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isReplaceExpanded.toggle()
                    }
                }) {
                    Image(systemName: isReplaceExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))

                    TextField("Find", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onChange(of: searchText) { _ in
                            updateMatchCount()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .frame(width: 220)

                // Match count indicator
                if !searchText.isEmpty {
                    Text(matchCount > 0 ? "\(matchCount) matches" : "No matches")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 70, alignment: .leading)
                }

                // Match Case Toggle
                Toggle(isOn: $matchCase) {
                    Text("Aa")
                        .font(.system(size: 11, weight: .bold))
                }
                .toggleStyle(.button)
                .help("Match Case")
                .onChange(of: matchCase) { _ in
                    updateMatchCount()
                }

                Spacer()

                // Close Button
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }

            // Replace Row
            if isReplaceExpanded {
                HStack(spacing: 8) {
                    Spacer().frame(width: 16)

                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))

                        TextField("Replace", text: $replaceText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .frame(width: 220)

                    Button("Replace") {
                        replaceCurrent()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(matchCount == 0)

                    Button("Replace All") {
                        replaceAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(matchCount == 0)

                    Spacer()
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

