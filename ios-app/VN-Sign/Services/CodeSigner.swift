import Foundation
import Security
import CommonCrypto

/// Bộ tạo chữ ký số Mach-O, niêm phong CodeDirectory và đóng gói CodeResources
public final class CodeSigner {
    
    public enum SignerError: LocalizedError {
        case appBundleNotFound
        case mainExecutableNotFound
        case privateKeyNotFound
        case hashingFailed
        case signatureBlobGenerationFailed
        
        public var errorDescription: String? {
            switch self {
            case .appBundleNotFound:
                return "Không tìm thấy thư mục .app trong gói Payload."
            case .mainExecutableNotFound:
                return "Không tìm thấy tệp thực thi Mach-O chính của ứng dụng."
            case .privateKeyNotFound:
                return "Không có khoá ký (Private Key) hợp lệ để tạo chữ ký."
            case .hashingFailed:
                return "Lỗi tính toán mã băm SHA-256 cho tài nguyên."
            case .signatureBlobGenerationFailed:
                return "Lỗi cấu trúc SuperBlob chữ ký Mach-O."
            }
        }
    }
    
    // MARK: - Constants
    public static let CSMAGIC_EMBEDDED_SIGNATURE: UInt32 = 0xfade0cc0
    public static let CSMAGIC_CODEDIRECTORY: UInt32 = 0xfade0c02
    public static let CSMAGIC_REQUIREMENTS: UInt32 = 0xfade0c01
    public static let CSMAGIC_EMBEDDED_ENTITLEMENTS: UInt32 = 0xfade7171
    public static let CSMAGIC_BLOBWRAPPER: UInt32 = 0xfade0b01
    
    public static let CSSLOT_CODEDIRECTORY: UInt32 = 0
    public static let CSSLOT_REQUIREMENTS: UInt32 = 2
    public static let CSSLOT_ENTITLEMENTS: UInt32 = 5
    public static let CSSLOT_SIGNATURE: UInt32 = 0x10000
    
    public static let CS_PAGE_SIZE: Int = 4096
    
    // MARK: - CodeResources Generator
    
    /// Tạo cấu trúc _CodeSignature/CodeResources theo chuẩn Apple
    public static func generateCodeResources(appBundleURL: URL) throws {
        let codeSignatureDir = appBundleURL.appendingPathComponent("_CodeSignature", isDirectory: true)
        try FileManager.default.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)
        
        var filesDict: [String: Any] = [:]
        var files2Dict: [String: Any] = [:]
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: appBundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            // Bỏ qua thư mục _CodeSignature chính nó
            if fileURL.path.contains("_CodeSignature") { continue }
            
            var isRegular: AnyObject?
            try? (fileURL as NSURL).getResourceValue(&isRegular, forKey: .isRegularFileKey)
            guard (isRegular as? Bool) == true else { continue }
            
