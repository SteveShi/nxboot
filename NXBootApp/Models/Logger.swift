import Foundation
import Observation

@Observable
@MainActor
class Logger {
    static let shared = Logger()
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let message: String
        let type: LogType
    }
    
    enum LogType {
        case system
        case device
    }
    
    var systemLogs: [LogEntry] = []
    var deviceLogs: [LogEntry] = []

    var maxSystemLogEntries: Int {
        UserDefaults.standard.object(forKey: "maxSystemLogEntries") as? Int ?? AppConstants.defaultMaxSystemLogEntries
    }

    var maxDeviceLogEntries: Int {
        UserDefaults.standard.object(forKey: "maxDeviceLogEntries") as? Int ?? AppConstants.defaultMaxDeviceLogEntries
    }

    private init() {
        // Handle logs from Objective-C
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NXLogNotification"), object: nil, queue: .main) { notification in
            if let message = notification.userInfo?["message"] as? String {
                Task { @MainActor in
                    self.addLog(message, type: .system)
                }
            }
        }
    }
    
    func addLog(_ message: String, type: LogType) {
        let entry = LogEntry(message: message, type: type)
        switch type {
        case .system:
            systemLogs.append(entry)
            if systemLogs.count > maxSystemLogEntries { systemLogs.removeFirst() }
        case .device:
            deviceLogs.append(entry)
            if deviceLogs.count > maxDeviceLogEntries { deviceLogs.removeFirst() }
        }
    }
    
    func clear(type: LogType) {
        switch type {
        case .system: systemLogs.removeAll()
        case .device: deviceLogs.removeAll()
        }
    }
}
