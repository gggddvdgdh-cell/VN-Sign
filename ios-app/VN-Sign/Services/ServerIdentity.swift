import Foundation

/// Chứa danh tính máy chủ bảo mật TLS và hồ sơ cấu hình CA cục bộ của VN-Sign
public struct ServerIdentity {
    public static let p12Password = "vnsign"
    public static let httpsPort: UInt16 = 8443
    public static let httpPort: UInt16 = 8080
    
    /// Chứng chỉ máy chủ PKCS#12 (server.crt + server.key + ca.crt) mã hoá Base64
    public static let p12Base64 = "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"
    
    /// Hồ sơ cấu hình Apple Configuration Profile (.mobileconfig) chứa Root CA
    public static let rootCAMobileConfig = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadCertificateFileName</key>
            <string>vnsign_root_ca.crt</string>
            <key>PayloadContent</key>
            <data>
MIIDZjCCAk6gAwIBAgIUbQuBpSu1bbGmOiasqbe0EfY21iQwDQYJKoZIhvcNAQEL
BQAwSzEeMBwGA1UEAwwVVk4tU2lnbiBMb2NhbCBSb290IENBMRwwGgYDVQQKDBNW
Ti1TaWduIENvcnBvcmF0aW9uMQswCQYDVQQGEwJWTjAeFw0yNjExMjExNDQzNTRa
Fw00NjExMTcxNDQzNTRaMEsxHjAcBgNVBAMMFVZOLVNpZ24gTG9jYWwgUm9vdCBD
QTEcMBoGA1UECgwTVk4tU2lnbiBDb3Jwb3JhdGlvbjELMAkGA1UEBhMCVk4wggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDXzQkRdvAgU+h7SQbS42JHc2+i
8OaVbB4NETwjqGIZfOGyBOct3+cBaGFp0aaIh4dMyHJi3jbBfPLpnMDK4ZtS5DDA
3qj8FtgFlluTveDzsdxb+FqyPy9gwXT6OoQ0VkW08UoZ5tdEYUvFS8siUWNKn/tv
GgFLTtQyuUvAFqceb2juspvov4/DA5whIHyRmUD6ZvPjQ9Bf70QaCjPPIQgrKEIz
+Ow1da00z1otZvOc7pFw22FNtRoqIytIoWG46LrcWREBuuwZe/6Bo2pSDV0s42Ef
gg8/dAvTPKxK0ZOab/1KGrJYHRBqd9XlC/TOOlqkaLa/q+zmhzEVHRN80w9NAgMB
AAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQW
BBRAti2PwfkMZrA/2yoFyLDF+ly5gjANBgkqhkiG9w0BAQsFAAOCAQEAVVNchm3m
lRLoFb+WDKJFAG/9u8v2fRpx6hXuNdEZdSz4JIQyvxefASpTHLE8J8SbX2LjtwXl
k1C0g/PjSJNUr4uGordcYGPUFthUKgiTTxYRlmgjB5+fcy7s9mISudtdfyaO+mY6
BXpvVlMim3nOaoYN2yeqOKNMne/HdQPVOKweoyi8i/atx2tjZz9MZ4wfqFlcALS8
FOxYvOUJoY7mlqIlw6QAQtBwryIU3KSwghmh6Kovx6+VdZ9FsK1noJ9GVsOQQJj2
LjvpBPUTXnZ74v3sfYh9gzDodNI6k+ABV833qs0Bbx1eNxw9vx9cZFhKWQTHNHiP
iyf/5gAA1NSRWg==
            </data>
            <key>PayloadDescription</key>
            <string>Chứng chỉ gốc tin cậy nội bộ phục vụ cài đặt trực tiếp ứng dụng OTA HTTPS cho VN-Sign.</string>
            <key>PayloadDisplayName</key>
            <string>VN-Sign Local Root CA</string>
            <key>PayloadIdentifier</key>
            <string>com.vnsign.rootca.cert</string>
            <key>PayloadType</key>
            <string>com.apple.security.root</string>
            <key>PayloadUUID</key>
            <string>406A1F0D-EB94-481C-B7E3-CB02E803A435</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>Cài đặt hồ sơ này để iPhone tin cậy máy chủ nội bộ VN-Sign và cho phép cài đặt trực tiếp ứng dụng không cần máy tính.</string>
    <key>PayloadDisplayName</key>
    <string>VN-Sign Local CA Profile</string>
    <key>PayloadIdentifier</key>
    <string>com.vnsign.rootca.profile</string>
    <key>PayloadOrganization</key>
    <string>VN-Sign Corporation</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>89F95809-F913-4B31-80E1-BBF255FAA2A0</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
"""
}
