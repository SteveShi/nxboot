import Foundation
import Observation

@Observable
@MainActor
class HekateManager {
    static let shared = HekateManager()
    
    enum BootTarget: Int, CaseIterable, Identifiable {
        case menu = 0
        case id = 1
        case index = 2
        case ums = 3
        
        var id: Int { self.rawValue }
        var localizedName: String {
            switch self {
            case .menu: return String(localized: "Menu")
            case .id: return String(localized: "Entry ID")
            case .index: return String(localized: "Entry Index")
            case .ums: return String(localized: "USB Mass Storage (UMS)")
            }
        }
    }
    
    enum UMSTarget: Int, CaseIterable, Identifiable {
        case sd = 0
        case boot0 = 1
        case boot1 = 2
        case gpp = 3
        case emuBoot0 = 4
        case emuBoot1 = 5
        case emuGpp = 6
        
        var id: Int { self.rawValue }
        var localizedName: String {
            switch self {
            case .sd: return String(localized: "SD Card")
            case .boot0: return String(localized: "eMMC BOOT0")
            case .boot1: return String(localized: "eMMC BOOT1")
            case .gpp: return String(localized: "eMMC GPP")
            case .emuBoot0: return String(localized: "emuMMC BOOT0")
            case .emuBoot1: return String(localized: "emuMMC BOOT1")
            case .emuGpp: return String(localized: "emuMMC GPP")
            }
        }
    }
    
    var bootTarget: BootTarget = .menu
    var bootID: String = ""
    var bootIndex: Int = 1
    var umsTarget: UMSTarget = .sd
    var showLaunchLog: Bool = false
    
    private init() {
        // Load defaults from UserDefaults if needed
    }
    
    func customize(payloadData: Data) -> Data {
        let customizer = NXHekateCustomizer(payload: payloadData)
        if customizer.isPayloadSupported {
            customizer.bootTarget = NXHekateBootTarget(rawValue: bootTarget.rawValue) ?? .menu
            customizer.bootID = bootID
            customizer.bootIndex = bootIndex
            customizer.umsTarget = NXHekateStorageTarget(rawValue: umsTarget.rawValue) ?? .SD
            customizer.logFlag = showLaunchLog
            return customizer.commitToImage()
        }
        return payloadData
    }
    
    func isHekate(_ payloadData: Data) -> Bool {
        let customizer = NXHekateCustomizer(payload: payloadData)
        return customizer.isPayloadSupported
    }
}
