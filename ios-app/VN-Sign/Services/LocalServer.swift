import Foundation
import Network
import Security
import UIKit

/// Máy chủ HTTPS (TLS) và HTTP cục bộ phục vụ giao thức itms-services:// để cài đặt trực tiếp không qua máy tính
public final class LocalServer: ObservableObject {
    public static let shared = LocalServer()
    
    @Published public var isRunning: Bool = false
    @Published public var httpsPort: UInt16 = ServerIdentity.httpsPort
    @Published public var httpPort: UInt16 = ServerIdentity.httpPort
    @Published public var statusMessage: String = "Sẵn sàng"
    public var serverPort: UInt16 { httpsPort }
    
    private var httpsListener: NWListener?
    private var httpListener: NWListener?
    private let queue = DispatchQueue(label: "com.vnsign.localserver.queue")
    private var currentServedApp: AppItem?
    
    private init() {}
    
    // MARK: - Start / Stop Server
    
    /// Khởi động máy chủ HTTPS (cổng 8443) và HTTP (cổng 8080)
    public func startServer() throws {
        guard !isRunning else { return }
        
        // 1. Khởi động HTTPS Listener với chứng chỉ bảo mật VN-Sign
        if let tlsParameters = createTLSParameters() {
            let nwHttpsPort = NWEndpoint.Port(rawValue: httpsPort) ?? NWEndpoint.Port(rawValue: 8443)!
            self.httpsListener = try NWListener(using: tlsParameters, on: nwHttpsPort)
            
            self.httpsListener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection, isTLS: true)
            }
            
