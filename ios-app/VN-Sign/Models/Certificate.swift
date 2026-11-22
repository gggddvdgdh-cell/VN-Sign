import Foundation
import Security

/// Đại diện cho chứng chỉ số Apple Developer / Enterprise (.p12)
public struct Certificate: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var teamName: String
    public var teamID: String
    public var creationDate: Date?
    public var expirationDate: Date
    public var sha1Fingerprint: String
    public var fileURL: URL?
    public var password: String
    public var isRevoked: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        teamName: String,
        teamID: String,
        creationDate: Date? = nil,
        expirationDate: Date,
        sha1Fingerprint: String = "",
        fileURL: URL? = nil,
        password: String = "",
        isRevoked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.teamName = teamName
        self.teamID = teamID
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.sha1Fingerprint = sha1Fingerprint
        self.fileURL = fileURL
        self.password = password
        self.isRevoked = isRevoked
    }
    
    /// Số ngày còn hiệu lực
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return max(0, components.day ?? 0)
    }
    
    /// Trạng thái hiệu lực
    public var isValid: Bool {
        return !isRevoked && expirationDate > Date()
    }
    
    /// Nhãn hiển thị Team và ID
    public var displayTeam: String {
        if teamName.isEmpty {
            return teamID
        }
        return "\(teamName) (\(teamID))"
    }
}
