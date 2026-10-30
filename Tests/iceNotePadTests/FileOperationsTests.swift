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
        XCTAssertEqual(result.encodingName, "UTF-8")
    }

    func testReadFileContentISOLatin1Fallback() throws {
        let fileURL = tempDirectory.appendingPathComponent("latin1_sample.txt")
        // Byte sequence that is valid ISO-8859-1 but invalid UTF-8
        let invalidUTF8Bytes: [UInt8] = [0xA9, 0x20, 0x32, 0x30, 0x32, 0x36] // Copyright symbol in ISO-8859-1
        let data = Data(invalidUTF8Bytes)
        try data.write(to: fileURL)

        let result = try FileOperations.readFileContent(from: fileURL)
        XCTAssertFalse(result.content.isEmpty)
        XCTAssertEqual(result.encodingName, "Western (ISO Latin 1)")
    }
}
