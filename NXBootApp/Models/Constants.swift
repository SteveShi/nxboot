import Foundation

enum AppConstants {
    // USB Device Identifiers (Tegra X1 RCM Mode)
    static let tegraX1VendorID: UInt16 = 0x0955
    static let tegraX1ProductID: UInt16 = 0x7321

    // Paths
    static let cliToolName = "nxboot"
    static let cliInstallPath = "/usr/local/bin/nxboot"
    static let payloadsSubdirectory = "Payloads"

    // USB Communication (Default values)
    static let defaultUSBReadTimeoutMS: UInt32 = 1000
    static let minUSBReadTimeoutMS: UInt32 = 100
    static let maxUSBReadTimeoutMS: UInt32 = 10000
    static let usbReadSleepNS: UInt64 = 10_000_000 // 10ms
    static let usbBufferSize = 0x1000 // 4KB

    // Logging (Default values)
    static let defaultMaxSystemLogEntries = 500
    static let defaultMaxDeviceLogEntries = 1000
    static let minLogEntries = 100
    static let maxLogEntriesLimit = 10000

    // Repository
    static let repositoryURL = "https://github.com/steveshi0/nxboot"
    static let licenseURL = "https://github.com/steveshi0/nxboot#license"
    static let updatesURL = "https://github.com/steveshi0/nxboot"

    // Copyright
    static let originalCopyright = "© 2018-2024 Oliver Kuckertz"
    static let currentCopyright = "© 2026 SteveShi"
    static let fullCopyright = "\(originalCopyright), \(currentCopyright)"
}
