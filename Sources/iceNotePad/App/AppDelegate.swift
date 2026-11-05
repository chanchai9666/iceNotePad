import AppKit

/// Receives documents opened from Finder (the app declares
/// `CFBundleDocumentTypes`) and routes them into the shared TabManager.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var tabManager: TabManager? {
        didSet { flushPendingURLs() }
    }

    private var pendingURLs: [URL] = []

    public func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            if self.tabManager == nil {
                self.pendingURLs.append(contentsOf: urls)
            } else {
                self.open(urls)
            }
        }
    }

    private func flushPendingURLs() {
        guard tabManager != nil, !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs.removeAll()
        open(urls)
    }

    @MainActor
    private func open(_ urls: [URL]) {
        guard let tabManager = tabManager else { return }
        for url in urls {
            do {
                let result = try FileOperations.readFileContent(from: url)
                tabManager.openDocument(url: url, content: result.content, encoding: result.encoding)
            } catch {
                FileOperations.showErrorAlert(
                    title: "Failed to open file",
                    message: error.localizedDescription
                )
            }
        }
    }
}