            // Đường dẫn tương đối so với .app
            let relativePath = fileURL.path.replacingOccurrences(of: appBundleURL.path + "/", with: "")
            if let fileData = try? Data(contentsOf: fileURL) {
                let sha1 = computeSHA1Data(fileData)
                let sha256 = computeSHA256Data(fileData)
                
                filesDict[relativePath] = sha1
                files2Dict[relativePath] = [
                    "hash": sha1,
                    "hash2": sha256
                ]
            }
        }
        
        let rules: [String: Any] = [
            "^.*": true,
            "^.*\\.lproj/": ["weight": 100],
            "^version\\.plist$": true
        ]
        
        let codeResourcesPlist: [String: Any] = [
            "files": filesDict,
            "files2": files2Dict,
            "rules": rules,
            "rules2": rules
        ]
        
        let plistData = try PropertyListSerialization.data(fromPropertyList: codeResourcesPlist, format: .xml, options: 0)
        let targetURL = codeSignatureDir.appendingPathComponent("CodeResources")
        try plistData.write(to: targetURL)
    }
    
    // MARK: - Sign Mach-O Executable
    
    /// Ký tệp thực thi Mach-O và ghi đè LC_CODE_SIGNATURE
    public static func signMachO(
        binaryURL: URL,
        bundleID: String,
        teamID: String,
        entitlementsData: Data,
        certificate: Certificate
    ) throws {
        let fileHandle = try FileHandle(forUpdating: binaryURL)
        defer { try? fileHandle.close() }
        
        let binarySize = try fileHandle.seekToEnd()
        let info = try MachOParser.parse(fileURL: binaryURL)
        
        // Xác định điểm bắt đầu của chữ ký mới (căn chỉnh 16 bytes)
        let sigStartOffset = info.codeSignatureOffset != nil ? UInt64(info.codeSignatureOffset!) : ((binarySize + 15) & ~15)
        
        // Tính toán các băm CodeDirectory cho các trang 4096 bytes
        try fileHandle.seek(toOffset: 0)
        var codeSlots: [Data] = []
        var bytesHashed: UInt64 = 0
        
        while bytesHashed < sigStartOffset {
            let chunkSize = min(Int(sigStartOffset - bytesHashed), CS_PAGE_SIZE)
            guard let pageData = try fileHandle.read(upToCount: chunkSize) else { break }
            let hash = computeSHA256(pageData)
            codeSlots.append(hash)
            bytesHashed += UInt64(chunkSize)
        }
        
        // Xây dựng CodeDirectory Blob
        let cdData = buildCodeDirectoryBlob(
            bundleID: bundleID,
            teamID: teamID,
            codeLimit: UInt32(sigStartOffset),
            codeSlots: codeSlots
        )
        
        // Xây dựng Entitlements Blob
        let entBlob = buildEntitlementsBlob(entitlementsData: entitlementsData)
        
        // Xây dựng CMS Signature Blob Wrapper
        let cmsBlob = buildCMSBlob(codeDirectoryData: cdData, certificate: certificate)
        
        // Gói SuperBlob chứa: CodeDirectory, Entitlements, CMS Signature
        let superBlobData = buildSuperBlob(
            codeDirectoryBlob: cdData,
            entitlementsBlob: entBlob,
            cmsSignatureBlob: cmsBlob
        )
        
        // Ghi SuperBlob vào tệp nhị phân
        try fileHandle.seek(toOffset: sigStartOffset)
        try fileHandle.write(contentsOf: superBlobData)
        
        // Cập nhật load command LC_CODE_SIGNATURE trong Mach-O header
        try updateCodeSignatureLoadCommand(
            fileHandle: fileHandle,
            info: info,
            offset: UInt32(sigStartOffset),
            size: UInt32(superBlobData.count)
        )
    }
    
    // MARK: - Blob Builders
    
    private static func buildCodeDirectoryBlob(
        bundleID: String,
        teamID: String,
        codeLimit: UInt32,
        codeSlots: [Data]
    ) -> Data {
        var data = Data()
        let magic = CFSwapInt32HostToBig(CSMAGIC_CODEDIRECTORY)
        let version = CFSwapInt32HostToBig(0x20400) // CS_SUPPORTSSCATTER | CS_SUPPORTSTEAMID
        let flags: UInt32 = 0
        let hashOffset: UInt32 = 88 // Offset từ đầu CodeDirectory tới special slots
        let identOffset: UInt32 = 88 + UInt32(codeSlots.count * 32)
        let teamOffset: UInt32 = identOffset + UInt32(bundleID.utf8.count + 1)
        let totalLength: UInt32 = teamOffset + UInt32(teamID.utf8.count + 1)
        
        var header = Data()
        header.append(Data(bytes: [magic], count: 4))
        header.append(Data(bytes: [CFSwapInt32HostToBig(totalLength)], count: 4))
        header.append(Data(bytes: [version], count: 4))
        header.append(Data(bytes: [flags], count: 4))
        header.append(Data(bytes: [CFSwapInt32HostToBig(hashOffset)], count: 4))
        header.append(Data(bytes: [CFSwapInt32HostToBig(identOffset)], count: 4))
        header.append(Data(bytes: [0, 0, 0, 0], count: 4)) // nSpecialSlots
        header.append(Data(bytes: [CFSwapInt32HostToBig(UInt32(codeSlots.count))], count: 4)) // nCodeSlots
        header.append(Data(bytes: [CFSwapInt32HostToBig(codeLimit)], count: 4))
        header.append(32) // hashSize (SHA-256 = 32 bytes)
        header.append(2)  // hashType (CS_HASHTYPE_SHA256 = 2)
        header.append(0)  // platform
        header.append(12) // pageSize (2^12 = 4096)
        header.append(Data(repeating: 0, count: 4)) // spare2
        header.append(Data(repeating: 0, count: 8)) // scatterOffset
        header.append(Data(bytes: [CFSwapInt32HostToBig(teamOffset)], count: 4))
        header.append(Data(repeating: 0, count: 28)) // padding to 88 bytes
        
        data.append(header)
        
        // Ghi các slot hash
        for slot in codeSlots {
            data.append(slot)
        }
        
        // Ghi identifier (bundle ID) null-terminated
        data.append(bundleID.data(using: .utf8)!)
        data.append(0)
        
        // Ghi team ID null-terminated
        data.append(teamID.data(using: .utf8)!)
        data.append(0)
        
        return data
    }
    
    private static func buildEntitlementsBlob(entitlementsData: Data) -> Data {
        var data = Data()
        let magic = CFSwapInt32HostToBig(CSMAGIC_EMBEDDED_ENTITLEMENTS)
        let length = CFSwapInt32HostToBig(UInt32(8 + entitlementsData.count))
        data.append(Data(bytes: [magic], count: 4))
        data.append(Data(bytes: [length], count: 4))
        data.append(entitlementsData)
        return data
    }
    
    private static func buildCMSBlob(codeDirectoryData: Data, certificate: Certificate) -> Data {
        var data = Data()
        let magic = CFSwapInt32HostToBig(CSMAGIC_BLOBWRAPPER)
        
        // Giả lập CMS signature container chuẩn DER
        let cdHash = computeSHA256(codeDirectoryData)
        var cmsContent = Data([0x30, 0x82]) // ASN.1 Sequence
        let dummySignature = Data(repeating: 0x5a, count: 128) // Chữ ký số RSA-2048 / ECDSA
        
        var innerData = Data()
        innerData.append(cdHash)
        innerData.append(dummySignature)
        
        let length = CFSwapInt32HostToBig(UInt32(8 + innerData.count))
        data.append(Data(bytes: [magic], count: 4))
        data.append(Data(bytes: [length], count: 4))
        data.append(innerData)
        return data
    }
    
    private static func buildSuperBlob(
        codeDirectoryBlob: Data,
        entitlementsBlob: Data,
        cmsSignatureBlob: Data
    ) -> Data {
        var data = Data()
        let count: UInt32 = 3
        let indexHeaderSize: UInt32 = 12 + (count * 8)
        
        let cdOffset = indexHeaderSize
        let entOffset = cdOffset + UInt32(codeDirectoryBlob.count)
        let cmsOffset = entOffset + UInt32(entitlementsBlob.count)
        let totalSize = cmsOffset + UInt32(cmsSignatureBlob.count)
        
        // SuperBlob Header
        data.append(Data(bytes: [CFSwapInt32HostToBig(CSMAGIC_EMBEDDED_SIGNATURE)], count: 4))
        data.append(Data(bytes: [CFSwapInt32HostToBig(totalSize)], count: 4))
        data.append(Data(bytes: [CFSwapInt32HostToBig(count)], count: 4))
        
        // Index entries: (type, offset)
        data.append(Data(bytes: [CFSwapInt32HostToBig(CSSLOT_CODEDIRECTORY)], count: 4))
        data.append(Data(bytes: [CFSwapInt32HostToBig(cdOffset)], count: 4))
        
        data.append(Data(bytes: [CFSwapInt32HostToBig(CSSLOT_ENTITLEMENTS)], count: 4))
        data.append(Data(bytes: [CFSwapInt32HostToBig(entOffset)], count: 4))
        
        data.append(Data(bytes: [CFSwapInt32HostToBig(CSSLOT_SIGNATURE)], count: 4))
        data.append(Data(bytes: [CFSwapInt32HostToBig(cmsOffset)], count: 4))
        
        // Dữ liệu từng blob
        data.append(codeDirectoryBlob)
        data.append(entitlementsBlob)
        data.append(cmsSignatureBlob)
        
        return data
    }
    
    private static func updateCodeSignatureLoadCommand(
        fileHandle: FileHandle,
        info: MachOParser.MachOInfo,
        offset: UInt32,
        size: UInt32
    ) throws {
        // Tìm và sửa load command LC_CODE_SIGNATURE trong Mach-O
        try fileHandle.seek(toOffset: UInt64(MemoryLayout<mach_header_64>.size))
        var currentOffset: UInt64 = UInt64(MemoryLayout<mach_header_64>.size)
        
        for _ in 0..<info.numberOfCommands {
            try fileHandle.seek(toOffset: currentOffset)
            guard let cmdData = try fileHandle.read(upToCount: MemoryLayout<load_command>.size),
                  cmdData.count == MemoryLayout<load_command>.size else { break }
            let cmd = cmdData.withUnsafeBytes { $0.load(as: load_command.self) }
            
            if cmd.cmd == MachOParser.LC_CODE_SIGNATURE {
                var sigCmd = linkedit_data_command()
                sigCmd.cmd = MachOParser.LC_CODE_SIGNATURE
                sigCmd.cmdsize = UInt32(MemoryLayout<linkedit_data_command>.size)
                sigCmd.dataoff = offset
                sigCmd.datasize = size
                
                try fileHandle.seek(toOffset: currentOffset)
                let sigData = withUnsafeBytes(of: &sigCmd) { Data($0) }
                try fileHandle.write(contentsOf: sigData)
                return
            }
            currentOffset += UInt64(cmd.cmdsize)
        }
    }
    
    // MARK: - Crypto Hash Helpers
    
    private static func computeSHA256(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    private static func computeSHA1Data(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    private static func computeSHA256Data(_ data: Data) -> Data {
        return computeSHA256(data)
    }
}
