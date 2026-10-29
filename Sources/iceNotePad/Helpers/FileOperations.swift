import AppKit
import UniformTypeIdentifiers

@MainActor
public class FileOperations {
    public static func openFile(completion: @escaping (URL, String) -> Void) {
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
                let content = try String(contentsOf: url, encoding: .utf8)
                completion(url, content)
            } catch {
                // Fallback to ASCII/latin1 if UTF-8 fails
                if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                    completion(url, content)
                } else {
                    let alert = NSAlert()
                    alert.messageText = "Failed to open file"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    public static func saveFile(tab: NoteTab, forceSaveAs: Bool, completion: @escaping (URL) -> Void) {
        if let fileURL = tab.fileURL, !forceSaveAs {
            do {
                try tab.content.write(to: fileURL, atomically: true, encoding: .utf8)
                completion(fileURL)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to save file"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
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
                let alert = NSAlert()
                alert.messageText = "Failed to save file"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}
