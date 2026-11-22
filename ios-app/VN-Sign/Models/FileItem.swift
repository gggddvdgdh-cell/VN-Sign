import Foundation

public enum FileType: String, Codable, CaseIterable {
    case ipa = "ipa"
    case p12 = "p12"
    case mobileprovision = "mobileprovision"
    case dylib = "dylib"
    case zip = "zip"
    case other = "other"
    
    public var iconSystemName: String {
        switch self {
        case .ipa:
            return "app.badge.fill"
        case .p12:
            return "key.horizontal.fill"
        case .mobileprovision:
            return "checkmark.seal.fill"
        case .dylib:
            return "shippingbox.fill"
        case .zip:
            return "doc.zipper"
        case .other:
            return "doc.fill"
        }
    }
    
    public var badgeColorHex: String {
        switch self {
        case .ipa:
            return "#06b6d4" // Cyan
        case .p12:
            return "#f59e0b" // Amber
        case .mobileprovision:
            return "#10b981" // Emerald
        case .dylib:
            return "#8b5cf6" // Purple
        case .zip:
            return "#3b82f6" // Blue
        case .other:
            return "#6b7280" // Gray
        }
    }
}

/// Đại diện cho một tệp trong trình quản lý tệp E-Sign
public struct FileItem: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var url: URL
    public var size: Int64
    public var modificationDate: Date
    public var fileType: FileType
    public var isSelected: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        size: Int64 = 0,
        modificationDate: Date = Date(),
        fileType: FileType = .other,
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.size = size
        self.modificationDate = modificationDate
        self.fileType = fileType
        self.isSelected = isSelected
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
}
