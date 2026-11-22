import Foundation
import MachO

/// Bộ phân tích và xử lý định dạng tệp thực thi Mach-O (ARM64 / Universal)
public final class MachOParser {
    
    public struct MachOInfo {
        public var is64Bit: Bool
        public var isFat: Bool
        public var isLittleEndian: Bool
        public var cpuType: cpu_type_t
        public var cpuSubtype: cpu_subtype_t
        public var fileType: UInt32
        public var numberOfCommands: UInt32
        public var sizeOfCommands: UInt32
        public var codeSignatureOffset: UInt32?
        public var codeSignatureSize: UInt32?
        public var linkeditSegmentOffset: UInt64?
        public var linkeditSegmentSize: UInt64?
    }
    
    /// Hằng số ma thuật Mach-O
    public static let MH_MAGIC_64: UInt32 = 0xfeedfacf
    public static let MH_CIGAM_64: UInt32 = 0xcffaedfe
    public static let MH_MAGIC: UInt32 = 0xfeedface
    public static let MH_CIGAM: UInt32 = 0xcefaedfe
    public static let FAT_MAGIC: UInt32 = 0xcafebabe
    public static let FAT_CIGAM: UInt32 = 0xbebafeca
    public static let FAT_MAGIC_64: UInt32 = 0xcafebabf
    
    public static let LC_SEGMENT: UInt32 = 0x1
    public static let LC_SEGMENT_64: UInt32 = 0x19
    public static let LC_CODE_SIGNATURE: UInt32 = 0x1d
    public static let LC_LOAD_DYLIB: UInt32 = 0xc
    public static let LC_LOAD_WEAK_DYLIB: UInt32 = 0x18 | 0x80000000
    public static let LC_RPATH: UInt32 = 0x1c | 0x80000000
    
    /// Phân tích tệp nhị phân Mach-O tại URL
    public static func parse(fileURL: URL) throws -> MachOInfo {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }
        
        guard let magicData = try fileHandle.read(upToCount: 4), magicData.count == 4 else {
            throw MachOError.invalidHeader
        }
        
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if magic == MH_MAGIC_64 || magic == MH_CIGAM_64 {
            return try parseMachO64(fileHandle: fileHandle, isLittleEndian: magic == MH_MAGIC_64)
        } else if magic == FAT_MAGIC || magic == FAT_CIGAM {
            // Universal binary - đọc slice đầu tiên (ưu tiên ARM64)
            return try parseFatBinary(fileHandle: fileHandle)
        } else {
            throw MachOError.unsupportedArchitecture
        }
    }
    
    private static func parseMachO64(fileHandle: FileHandle, isLittleEndian: Bool, offset: UInt64 = 0) throws -> MachOInfo {
        try fileHandle.seek(toOffset: offset)
        guard let headerData = try fileHandle.read(upToCount: MemoryLayout<mach_header_64>.size),
              headerData.count == MemoryLayout<mach_header_64>.size else {
            throw MachOError.invalidHeader
        }
        
        let header = headerData.withUnsafeBytes { $0.load(as: mach_header_64.self) }
        
        var codeSigOffset: UInt32?
        var codeSigSize: UInt32?
        var linkeditOffset: UInt64?
        var linkeditSize: UInt64?
        
        var currentOffset = offset + UInt64(MemoryLayout<mach_header_64>.size)
        
        for _ in 0..<header.ncmds {
            try fileHandle.seek(toOffset: currentOffset)
            guard let cmdData = try fileHandle.read(upToCount: MemoryLayout<load_command>.size),
                  cmdData.count == MemoryLayout<load_command>.size else {
                break
            }
            let cmd = cmdData.withUnsafeBytes { $0.load(as: load_command.self) }
            
            if cmd.cmd == LC_CODE_SIGNATURE {
                try fileHandle.seek(toOffset: currentOffset)
                if let sigCmdData = try fileHandle.read(upToCount: MemoryLayout<linkedit_data_command>.size),
                   sigCmdData.count == MemoryLayout<linkedit_data_command>.size {
                    let sigCmd = sigCmdData.withUnsafeBytes { $0.load(as: linkedit_data_command.self) }
                    codeSigOffset = sigCmd.dataoff
                    codeSigSize = sigCmd.datasize
                }
            } else if cmd.cmd == LC_SEGMENT_64 {
                try fileHandle.seek(toOffset: currentOffset)
                if let segData = try fileHandle.read(upToCount: MemoryLayout<segment_command_64>.size),
                   segData.count == MemoryLayout<segment_command_64>.size {
                    let seg = segData.withUnsafeBytes { $0.load(as: segment_command_64.self) }
                    let segName = withUnsafeBytes(of: seg.segname) { rawPtr -> String in
                        let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
                        return String(cString: ptr)
                    }
                    if segName == "__LINKEDIT" {
                        linkeditOffset = seg.fileoff
                        linkeditSize = seg.filesize
                    }
                }
            }
            
            currentOffset += UInt64(cmd.cmdsize)
        }
        
        return MachOInfo(
            is64Bit: true,
            isFat: false,
            isLittleEndian: isLittleEndian,
            cpuType: header.cputype,
            cpuSubtype: header.cpusubtype,
            fileType: header.filetype,
            numberOfCommands: header.ncmds,
            sizeOfCommands: header.sizeofcmds,
            codeSignatureOffset: codeSigOffset,
            codeSignatureSize: codeSigSize,
            linkeditSegmentOffset: linkeditOffset,
            linkeditSegmentSize: linkeditSize
        )
    }
    
    private static func parseFatBinary(fileHandle: FileHandle) throws -> MachOInfo {
        try fileHandle.seek(toOffset: 0)
        guard let fatHeaderData = try fileHandle.read(upToCount: MemoryLayout<fat_header>.size) else {
            throw MachOError.invalidHeader
        }
        let fatHeader = fatHeaderData.withUnsafeBytes { $0.load(as: fat_header.self) }
        let numArchs = CFSwapInt32BigToHost(fatHeader.nfat_arch)
        
        var selectedOffset: UInt64 = 0
        
        for _ in 0..<numArchs {
            guard let archData = try fileHandle.read(upToCount: MemoryLayout<fat_arch>.size) else { break }
            let arch = archData.withUnsafeBytes { $0.load(as: fat_arch.self) }
            let cpuType = CFSwapInt32BigToHost(UInt32(arch.cputype))
            let offset = UInt64(CFSwapInt32BigToHost(arch.offset))
            
            // Ưu tiên CPU_TYPE_ARM64 = 0x0100000c
            if cpuType == 0x0100000c {
                selectedOffset = offset
                break
            }
            if selectedOffset == 0 {
                selectedOffset = offset
            }
        }
        
        if selectedOffset == 0 {
            throw MachOError.unsupportedArchitecture
        }
        
        var info = try parseMachO64(fileHandle: fileHandle, isLittleEndian: true, offset: selectedOffset)
        info.isFat = true
        return info
    }
}

public enum MachOError: LocalizedError {
    case invalidHeader
    case unsupportedArchitecture
    case loadCommandNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidHeader:
            return "Cấu trúc tiêu đề Mach-O không hợp lệ."
        case .unsupportedArchitecture:
            return "Kiến trúc Mach-O không được hỗ trợ (cần ARM64)."
        case .loadCommandNotFound:
            return "Không tìm thấy Load Command cần thiết."
        }
    }
}
