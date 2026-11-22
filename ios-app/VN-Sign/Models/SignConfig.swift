import Foundation

public enum CompressionLevel: String, CaseIterable, Codable {
    case fast = "fast"
    case balanced = "balanced"
    case ultra = "ultra"
    
    public var title: String {
        switch self {
        case .fast: return "Nhanh (Store)"
        case .balanced: return "Cân bằng"
        case .ultra: return "Tối đa (Ultra)"
        }
    }
}

/// Cấu hình cho một phiên ký IPA
public struct SignConfig {
    public var appItem: AppItem
    public var certificate: Certificate?
    public var provisioningProfile: ProvisioningProfile?
    
    // Tùy chọn nâng cao
    public var customAppName: String = ""
    public var customBundleIdentifier: String = ""
    public var injectDylibURL: URL? = nil
    public var removeDeviceLimits: Bool = true
    public var enableFileSharing: Bool = true
    public var compressionLevel: CompressionLevel = .balanced
    
    public init(
        appItem: AppItem,
        certificate: Certificate? = nil,
        provisioningProfile: ProvisioningProfile? = nil,
        customAppName: String = "",
        customBundleIdentifier: String = "",
        injectDylibURL: URL? = nil,
        removeDeviceLimits: Bool = true,
        enableFileSharing: Bool = true,
        compressionLevel: CompressionLevel = .balanced
    ) {
        self.appItem = appItem
        self.certificate = certificate
        self.provisioningProfile = provisioningProfile
        self.customAppName = customAppName
        self.customBundleIdentifier = customBundleIdentifier
        self.injectDylibURL = injectDylibURL
        self.removeDeviceLimits = removeDeviceLimits
        self.enableFileSharing = enableFileSharing
        self.compressionLevel = compressionLevel
    }
}
