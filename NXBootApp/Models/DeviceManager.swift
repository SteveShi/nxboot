import Foundation
import SwiftUI
import Observation
import IOKit

@Observable
class DeviceManager: NSObject, NXUSBDeviceEnumeratorDelegate {
    var isConnected: Bool = false
    var connectedDevice: NXUSBDevice?
    var statusMessage: String = "No Device Connected"
    var lastError: String?
    var isAutoBootEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAutoBootEnabled, forKey: "isAutoBootEnabled")
        }
    }

    var usbReadTimeoutMS: UInt32 {
        let timeout = UserDefaults.standard.object(forKey: "usbReadTimeoutMS") as? UInt32 ?? AppConstants.defaultUSBReadTimeoutMS
        return max(AppConstants.minUSBReadTimeoutMS, min(timeout, AppConstants.maxUSBReadTimeoutMS))
    }

    private let usbEnum = NXUSBDeviceEnumerator()
    private var readTask: Task<Void, Never>?
    
    // Callback for auto-injection
    var onAutoInject: (() -> (Data?, Data?))?
    
    override init() {
        super.init()
        self.isAutoBootEnabled = UserDefaults.standard.bool(forKey: "isAutoBootEnabled")
        usbEnum.delegate = self
        // Filter for Tegra X1 RCM (NVIDIA Corp. Recovery Mode)
        usbEnum.setFilterForVendorID(AppConstants.tegraX1VendorID, productID: AppConstants.tegraX1ProductID)
    }
    
    func startMonitoring() {
        usbEnum.start()
    }
    
    func stopMonitoring() {
        usbEnum.stop()
    }
    
    func inject(payloadData: Data, relocatorData: Data) {
        guard let device = connectedDevice else {
            self.statusMessage = "Error: No device connected"
            Logger.shared.addLog("Injection failed: No device connected", type: .system)
            return
        }
        
        self.statusMessage = "Injecting payload..."
        Logger.shared.addLog("Starting injection...", type: .system)
        
        var errorString: NSString?
        
        // Use the high-level NXExec function that handles interface acquisition automatically
        if NXExec(device, relocatorData, payloadData, &errorString) {
            self.statusMessage = "Success: Payload injected!"
            Logger.shared.addLog("Payload injected successfully!", type: .system)
            
            // Start reading serial output if possible
            startSerialReading(device: device)
        } else {
            let err = errorString as String? ?? "Unknown error"
            self.statusMessage = "Error: Injection failed: \(err)"
            Logger.shared.addLog("Injection failed: \(err)", type: .system)
        }
    }
    
    private func startSerialReading(device: NXUSBDevice) {
        readTask?.cancel()
        readTask = Task.detached(priority: .background) {
            Logger.shared.addLog("Attempting to read from USB EP1...", type: .system)
            
            var err: NSString?
            var desc = NXExecAcquireDeviceInterface(device.deviceInterface, &err)
            guard desc.intf != nil else {
                Logger.shared.addLog("Could not acquire device interface for reading: \(err ?? "unknown")", type: .system)
                return
            }
            
            defer { NXExecReleaseDeviceInterface(&desc) }
            
            let bufferSize = AppConstants.usbBufferSize
            let rdbuf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { rdbuf.deallocate() }

            while !Task.isCancelled {
                var btransf: UInt32 = UInt32(bufferSize)
                let kr = NXReadPipeTO(desc.intf, desc.readRef, rdbuf, &btransf, self.usbReadTimeoutMS)
                
                if kr == Int32(bitPattern: 0xE0004051) { // bulk read error, expected when device disconnects
                    Logger.shared.addLog("USB EP1 stream terminated", type: .system)
                    break
                }
                
                if kr == 0 {
                    if btransf > 0 {
                        let data = Data(bytes: rdbuf, count: Int(btransf))
                        if let string = String(data: data, encoding: .utf8) {
                            Logger.shared.addLog(string.trimmingCharacters(in: .newlines), type: .device)
                        } else {
                            Logger.shared.addLog("Received \(btransf) bytes of binary data", type: .device)
                        }
                    }
                } else if kr != Int32(bitPattern: 0xE000404F) { // Ignore timeout errors (expected if no data)
                    Logger.shared.addLog("Read error: \(String(format: "0x%08x", kr))", type: .system)
                    break
                }

                try? await Task.sleep(nanoseconds: AppConstants.usbReadSleepNS)
            }
        }
    }
    
    // MARK: - NXUSBDeviceEnumeratorDelegate
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceConnected device: NXUSBDevice) {
        Task { @MainActor in
            self.isConnected = true
            self.connectedDevice = device
            self.statusMessage = "Nintendo Switch Connected (RCM)"
            Logger.shared.addLog("Device connected: Nintendo Switch (RCM)", type: .system)
            
            if self.isAutoBootEnabled {
                if let (payload, relocator) = onAutoInject?(), let p = payload, let r = relocator {
                    Logger.shared.addLog("Auto-boot enabled, injecting default payload...", type: .system)
                    self.inject(payloadData: p, relocatorData: r)
                } else {
                    Logger.shared.addLog("Auto-boot enabled, but no default payload or relocator found.", type: .system)
                }
            }
        }
    }
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceDisconnected device: NXUSBDevice) {
        Task { @MainActor in
            self.isConnected = false
            self.connectedDevice = nil
            self.statusMessage = "No Device Connected"
            Logger.shared.addLog("Device disconnected", type: .system)
            readTask?.cancel()
            readTask = nil
        }
    }
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceError err: String) {
        Task { @MainActor in
            self.lastError = err
            self.statusMessage = "Error: \(err)"
            Logger.shared.addLog("USB Error: \(err)", type: .system)
        }
    }
}
