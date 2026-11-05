import XCTest
@testable import iceNotePad

@MainActor
final class FileOperationsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testReadFileContentUTF8() throws {
        let fileURL = tempDirectory.appendingPathComponent("utf8_sample.txt")
        let sampleText = "สวัสดีชาวโลก Hello UTF-8"
        try sampleText.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = try FileOperations.readFileContent(from: fileURL)
        XCTAssertEqual(result.content, sampleText)
        XCTAssertEqual(result.encoding, .utf8)
    }

    func testReadFileContentISOLatin1Fallback() throws {
        let fileURL = tempDirectory.appendingPathComponent("latin1_sample.txt")
        // Byte sequence that is valid ISO-8859-1 but invalid UTF-8
        let invalidUTF8Bytes: [UInt8] = [0xA9, 0x20, 0x32, 0x30, 0x32, 0x36] // Copyright symbol in ISO-8859-1
        let data = Data(invalidUTF8Bytes)
        try data.write(to: fileURL)

        let result = try FileOperations.readFileContent(from: fileURL)
        XCTAssertFalse(result.content.isEmpty)
        XCTAssertEqual(result.encoding, .isoLatin1)
    }

    func testSaveFilePreservesISOLatin1Encoding() throws {
        let fileURL = tempDirectory.appendingPathComponent("latin1_doc.txt")
        let originalText = "café"
        try originalText.write(to: fileURL, atomically: true, encoding: .isoLatin1)

        let tab = NoteTab(title: "latin1_doc.txt", content: "café", fileURL: fileURL, encoding: .isoLatin1)

        var savedURL: URL?
        FileOperations.saveFile(tab: tab, forceSaveAs: false) { url in
            savedURL = url
        }

        XCTAssertEqual(savedURL, fileURL)

        let data = try Data(contentsOf: fileURL)
        // ISO Latin 1 writes "é" as a single byte; UTF-8 would need two.
        XCTAssertEqual(data, Data([0x63, 0x61, 0x66, 0xE9]))
        XCTAssertEqual(String(data: data, encoding: .isoLatin1), originalText)
        XCTAssertNil(String(data: data, encoding: .utf8))
    }
}

