import Foundation
import Combine
import UIKit

public struct SigningProgress {
    public enum Stage: Int {
        case extracting = 1
        case injecting = 2
        case codesigning = 3
        case repackaging = 4
        case completed = 5
        
        public var title: String {
            switch self {
            case .extracting:
                return NSLocalizedString("step_extract", comment: "")
            case .injecting:
                return NSLocalizedString("step_inject", comment: "")
            case .codesigning:
                return NSLocalizedString("step_codesign", comment: "")
            case .repackaging:
                return NSLocalizedString("step_package", comment: "")
            case .completed:
                return NSLocalizedString("step_completed", comment: "")
            }
        }
    }
    
    public var stage: Stage
    public var progress: Double // 0.0 -> 1.0
    public var message: String
}

/// Động cơ ký số IPA trực tiếp trên thiết bị (On-Device Signing Engine)
public final class SigningEngine: ObservableObject {
    public static let shared = SigningEngine()
    
    @Published public var isSigning: Bool = false
    @Published public var currentProgress: SigningProgress?
    @Published public var signedApps: [AppItem] = []
    @Published public var libraryApps: [AppItem] = []
    
    private let signedAppsDir: URL
    private let workDir: URL
    
    private init() {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.signedAppsDir = documents.appendingPathComponent("SignedApps", isDirectory: true)
        self.workDir = fileManager.temporaryDirectory.appendingPathComponent("VN-Sign-Work", isDirectory: true)
        
        try? fileManager.createDirectory(at: signedAppsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)
        
        loadSavedSignedApps()
        populateSampleLibraryAppsIfNeeded()
    }
    
    // MARK: - Core Signing Execution
    
    /// Thực thi quy trình ký ứng dụng 4 bước hoàn chỉnh
    @MainActor
    public func sign(config: SignConfig) async throws -> AppItem {
        isSigning = true
        defer { isSigning = false }
        
        guard let certificate = config.certificate ?? CertManager.shared.activeCertificate else {
            throw CertError.noIdentityFound
        }
        guard let profile = config.provisioningProfile ?? CertManager.shared.activeProfile else {
            throw CertError.invalidMobileProvision
        }
        
        let sessionID = UUID().uuidString
        let tempSessionDir = workDir.appendingPathComponent(sessionID, isDirectory: true)
        try FileManager.default.createDirectory(at: tempSessionDir, withIntermediateDirectories: true)
        
        // ------------------------------------------------------------------
        // GIAI ĐOẠN 1: GIẢI NÉN GÓI IPA (0% -> 25%)
        // ------------------------------------------------------------------
        currentProgress = SigningProgress(stage: .extracting, progress: 0.10, message: SigningProgress.Stage.extracting.title)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let ipaSourceURL = URL(fileURLWithPath: config.appItem.originalIpaPath)
        let appBundleURL = try ZipArchiveManager.extractIPA(from: ipaSourceURL, to: tempSessionDir)
        
        currentProgress = SigningProgress(stage: .extracting, progress: 0.25, message: "Giải nén hoàn tất...")
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // ------------------------------------------------------------------
        // GIAI ĐOẠN 2: TIÊM DYLIB & TÙY BIẾN PLIST (25% -> 50%)
        // ------------------------------------------------------------------
        currentProgress = SigningProgress(stage: .injecting, progress: 0.35, message: SigningProgress.Stage.injecting.title)
        
        // Cập nhật Info.plist
        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        if var plistDict = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] {
            if !config.customAppName.isEmpty {
                plistDict["CFBundleDisplayName"] = config.customAppName
                plistDict["CFBundleName"] = config.customAppName
            }
            if !config.customBundleIdentifier.isEmpty {
                plistDict["CFBundleIdentifier"] = config.customBundleIdentifier
            }
            if config.enableFileSharing {
                plistDict["UIFileSharingEnabled"] = true
                plistDict["LSSupportsOpeningDocumentsInPlace"] = true
            }
            if config.removeDeviceLimits {
                plistDict.removeValue(forKey: "UIRequiredDeviceCapabilities")
            }
            
            let plistData = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
            try plistData.write(to: infoPlistURL)
        }
        
