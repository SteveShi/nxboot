import Foundation
import SwiftUI
import Observation
import IOKit

@Observable
@MainActor
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
            self.statusMessage = String(localized: "Error: No device connected")
            Logger.shared.addLog(String(localized: "Injection failed: No device connected"), type: .system)
            return
        }
        
        self.statusMessage = String(localized: "Injecting payload...")
        Logger.shared.addLog(String(localized: "Starting injection..."), type: .system)
        
        var errorString: NSString?
        
        // Use the high-level NXExec function that handles interface acquisition automatically
        if NXExec(device, relocatorData, payloadData, &errorString) {
            self.statusMessage = String(localized: "Success: Payload injected!")
            Logger.shared.addLog(String(localized: "Payload injected successfully!"), type: .system)
            
            // Start reading serial output if possible
            startSerialReading(device: device)
        } else {
            let err = errorString as String? ?? String(localized: "Unknown error")
            self.statusMessage = String(localized: "Error: Injection failed: \(err)")
            Logger.shared.addLog(String(localized: "Injection failed: \(err)"), type: .system)
        }
    }
    
    private func startSerialReading(device: NXUSBDevice) {
        readTask?.cancel()
        let timeoutMS = self.usbReadTimeoutMS
        let deviceInterface = device.deviceInterface
        let wrappedInterface = SendableWrapper(value: deviceInterface)
        readTask = Task.detached(priority: .background) {
            await Logger.shared.addLog(String(localized: "Attempting to read from USB EP1..."), type: .system)
            
            var err: NSString?
            var desc = NXExecAcquireDeviceInterface(wrappedInterface.value, &err)
            guard desc.intf != nil else {
                let errStr = err as String? ?? String(localized: "unknown")
                await Logger.shared.addLog(String(localized: "Could not acquire device interface for reading: \(errStr)"), type: .system)
                return
            }
            
            defer { NXExecReleaseDeviceInterface(&desc) }
            
            let bufferSize = AppConstants.usbBufferSize
            let rdbuf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { rdbuf.deallocate() }

            while !Task.isCancelled {
                var btransf: UInt32 = UInt32(bufferSize)
                let kr = NXReadPipeTO(desc.intf, desc.readRef, rdbuf, &btransf, timeoutMS)
                
                if kr == Int32(bitPattern: 0xE0004051) { // bulk read error, expected when device disconnects
                    await Logger.shared.addLog(String(localized: "USB EP1 stream terminated"), type: .system)
                    break
                }
                
                if kr == 0 {
                    if btransf > 0 {
                        let data = Data(bytes: rdbuf, count: Int(btransf))
                        if let string = String(data: data, encoding: .utf8) {
                            await Logger.shared.addLog(string.trimmingCharacters(in: .newlines), type: .device)
                        } else {
                            await Logger.shared.addLog(String(localized: "Received \(Int(btransf)) bytes of binary data"), type: .device)
                        }
                    }
                } else if kr != Int32(bitPattern: 0xE000404F) { // Ignore timeout errors (expected if no data)
                    let errHex = String(format: "0x%08x", kr)
                    await Logger.shared.addLog(String(localized: "Read error: \(errHex)"), type: .system)
                    break
                }

                try? await Task.sleep(nanoseconds: AppConstants.usbReadSleepNS)
            }
        }
    }
    
    // MARK: - NXUSBDeviceEnumeratorDelegate
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceConnected device: NXUSBDevice) {
        self.isConnected = true
        self.connectedDevice = device
        self.statusMessage = String(localized: "Nintendo Switch Connected (RCM)")
        Logger.shared.addLog(String(localized: "Device connected: Nintendo Switch (RCM)"), type: .system)
        
        if self.isAutoBootEnabled {
            if let (payload, relocator) = onAutoInject?(), let p = payload, let r = relocator {
                Logger.shared.addLog(String(localized: "Auto-boot enabled, injecting default payload..."), type: .system)
                self.inject(payloadData: p, relocatorData: r)
            } else {
                Logger.shared.addLog(String(localized: "Auto-boot enabled, but no default payload or relocator found."), type: .system)
            }
        }
    }
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceDisconnected device: NXUSBDevice) {
        self.isConnected = false
        self.connectedDevice = nil
        self.statusMessage = String(localized: "No Device Connected")
        Logger.shared.addLog(String(localized: "Device disconnected"), type: .system)
        readTask?.cancel()
        readTask = nil
    }
    
    func usbDeviceEnumerator(_ deviceEnum: NXUSBDeviceEnumerator, deviceError err: String) {
        self.lastError = err
        self.statusMessage = String(localized: "Error: \(err)")
        Logger.shared.addLog(String(localized: "USB Error: \(err)"), type: .system)
    }
}

struct SendableWrapper<T>: @unchecked Sendable {
    let value: T
}
