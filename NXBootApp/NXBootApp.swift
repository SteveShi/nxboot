import SwiftUI

@main
struct NXBootApp: App {
    @State private var payloadManager = PayloadManager()
    @State private var deviceManager = DeviceManager()
    @State private var logger = Logger.shared
    @State private var hekateManager = HekateManager.shared
    @State private var cliInstaller = CLIInstaller.shared
    
    init() {
        // Enable NXBootKit debug logs so they are captured by Logger
        NXBootKitSetDebugEnabled(true)
    }
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
            MainLayoutView()
                .environment(payloadManager)
                .environment(deviceManager)
                .environment(logger)
                .environment(hekateManager)
                .environment(cliInstaller)
                .onAppear {
                    deviceManager.startMonitoring()
                }
        }
        .windowStyle(.hiddenTitleBar)
        
        Window(String(localized: "About NXBoot"), id: "about") {
            AboutView()
                .environment(cliInstaller)
                .frame(width: 400, height: 450)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(String(localized: "About NXBoot")) {
                    openWindow(id: "about")
                }
            }
        }
    }
}