        // Nhúng embedded.mobileprovision
        if let profileURL = profile.fileURL,
           let profileData = try? Data(contentsOf: profileURL) {
            let embeddedURL = appBundleURL.appendingPathComponent("embedded.mobileprovision")
            try? profileData.write(to: embeddedURL)
        }
        
        // Tiêm Dylib / Tweak nếu có
        if let dylibURL = config.injectDylibURL {
            let frameworksDir = appBundleURL.appendingPathComponent("Frameworks", isDirectory: true)
            try? FileManager.default.createDirectory(at: frameworksDir, withIntermediateDirectories: true)
            
            let targetDylibURL = frameworksDir.appendingPathComponent(dylibURL.lastPathComponent)
            try? FileManager.default.copyItem(at: dylibURL, to: targetDylibURL)
            
            // Tìm executable chính để chèn load command
            let execName = (NSDictionary(contentsOf: infoPlistURL)?["CFBundleExecutable"] as? String) ?? appBundleURL.deletingPathExtension().lastPathComponent
            let mainBinaryURL = appBundleURL.appendingPathComponent(execName)
            
            try? DylibInjector.injectDylib(binaryURL: mainBinaryURL, dylibName: dylibURL.lastPathComponent)
        }
        
        currentProgress = SigningProgress(stage: .injecting, progress: 0.50, message: "Tiêm Tweak & Plist thành công...")
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // ------------------------------------------------------------------
        // GIAI ĐOẠN 3: KÝ MÃ MACH-O & NIÊM PHONG ENTITLEMENTS (50% -> 85%)
        // ------------------------------------------------------------------
        currentProgress = SigningProgress(stage: .codesigning, progress: 0.60, message: SigningProgress.Stage.codesigning.title)
        
        // 1. Tạo file _CodeSignature/CodeResources
        try CodeSigner.generateCodeResources(appBundleURL: appBundleURL)
        
        // 2. Ký các Frameworks con & Dylibs
        let frameworksPath = appBundleURL.appendingPathComponent("Frameworks")
        if let frameworks = try? FileManager.default.contentsOfDirectory(at: frameworksPath, includingPropertiesForKeys: nil) {
            for fw in frameworks {
                let fwBinary = fw.appendingPathComponent(fw.deletingPathExtension().lastPathComponent)
                if FileManager.default.fileExists(atPath: fwBinary.path) {
                    try? CodeSigner.signMachO(
                        binaryURL: fwBinary,
                        bundleID: config.customBundleIdentifier.isEmpty ? config.appItem.bundleIdentifier : config.customBundleIdentifier,
                        teamID: certificate.teamID,
                        entitlementsData: Data(),
                        certificate: certificate
                    )
                }
            }
        }
        
        // 3. Ký Mach-O chính
        let execName = (NSDictionary(contentsOf: infoPlistURL)?["CFBundleExecutable"] as? String) ?? appBundleURL.deletingPathExtension().lastPathComponent
        let mainBinaryURL = appBundleURL.appendingPathComponent(execName)
        
        let bundleID = config.customBundleIdentifier.isEmpty ? config.appItem.bundleIdentifier : config.customBundleIdentifier
        let entitlementsDict = profile.entitlements.mapValues { $0.value }
        let entData = (try? PropertyListSerialization.data(fromPropertyList: entitlementsDict, format: .xml, options: 0)) ?? Data()
        
        if FileManager.default.fileExists(atPath: mainBinaryURL.path) {
            try CodeSigner.signMachO(
                binaryURL: mainBinaryURL,
                bundleID: bundleID,
                teamID: certificate.teamID,
                entitlementsData: entData,
                certificate: certificate
            )
        }
        
        currentProgress = SigningProgress(stage: .codesigning, progress: 0.85, message: "Ký nhị phân hoàn tất...")
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // ------------------------------------------------------------------
        // GIAI ĐOẠN 4: NÉN VÀ ĐÓNG GÓI IPA (85% -> 100%)
        // ------------------------------------------------------------------
        currentProgress = SigningProgress(stage: .repackaging, progress: 0.90, message: SigningProgress.Stage.repackaging.title)
        
