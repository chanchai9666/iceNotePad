import SwiftUI
import AppKit

@main
struct iceNotePadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var tabManager = TabManager()
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainWindowView(tabManager: tabManager, settings: settings)
                .onAppear {
                    appDelegate.tabManager = tabManager
                }
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