            self.httpsListener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.statusMessage = "Máy chủ OTA HTTPS đang chạy (Port \(self?.httpsPort ?? 8443))"
                    case .failed(let error):
                        self?.statusMessage = "Lỗi HTTPS: \(error.localizedDescription)"
                    default:
                        break
                    }
                }
            }
            
            self.httpsListener?.start(queue: queue)
        }
        
        // 2. Khởi động HTTP Listener phục vụ tải file .mobileconfig
        let httpParameters = NWParameters.tcp
        let nwHttpPort = NWEndpoint.Port(rawValue: httpPort) ?? NWEndpoint.Port(rawValue: 8080)!
        self.httpListener = try NWListener(using: httpParameters, on: nwHttpPort)
        
        self.httpListener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection, isTLS: false)
        }
        
        self.httpListener?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isRunning = true
                case .failed(let error):
                    print("[LocalServer] HTTP Listener failed: \(error)")
                default:
                    break
                }
            }
        }
        
        self.httpListener?.start(queue: queue)
    }
    
    /// Dừng toàn bộ máy chủ cục bộ
    public func stopServer() {
        httpsListener?.cancel()
        httpsListener = nil
        httpListener?.cancel()
        httpListener = nil
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusMessage = "Đã dừng"
        }
    }
    
    // MARK: - Direct Installation Action
    
    /// Bắt đầu quy trình cài đặt OTA trực tiếp qua giao thức HTTPS bảo mật
    @MainActor
    public func installAppDirectly(_ app: AppItem) {
        self.currentServedApp = app
        
        if !isRunning {
            try? startServer()
        }
        
        // Tạo manifest endpoint qua HTTPS 127.0.0.1
        let manifestEndpoint = "https://127.0.0.1:\(httpsPort)/manifest.plist"
        guard let encodedManifest = manifestEndpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let itmsURL = URL(string: "itms-services://?action=download-manifest&url=\(encodedManifest)") else {
            return
        }
        
        // Kích hoạt giao thức cài đặt OTA ngầm của Apple
        UIApplication.shared.open(itmsURL, options: [:]) { success in
            if success {
                print("[LocalServer] Đã mở yêu cầu itms-services HTTPS thành công!")
            } else {
                print("[LocalServer] Không thể mở URL itms-services.")
            }
        }
    }
    
    /// Hỗ trợ người dùng mở và cài đặt hồ sơ chứng chỉ CA cục bộ vào iPhone
    @MainActor
    public func openCAProfileInstallation() {
        if !isRunning {
            try? startServer()
        }
        
        // Mở Safari để tải file cấu hình .mobileconfig từ cổng 8080
        if let url = URL(string: "http://127.0.0.1:\(httpPort)/ca.mobileconfig") {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    // Dự phòng: Chia sẻ trực tiếp file .mobileconfig qua Share Sheet
                    self.shareCAProfileFile()
                }
            }
        }
    }
    
    /// Xuất và chia sẻ file .mobileconfig ra ngoài
    @MainActor
    public func shareCAProfileFile() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("VNSign_Root_CA.mobileconfig")
        try? ServerIdentity.rootCAMobileConfig.data(using: .utf8)?.write(to: tempURL)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - TLS Identity Configuration
    
    private func createTLSParameters() -> NWParameters? {
        guard let p12Data = Data(base64Encoded: ServerIdentity.p12Base64) else { return nil }
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: ServerIdentity.p12Password
        ]
        
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &rawItems)
        guard status == errSecSuccess,
              let items = rawItems as? [[String: Any]],
              let firstItem = items.first,
              let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity? else {
            print("[LocalServer] Không thể nhập SecIdentity từ p12: \(status)")
            return nil
        }
        
        let tlsOptions = NWProtocolTLS.Options()
        guard let secIdentity = sec_identity_create(identity) else {
            print("[LocalServer] sec_identity_create thất bại")
            return nil
        }
        
        sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        
        return NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
    }
    
    // MARK: - HTTP / HTTPS Request Handling
    
    private func handleConnection(_ connection: NWConnection, isTLS: Bool) {
        connection.start(queue: queue)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] (data, _, isComplete, error) in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            
            let requestString = String(data: data, encoding: .utf8) ?? ""
            let lines = requestString.components(separatedBy: "\r\n")
            guard let firstLine = lines.first else {
                connection.cancel()
                return
            }
            
            let parts = firstLine.components(separatedBy: " ")
            guard parts.count >= 2 else {
                connection.cancel()
                return
            }
            
            let path = parts[1]
            
            if path.contains("ca.mobileconfig") {
                self.serveMobileConfig(connection: connection)
            } else if path.contains("manifest.plist") {
                self.serveManifest(connection: connection)
            } else if path.contains("download.ipa") {
                self.serveIPA(connection: connection)
            } else {
                self.serveNotFound(connection: connection)
            }
        }
    }
    
    private func serveMobileConfig(connection: NWConnection) {
        let configData = ServerIdentity.rootCAMobileConfig.data(using: .utf8) ?? Data()
        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: application/x-apple-aspen-config\r
        Content-Length: \(configData.count)\r
        Content-Disposition: attachment; filename="VNSign_Root_CA.mobileconfig"\r
        Connection: close\r
        \r
        """
        
        var response = header.data(using: .utf8)!
        response.append(configData)
        
        connection.send(content: response, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func serveManifest(connection: NWConnection) {
        let app = currentServedApp ?? AppItem(
            name: "VN-Sign App",
            bundleIdentifier: "com.vnsign.app",
            version: "1.0",
            filePath: "",
            originalIpaPath: ""
        )
        
        // URL tải IPA bắt buộc phải qua HTTPS 127.0.0.1
        let downloadURL = "https://127.0.0.1:\(httpsPort)/download.ipa"
        
        let manifestXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>items</key>
            <array>
                <dict>
                    <key>assets</key>
                    <array>
                        <dict>
                            <key>kind</key>
                            <string>software-package</string>
                            <key>url</key>
                            <string>\(downloadURL)</string>
                        </dict>
                    </array>
                    <key>metadata</key>
                    <dict>
                        <key>bundle-identifier</key>
                        <string>\(app.bundleIdentifier)</string>
                        <key>bundle-version</key>
                        <string>\(app.version)</string>
                        <key>kind</key>
                        <string>software</string>
                        <key>title</key>
                        <string>\(app.name)</string>
                    </dict>
                </dict>
            </array>
        </dict>
        </plist>
        """
        
        let response = """
        HTTP/1.1 200 OK\r
        Content-Type: application/xml\r
        Content-Length: \(manifestXML.utf8.count)\r
        Connection: close\r
        \r
        \(manifestXML)
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func serveIPA(connection: NWConnection) {
        guard let app = currentServedApp,
              let path = app.signedIpaPath ?? (app.filePath.isEmpty ? nil : app.filePath),
              let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            serveNotFound(connection: connection)
            return
        }
        
        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: application/octet-stream\r
        Content-Length: \(fileData.count)\r
        Content-Disposition: attachment; filename="\(app.name).ipa"\r
        Connection: close\r
        \r
        """
        
        var responseData = header.data(using: .utf8)!
        responseData.append(fileData)
        
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func serveNotFound(connection: NWConnection) {
        let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
