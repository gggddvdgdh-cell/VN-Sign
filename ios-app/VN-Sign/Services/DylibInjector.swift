import Foundation
import MachO

/// Bộ tiêm thư viện động (Dylib / Tweak injection) vào Mach-O binary
public final class DylibInjector {
    
    public enum InjectError: LocalizedError {
        case fileNotFound
        case insufficientHeaderPadding
        case invalidMachO
        case writeFailed
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Không tìm thấy tệp nhị phân hoặc tệp dylib."
            case .insufficientHeaderPadding:
                return "Không đủ khoảng trống đệm trong tiêu đề Mach-O để chèn LC_LOAD_DYLIB."
            case .invalidMachO:
                return "Tệp nhị phân Mach-O không hợp lệ."
            case .writeFailed:
                return "Không thể ghi bản vá load command vào tệp thực thi."
            }
        }
    }
    
    /// Tiêm dylib vào Mach-O binary
    /// - Parameters:
    ///   - binaryURL: URL tệp thực thi Mach-O chính
    ///   - dylibName: Tên dylib (vd: "Rocket.dylib")
    ///   - useRpath: Sử dụng @rpath/ hay @executable_path/Frameworks/
    public static func injectDylib(binaryURL: URL, dylibName: String, useRpath: Bool = true) throws {
        guard FileManager.default.fileExists(atPath: binaryURL.path) else {
            throw InjectError.fileNotFound
        }
        
        let pathString = useRpath ? "@rpath/\(dylibName)" : "@executable_path/Frameworks/\(dylibName)"
        guard let pathData = pathString.data(using: .utf8) else {
            throw InjectError.invalidMachO
        }
        
        let fileHandle = try FileHandle(forUpdating: binaryURL)
        defer { try? fileHandle.close() }
        
        // Đọc mach_header_64
        guard let headerData = try fileHandle.read(upToCount: MemoryLayout<mach_header_64>.size),
              headerData.count == MemoryLayout<mach_header_64>.size else {
            throw InjectError.invalidMachO
        }
        
        var header = headerData.withUnsafeBytes { $0.load(as: mach_header_64.self) }
        guard header.magic == MachOParser.MH_MAGIC_64 || header.magic == MachOParser.MH_CIGAM_64 else {
            throw InjectError.invalidMachO
        }
        
        // Tính toán kích thước dylib_command căn chỉnh theo bội số 8 bytes
        let cmdHeaderSize = MemoryLayout<dylib_command>.size
        let rawTotal = cmdHeaderSize + pathData.count + 1 // + null terminator
        let alignedCmdSize = UInt32((rawTotal + 7) & ~7)
        
        let commandsEndOffset = UInt64(MemoryLayout<mach_header_64>.size) + UInt64(header.sizeofcmds)
        
        // Kiểm tra khoảng trống đệm xem có toàn 0 không
        try fileHandle.seek(toOffset: commandsEndOffset)
        guard let paddingData = try fileHandle.read(upToCount: Int(alignedCmdSize)),
              paddingData.count == Int(alignedCmdSize) else {
            throw InjectError.insufficientHeaderPadding
        }
        
        // Xác minh khoảng đệm trống
        let isZeroPadding = paddingData.allSatisfy { $0 == 0 }
        guard isZeroPadding else {
            throw InjectError.insufficientHeaderPadding
        }
        
        // Xây dựng struct dylib_command
        let lcStr = lc_str(offset: UInt32(cmdHeaderSize))
        let dylibInfo = dylib(name: lcStr, timestamp: 2, current_version: 0x00010000, compatibility_version: 0x00010000)
        var dylibCmd = dylib_command(cmd: MachOParser.LC_LOAD_DYLIB, cmdsize: alignedCmdSize, dylib: dylibInfo)
        
        // Chuẩn bị buffer dữ liệu mới
        var newCmdBuffer = withUnsafeBytes(of: &dylibCmd) { Data($0) }
        newCmdBuffer.append(pathData)
        newCmdBuffer.append(0) // Null-terminator
        
        // Thêm padding 0 cho đủ alignedCmdSize
        while newCmdBuffer.count < Int(alignedCmdSize) {
            newCmdBuffer.append(0)
        }
        
        // Ghi dylib_command mới vào cuối danh sách load commands
        try fileHandle.seek(toOffset: commandsEndOffset)
        try fileHandle.write(contentsOf: newCmdBuffer)
        
        // Cập nhật mach_header_64 (tăng ncmds và sizeofcmds)
        header.ncmds += 1
        header.sizeofcmds += alignedCmdSize
        
        try fileHandle.seek(toOffset: 0)
        let updatedHeaderData = withUnsafeBytes(of: &header) { Data($0) }
        try fileHandle.write(contentsOf: updatedHeaderData)
    }
}
