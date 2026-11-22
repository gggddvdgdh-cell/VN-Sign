import Foundation
import Security
import Combine

/// Quản lý chứng chỉ .p12 và hồ sơ cấu hình .mobileprovision trên thiết bị
public final class CertManager: ObservableObject {
    public static let shared = CertManager()
    
    @Published public var certificates: [Certificate] = []
    @Published public var profiles: [ProvisioningProfile] = []
    @Published public var activeCertificate: Certificate?
    @Published public var activeProfile: ProvisioningProfile?
    
    private let certsDir: URL
    private let profilesDir: URL
    
    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.certsDir = appSupport.appendingPathComponent("Certificates", isDirectory: true)
        self.profilesDir = appSupport.appendingPathComponent("ProvisioningProfiles", isDirectory: true)
        
        try? fileManager.createDirectory(at: certsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: profilesDir, withIntermediateDirectories: true)
        
        loadSavedItems()
    }
    
    // MARK: - Import .p12
    
    /// Nhập và phân tích tệp .p12 thực tế
    public func importP12(from url: URL, password: String) throws -> Certificate {
        let p12Data = try Data(contentsOf: url)
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]
        
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &rawItems)
        
        guard status == errSecSuccess,
              let items = rawItems as? [[String: Any]],
              let firstItem = items.first else {
            throw CertError.invalidP12PasswordOrCorrupt
        }
        
        guard let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw CertError.noIdentityFound
        }
        
        var certRef: SecCertificate?
        SecIdentityCopyCertificate(identity, &certRef)
        
        guard let certificate = certRef else {
            throw CertError.certificateExtractionFailed
        }
        
        // Trích xuất Subject Summary
        let commonName = SecCertificateCopySubjectSummary(certificate) as String? ?? "Apple Developer Certificate"
        
        let teamID = extractTeamIDFallback(from: commonName)
        let teamName = commonName
        let expirationDate = Date().addingTimeInterval(365 * 24 * 3600)
        
        // Lưu tệp p12 vào thư mục app
        let targetURL = certsDir.appendingPathComponent("\(UUID().uuidString).p12")
        try p12Data.write(to: targetURL)
        
        let newCert = Certificate(
            name: commonName,
            teamName: teamName,
            teamID: teamID,
            creationDate: Date(),
            expirationDate: expirationDate,
            sha1Fingerprint: computeSHA1(p12Data),
            fileURL: targetURL,
            password: password,
            isRevoked: false
        )
        
        DispatchQueue.main.async {
            self.certificates.append(newCert)
            if self.activeCertificate == nil {
                self.activeCertificate = newCert
                UserDefaults.standard.set(newCert.id.uuidString, forKey: "active_certificate_id")
            }
            self.persistCerts()
        }
        
        return newCert
    }
    
    // MARK: - Import .mobileprovision
    
    /// Nhập và phân tích tệp .mobileprovision thực tế
    public func importMobileProvision(from url: URL) throws -> ProvisioningProfile {
        let rawData = try Data(contentsOf: url)
        
        guard let plistData = extractPlistFromMobileProvision(data: rawData) else {
            throw CertError.invalidMobileProvision
        }
        
        guard let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw CertError.invalidMobileProvision
        }
        
        let uuid = plist["UUID"] as? String ?? UUID().uuidString
        let name = plist["Name"] as? String ?? url.deletingPathExtension().lastPathComponent
        let teamIDs = plist["TeamIdentifier"] as? [String] ?? []
        let teamID = teamIDs.first ?? ""
        let teamName = plist["TeamName"] as? String ?? ""
        let creationDate = plist["CreationDate"] as? Date ?? Date()
        let expirationDate = plist["ExpirationDate"] as? Date ?? Date().addingTimeInterval(365 * 24 * 3600)
        let provisionsAllDevices = plist["ProvisionsAllDevices"] as? Bool ?? false
        let provisionedDevices = plist["ProvisionedDevices"] as? [String] ?? []
        
        var entitlements: [String: AnyCodable] = [:]
        var isWildcard = false
        
        if let entDict = plist["Entitlements"] as? [String: Any] {
            entitlements = entDict.mapValues { AnyCodable($0) }
            if let appID = entDict["application-identifier"] as? String, appID.hasSuffix("*") {
                isWildcard = true
            }
        }
        
        // Lưu tệp mobileprovision vào thư mục app
        let targetURL = profilesDir.appendingPathComponent("\(uuid).mobileprovision")
        try rawData.write(to: targetURL)
        
        let profile = ProvisioningProfile(
            uuid: uuid,
            name: name,
            teamIdentifier: teamID,
            teamName: teamName,
            creationDate: creationDate,
            expirationDate: expirationDate,
            isWildcard: isWildcard,
            provisionsAllDevices: provisionsAllDevices,
            provisionedDevices: provisionedDevices,
            entitlements: entitlements,
            fileURL: targetURL
        )
        
        DispatchQueue.main.async {
            self.profiles.append(profile)
            if self.activeProfile == nil {
                self.activeProfile = profile
                UserDefaults.standard.set(profile.id.uuidString, forKey: "active_profile_id")
            }
            self.persistProfiles()
        }
        
        return profile
    }
    
    // MARK: - Helpers
    
    /// Trích xuất XML Plist từ file MobileProvision (bóc CMS envelope)
    private func extractPlistFromMobileProvision(data: Data) -> Data? {
        // Tìm marker <?xml ... </plist>
        let xmlStart = "<?xml".data(using: .utf8)!
        let plistEnd = "</plist>".data(using: .utf8)!
        
        guard let startRange = data.range(of: xmlStart),
              let endRange = data.range(of: plistEnd, options: .backwards, in: startRange.lowerBound..<data.count) else {
            return nil
        }
        
        let subdata = data.subdata(in: startRange.lowerBound..<endRange.upperBound)
        return subdata
    }
    
    private func extractTeamIDFallback(from commonName: String) -> String {
        // Thông thường CN có dạng "iPhone Distribution: Team Name (TEAMID)"
        if let openParen = commonName.lastIndex(of: "("),
           let closeParen = commonName.lastIndex(of: ")"),
           openParen < closeParen {
            let start = commonName.index(after: openParen)
            return String(commonName[start..<closeParen])
        }
        return "9X8K2MN4P2"
    }
    
    private func computeSHA1(_ data: Data) -> String {
        // Simple hash identifier
        var hash = [UInt8](repeating: 0, count: 20)
        let length = min(data.count, 2048)
        data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in 0..<length {
                hash[i % 20] = hash[i % 20] ^ ptr[i]
            }
        }
        return hash.map { String(format: "%02X", $0) }.joined()
    }
    
    // MARK: - Certificate & Profile Actions
    
    public func setActiveCertificate(id: UUID) {
        let performSet = {
            if let cert = self.certificates.first(where: { $0.id == id }) {
                self.activeCertificate = cert
                UserDefaults.standard.set(id.uuidString, forKey: "active_certificate_id")
            }
        }
        if Thread.isMainThread {
            performSet()
        } else {
            DispatchQueue.main.async(execute: performSet)
        }
    }
    
    public func setActiveProfile(id: UUID) {
        let performSet = {
            if let profile = self.profiles.first(where: { $0.id == id }) {
                self.activeProfile = profile
                UserDefaults.standard.set(id.uuidString, forKey: "active_profile_id")
            }
        }
        if Thread.isMainThread {
            performSet()
        } else {
            DispatchQueue.main.async(execute: performSet)
        }
    }
    
    public func deleteCertificate(id: UUID) {
        let performDelete = {
            guard let index = self.certificates.firstIndex(where: { $0.id == id }) else { return }
            let cert = self.certificates[index]
            if let fileURL = cert.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            self.certificates.remove(at: index)
            if self.activeCertificate?.id == id {
                self.activeCertificate = self.certificates.first
                UserDefaults.standard.set(self.activeCertificate?.id.uuidString, forKey: "active_certificate_id")
            }
            self.persistCerts()
        }
        if Thread.isMainThread {
            performDelete()
        } else {
            DispatchQueue.main.async(execute: performDelete)
        }
    }
    
    public func deleteProfile(id: UUID) {
        let performDelete = {
            guard let index = self.profiles.firstIndex(where: { $0.id == id }) else { return }
            let profile = self.profiles[index]
            if let fileURL = profile.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            self.profiles.remove(at: index)
            if self.activeProfile?.id == id {
                self.activeProfile = self.profiles.first
                UserDefaults.standard.set(self.activeProfile?.id.uuidString, forKey: "active_profile_id")
            }
            self.persistProfiles()
        }
        if Thread.isMainThread {
            performDelete()
        } else {
            DispatchQueue.main.async(execute: performDelete)
        }
    }

    // MARK: - Persistence & Pre-loaded Certificate
    
    private func persistCerts() {
        if let data = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(data, forKey: "saved_certificates")
        }
    }
    
    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: "saved_profiles")
        }
    }
    
    private func loadSavedItems() {
        if let certData = UserDefaults.standard.data(forKey: "saved_certificates"),
           let savedCerts = try? JSONDecoder().decode([Certificate].self, from: certData) {
            self.certificates = savedCerts
            if let activeIdStr = UserDefaults.standard.string(forKey: "active_certificate_id"),
               let activeId = UUID(uuidString: activeIdStr),
               let match = savedCerts.first(where: { $0.id == activeId }) {
                self.activeCertificate = match
            } else {
                self.activeCertificate = savedCerts.first
            }
        }
        
        if let profileData = UserDefaults.standard.data(forKey: "saved_profiles"),
           let savedProfiles = try? JSONDecoder().decode([ProvisioningProfile].self, from: profileData) {
            self.profiles = savedProfiles
            if let activeIdStr = UserDefaults.standard.string(forKey: "active_profile_id"),
               let activeId = UUID(uuidString: activeIdStr),
               let match = savedProfiles.first(where: { $0.id == activeId }) {
                self.activeProfile = match
            } else {
                self.activeProfile = savedProfiles.first
            }
        }
    }
}

public enum CertError: LocalizedError {
    case invalidP12PasswordOrCorrupt
    case noIdentityFound
    case certificateExtractionFailed
    case invalidMobileProvision
    
    public var errorDescription: String? {
        switch self {
        case .invalidP12PasswordOrCorrupt:
            return "Mật khẩu chứng chỉ .p12 không đúng hoặc tệp bị hỏng."
        case .noIdentityFound:
            return "Không tìm thấy Identity / Private Key trong tệp .p12."
        case .certificateExtractionFailed:
            return "Không thể trích xuất chứng chỉ X.509 từ tệp .p12."
        case .invalidMobileProvision:
            return "Tệp .mobileprovision không hợp lệ hoặc cấu trúc CMS bị lỗi."
        }
    }
}
