import os, base64

p12_path = r'd:\VN-Sign\ios-app\VN-Sign\Resources\vnsign_server.p12'
mobileconfig_path = r'd:\VN-Sign\ios-app\VN-Sign\Resources\VNSign_Root_CA.mobileconfig'
output_swift = r'd:\VN-Sign\ios-app\VN-Sign\Services\ServerIdentity.swift'

with open(p12_path, 'rb') as f:
    b64_p12 = base64.b64encode(f.read()).decode('ascii')

with open(mobileconfig_path, 'r', encoding='utf-8') as f:
    config_str = f.read()

# Escape for Swift multiline string literal
swift_code = '''import Foundation

/// Chứa danh tính máy chủ bảo mật TLS và hồ sơ cấu hình CA cục bộ của VN-Sign
public struct ServerIdentity {
    public static let p12Password = "vnsign"
    public static let httpsPort: UInt16 = 8443
    public static let httpPort: UInt16 = 8080
    
    /// Chứng chỉ máy chủ PKCS#12 (server.crt + server.key + ca.crt) mã hoá Base64
    public static let p12Base64 = "''' + b64_p12 + '''"
    
    /// Hồ sơ cấu hình Apple Configuration Profile (.mobileconfig) chứa Root CA
    public static let rootCAMobileConfig = """
''' + config_str + '''
"""
}
'''

with open(output_swift, 'w', encoding='utf-8') as f:
    f.write(swift_code)

print("Created ServerIdentity.swift successfully!")
