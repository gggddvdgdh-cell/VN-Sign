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
MIIDZjCCAk6gAwIBAgIUOvAHxZXLN6wXoFWNu9HFln7twP0wDQYJKoZIhvcNAQEL
BQAwSzEeMBwGA1UEAwwVVk4tU2lnbiBMb2NhbCBSb290IENBMRwwGgYDVQQKDBNW
Ti1TaWduIENvcnBvcmF0aW9uMQswCQYDVQQGEwJWTjAeFw0yNjExMjExNTAwMjJa
Fw00NjExMTcxNTAwMjJaMEsxHjAcBgNVBAMMFVZOLVNpZ24gTG9jYWwgUm9vdCBD
QTEcMBoGA1UECgwTVk4tU2lnbiBDb3Jwb3JhdGlvbjELMAkGA1UEBhMCVk4wggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsB5OhJy2Pcy/Fzw2GEN8JNPu+
KH6ZGk1kNeG6+B3Mby3I6fHkjwnuKlX2GqeUEUYzm/Ujqh6kcsOobwW69y01IVP0
vRNYINBbF4kvKcvwriHWvxfzKVpvGketdYTwWlhBtS8vlBxT78XH7XUiLHWxyLcp
EWOlLERzeMlrIgwDWD7v770fYudmKmaNV2mUL+uqDOR4vG2avsS86EB3oo/EuVrf
JgIqhOwTQ+Xj3+dNamPqSygiWyp/xCplid4YjYpk0+b2dGWrg9MrZ5sk6UukjxdK
Fj2oLnCNX890RNoZntXCVJAKE+9vcXKgR/dvKp3dkCEuhbhaVWHV0G5O8ExDAgMB
AAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQW
BBRgmSG/Q9KEyp4JwUJ2n1cSY6OgTTANBgkqhkiG9w0BAQsFAAOCAQEAi5PYdR2L
V0T23AdGOCSVYnlM7GAyrWI0TZmdBmIrwMF4+0gOs7BydFYky7AIEpOmeqwFnQTL
LvYmM1QgDqsqmMZIMHxUzk7Yle/ivj+AT8yHOZgNYD/2tXY1BQzjJTQ5EmpR2QZV
7WLbd7Gp323DeUXPOEZLT3YSPTj7PdQGTJdCtHghVsL7pD5hvBs2Yhrhr4Lh7zy+
3zZIqoV2OMXn/FV4A9Wb4yYjMgTxjYwJc/XUWk6FZ7Tqz05WDJu8VtVuHu6QICwx
0ZBgdM9iY5huROt8xbiWZKP1YggJbesMARCigv3QRMooM6q9xl0pe7YkxMORH8kk
5ZUk2a0JgV/6ww==
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
            <string>5DA72986-0D7D-48E1-8BEA-C81DD1F1102C</string>
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
    <string>FD88A3CE-56F1-4E72-9624-D9303709AA8A</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
"""
}
