import UIKit

/// Cung cấp thông tin phần cứng và hệ điều hành của thiết bị
public final class DeviceInfo {
    public static let shared = DeviceInfo()
    
    public let modelName: String
    public let systemVersion: String
    public let deviceUDID: String
    
    private init() {
        self.systemVersion = UIDevice.current.systemVersion
        self.modelName = DeviceInfo.resolveDeviceModelName()
        self.deviceUDID = UIDevice.current.identifierForVendor?.uuidString ?? "00008101-001248920192001E"
    }
    
    private static func resolveDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "x86_64", "arm64":
            #if targetEnvironment(simulator)
            return "iPhone 16 Pro (Simulator)"
            #else
            return "iPhone 16 Pro"
            #endif
        default:
            return identifier.isEmpty ? "iPhone" : identifier
        }
    }
}
