import SwiftUI
import AppKit

@main
struct iceNotePadApp: App {
    @StateObject private var tabManager = TabManager()
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainWindowView(tabManager: tabManager, settings: settings)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    tabManager.saveSessionSync()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            IceNotePadCommands(tabManager: tabManager, settings: settings)
        }
    }
}