        let safeAppName = (config.customAppName.isEmpty ? config.appItem.name : config.customAppName)
            .replacingOccurrences(of: " ", with: "_")
        let signedIpaFileName = "\(safeAppName)_signed_\(Int(Date().timeIntervalSince1970)).ipa"
        let outputSignedIPAURL = signedAppsDir.appendingPathComponent(signedIpaFileName)
        
        try ZipArchiveManager.repackageIPA(
            sourceDir: tempSessionDir,
            outputIPAURL: outputSignedIPAURL,
            compressionLevel: config.compressionLevel
        )
        
        // Dọn dẹp thư mục làm việc tạm
        try? FileManager.default.removeItem(at: tempSessionDir)
        
        currentProgress = SigningProgress(stage: .completed, progress: 1.0, message: SigningProgress.Stage.completed.title)
        
        // Tạo AppItem mới cho danh sách đã ký
        let signedItem = AppItem(
            name: config.customAppName.isEmpty ? config.appItem.name : config.customAppName,
            bundleIdentifier: bundleID,
            version: config.appItem.version,
            buildNumber: config.appItem.buildNumber,
            fileSize: (try? FileManager.default.attributesOfItem(atPath: outputSignedIPAURL.path)[.size] as? Int64) ?? config.appItem.fileSize,
            filePath: outputSignedIPAURL.path,
            iconPath: config.appItem.iconPath,
            originalIpaPath: config.appItem.originalIpaPath,
            signedIpaPath: outputSignedIPAURL.path,
            isSigned: true,
            dateAdded: Date(),
            signedDate: Date(),
            teamName: certificate.displayTeam
        )
        
        signedApps.insert(signedItem, at: 0)
        persistSignedApps()
        
        return signedItem
    }
    
    // MARK: - Library & Sample Setup
    
    private func persistSignedApps() {
        if let data = try? JSONEncoder().encode(signedApps) {
            UserDefaults.standard.set(data, forKey: "saved_signed_apps")
        }
    }
    
    private func loadSavedSignedApps() {
        if let data = UserDefaults.standard.data(forKey: "saved_signed_apps"),
           let items = try? JSONDecoder().decode([AppItem].self, from: data) {
            self.signedApps = items
        }
    }
    
    private func populateSampleLibraryAppsIfNeeded() {
        if libraryApps.isEmpty {
            self.libraryApps = [
                AppItem(
                    name: "Facebook Pro VIP",
                    bundleIdentifier: "com.facebook.FacebookPro",
                    version: "492.0.1",
                    buildNumber: "128",
                    fileSize: 182_452_224, // 174 MB
                    filePath: "d:\\VN-Sign\\FacebookPro.ipa",
                    iconPath: nil,
                    originalIpaPath: "d:\\VN-Sign\\FacebookPro.ipa",
                    isSigned: false
                ),
                AppItem(
                    name: "TikTok Mod No Watermark",
                    bundleIdentifier: "com.zhiliaoapp.musically.mod",
                    version: "36.8.0",
                    buildNumber: "450",
                    fileSize: 248_512_512, // 237 MB
                    filePath: "d:\\VN-Sign\\TikTokMod.ipa",
                    iconPath: nil,
                    originalIpaPath: "d:\\VN-Sign\\TikTokMod.ipa",
                    isSigned: false
                ),
                AppItem(
                    name: "YouTube Plus Premium",
                    bundleIdentifier: "com.google.ios.youtube.plus",
                    version: "19.45.2",
                    buildNumber: "89",
                    fileSize: 154_140_672, // 147 MB
                    filePath: "d:\\VN-Sign\\YouTubePlus.ipa",
                    iconPath: nil,
                    originalIpaPath: "d:\\VN-Sign\\YouTubePlus.ipa",
                    isSigned: false
                ),
                AppItem(
                    name: "CapCut Pro VIP All Features",
                    bundleIdentifier: "com.lemon.lvoverseas.vip",
                    version: "14.1.0",
                    buildNumber: "302",
                    fileSize: 220_200_960, // 210 MB
                    filePath: "d:\\VN-Sign\\CapCutPro.ipa",
                    iconPath: nil,
                    originalIpaPath: "d:\\VN-Sign\\CapCutPro.ipa",
                    isSigned: false
                )
            ]
        }
    }
}
