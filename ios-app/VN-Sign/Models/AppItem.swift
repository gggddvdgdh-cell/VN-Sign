import Foundation
import UIKit

/// Đại diện cho ứng dụng trong thư viện ký hoặc đã ký
public struct AppItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var version: String
    public var buildNumber: String
    public var fileSize: Int64
    public var filePath: String
    public var iconPath: String?
    public var originalIpaPath: String
    public var signedIpaPath: String?
    public var isSigned: Bool
    public var dateAdded: Date
    public var signedDate: Date?
    public var teamName: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        version: String,
        buildNumber: String = "1",
        fileSize: Int64 = 0,
        filePath: String,
        iconPath: String? = nil,
        originalIpaPath: String,
        signedIpaPath: String? = nil,
        isSigned: Bool = false,
        dateAdded: Date = Date(),
        signedDate: Date? = nil,
        teamName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.buildNumber = buildNumber
        self.fileSize = fileSize
        self.filePath = filePath
        self.iconPath = iconPath
        self.originalIpaPath = originalIpaPath
        self.signedIpaPath = signedIpaPath
        self.isSigned = isSigned
        self.dateAdded = dateAdded
        self.signedDate = signedDate
        self.teamName = teamName
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
