import Foundation
import SwiftUI
import Observation

@Observable
class NXPayload: Identifiable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var dateAdded: Date
    
    init(id: UUID = UUID(), name: String, path: URL, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
        self.dateAdded = dateAdded
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NXPayload, rhs: NXPayload) -> Bool {
        lhs.id == rhs.id
    }
    
    var sizeString: String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: fileSize)
        } catch {
            return "Unknown"
        }
    }
}

@Observable
class PayloadManager {
    var payloads: [NXPayload] = []
    private let fileManager = FileManager.default
    
    private var payloadsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "io.steveshi.nxboot.app"
        let payloadsDir = appSupport.appendingPathComponent("\(bundleID)/\(AppConstants.payloadsSubdirectory)", isDirectory: true)

        if !fileManager.fileExists(atPath: payloadsDir.path) {
            try? fileManager.createDirectory(at: payloadsDir, withIntermediateDirectories: true)
        }

        return payloadsDir
    }
    
    init() {
        loadPayloads()
    }
    
    func loadPayloads() {
        do {
            let files = try fileManager.contentsOfDirectory(at: payloadsDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            
            payloads = files.filter { $0.pathExtension == "bin" }.map { url in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let date = attributes?[.modificationDate] as? Date ?? Date()
                return NXPayload(name: url.deletingPathExtension().lastPathComponent, path: url, dateAdded: date)
            }
            .sorted(by: { $0.dateAdded > $1.dateAdded })
        } catch {
            print("Failed to load payloads: \(error)")
        }
    }
    
    func importPayload(from sourceURL: URL) {
        // Gain access to file if it's from a security-scoped URL (like a file picker)
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if shouldStopAccessing { sourceURL.stopAccessingSecurityScopedResource() } }
        
        let destinationURL = payloadsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            loadPayloads()
        } catch {
            print("Failed to import payload: \(error)")
        }
    }
    
    func deletePayload(_ payload: NXPayload) {
        do {
            try fileManager.removeItem(at: payload.path)
            loadPayloads()
        } catch {
            print("Failed to delete payload: \(error)")
        }
    }
}
