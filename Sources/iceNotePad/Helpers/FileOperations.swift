import AppKit
import UniformTypeIdentifiers

@MainActor
public class FileOperations {
    public static func showErrorAlert(title: String, message: String, style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }

    public static func readFileContent(from url: URL) throws -> (content: String, encodingName: String) {
        if let utf8Content = try? String(contentsOf: url, encoding: .utf8) {
            return (utf8Content, "UTF-8")
        }
        if let latin1Content = try? String(contentsOf: url, encoding: .isoLatin1) {
            return (latin1Content, "Western (ISO Latin 1)")
        }
        throw NSError(
            domain: "iceNotePad.FileOperations",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unsupported text encoding or corrupted file."]
        )
    }

    public static func openFile(completion: @escaping (URL, String, String) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Open Document"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.plainText, .text, .utf8PlainText, .sourceCode]

        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let result = try readFileContent(from: url)
                completion(url, result.content, result.encodingName)
            } catch {
                showErrorAlert(title: "Failed to open file", message: error.localizedDescription, style: .warning)
            }
        }
    }

    public static func openFile(completion: @escaping (URL, String) -> Void) {
        openFile { url, content, _ in
            completion(url, content)
        }
    }

    public static func saveFile(tab: NoteTab, forceSaveAs: Bool, completion: @escaping (URL) -> Void) {
        if let fileURL = tab.fileURL, !forceSaveAs {
            do {
                try tab.content.write(to: fileURL, atomically: true, encoding: .utf8)
                completion(fileURL)
            } catch {
                showErrorAlert(title: "Failed to save file", message: error.localizedDescription, style: .critical)
            }
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "Save As"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [.plainText]

        var defaultName = tab.title
        if !defaultName.contains(".") {
            defaultName += ".txt"
        }
        savePanel.nameFieldStringValue = defaultName

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try tab.content.write(to: url, atomically: true, encoding: .utf8)
                completion(url)
            } catch {
                showErrorAlert(title: "Failed to save file", message: error.localizedDescription, style: .critical)
            }
        }
    }
}
