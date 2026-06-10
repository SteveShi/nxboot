import Foundation
import Observation

@Observable
@MainActor
class CLIInstaller {
    static let shared = CLIInstaller()
    
    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: AppConstants.cliInstallPath)
    }

    func install() async throws {
        // Find the embedded tool. When embedded as a dependency, it's usually in the bundle resources or a specific subdirectory.
        // If xcodegen embeds it as a 'tool', it might be in Contents/Helpers or just the main bundle.
        // We'll search for 'nxboot' in the bundle.
        guard let toolURL = Bundle.main.url(forResource: AppConstants.cliToolName, withExtension: nil) ??
                Bundle.main.url(forResource: "NXBootCmd", withExtension: nil) else {
            throw NSError(domain: "CLIInstaller", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "CLI tool not found in bundle")])
        }

        let binDir = URL(fileURLWithPath: AppConstants.cliInstallPath).deletingLastPathComponent().path
        let destinationPath = AppConstants.cliInstallPath
        let sourcePath = toolURL.path

        // Use osascript to copy with elevator privileges.
        // First ensure /usr/local/bin exists.
        let command = "mkdir -p \(binDir) && cp '\(sourcePath)' '\(destinationPath)' && chmod +x '\(destinationPath)'"
        let script = "do shell script \"\(command)\" with administrator privileges"

        try await executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) async throws {
        try await Task.detached {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: source) {
                scriptObject.executeAndReturnError(&error)
                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    throw NSError(domain: "CLIInstaller", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
                }
            } else {
                throw NSError(domain: "CLIInstaller", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create AppleScript object"])
            }
        }.value
    }
}
