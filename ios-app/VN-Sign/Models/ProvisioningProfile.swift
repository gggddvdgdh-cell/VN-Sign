import Foundation

/// Đại diện cho hồ sơ cấu hình thiết bị Apple (.mobileprovision)
public struct ProvisioningProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var uuid: String
    public var name: String
    public var teamIdentifier: String
    public var teamName: String
    public var creationDate: Date
    public var expirationDate: Date
    public var isWildcard: Bool
    public var provisionsAllDevices: Bool
    public var provisionedDevices: [String]
    public var entitlements: [String: AnyCodable]
    public var fileURL: URL?
    
    public init(
        id: UUID = UUID(),
        uuid: String,
        name: String,
        teamIdentifier: String,
        teamName: String = "",
        creationDate: Date = Date(),
        expirationDate: Date,
        isWildcard: Bool = false,
        provisionsAllDevices: Bool = false,
        provisionedDevices: [String] = [],
        entitlements: [String: AnyCodable] = [:],
        fileURL: URL? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.name = name
        self.teamIdentifier = teamIdentifier
        self.teamName = teamName
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.isWildcard = isWildcard
        self.provisionsAllDevices = provisionsAllDevices
        self.provisionedDevices = provisionedDevices
        self.entitlements = entitlements
        self.fileURL = fileURL
    }
    
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return max(0, components.day ?? 0)
    }
    
    public var isValid: Bool {
        return expirationDate > Date()
    }
}

/// Helper wrapper cho Codable dictionary chứa các kiểu dữ liệu plist khác nhau
public struct AnyCodable: Codable, Equatable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            self.value = dictVal.mapValues { $0.value }
        } else {
            self.value = ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}
