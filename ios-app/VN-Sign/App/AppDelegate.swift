import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
    
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Khởi động các dịch vụ nền
        _ = CertManager.shared
        _ = SigningEngine.shared
        _ = LocalServer.shared
        return true
    }
    
    // Xử lý mở tệp từ ứng dụng Tệp (Files app) hoặc chia sẻ AirDrop
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
        
        let targetURL = docURL.appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: url, to: targetURL)
        } catch {
            print("Lỗi chép tệp mở ngoài: \(error)")
        }
        
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "ipa":
            SigningEngine.shared.reloadLibraryApps()
            return true
            
        case "p12":
            // Thử nhập với mật khẩu mặc định rỗng nếu có
            _ = try? CertManager.shared.importP12(from: targetURL, password: "")
            return true
            
        case "mobileprovision":
            _ = try? CertManager.shared.importMobileProvision(from: targetURL)
            return true
            
        default:
            return true
        }
    }
}
