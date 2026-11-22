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
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "ipa":
            // Thêm vào danh sách thư viện ký
            let name = url.deletingPathExtension().lastPathComponent
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            let appItem = AppItem(
                name: name,
                bundleIdentifier: "com.vnsign.\(name.lowercased().filter { $0.isLetter })",
                version: "1.0",
                fileSize: size,
                filePath: url.path,
                originalIpaPath: url.path
            )
            DispatchQueue.main.async {
                SigningEngine.shared.libraryApps.insert(appItem, at: 0)
            }
            return true
            
        case "p12":
            // Nhập chứng chỉ .p12 (với pass mặc định hoặc thông báo)
            _ = try? CertManager.shared.importP12(from: url, password: "1")
            return true
            
        case "mobileprovision":
            // Nhập hồ sơ provisioning
            _ = try? CertManager.shared.importMobileProvision(from: url)
            return true
            
        default:
            return false
        }
    }
}
