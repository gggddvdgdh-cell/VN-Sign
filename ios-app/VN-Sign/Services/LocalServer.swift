import Foundation
import Network
import UIKit

/// Máy chủ HTTPS / HTTP cục bộ phục vụ giao thức itms-services:// để cài đặt trực tiếp không qua máy tính
public final class LocalServer: ObservableObject {
    public static let shared = LocalServer()
    
    @Published public var isRunning: Bool = false
    @Published public var serverPort: UInt16 = 8080
    @Published public var statusMessage: String = "Sẵn sàng"
    
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.vnsign.localserver.queue")
    private var currentServedApp: AppItem?
    
    private init() {}
    
    // MARK: - Start / Stop Server
    
    /// Khởi động máy chủ cục bộ trên cổng chỉ định
    public func startServer(port: UInt16 = 8080) throws {
        guard !isRunning else { return }
        
        self.serverPort = port
        let parameters = NWParameters.tcp
        
        let nwPort = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(rawValue: 8080)!
        self.listener = try NWListener(using: parameters, on: nwPort)
        
        self.listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        self.listener?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isRunning = true
                    self?.statusMessage = "Máy chủ OTA đang chạy trên cổng \(port)"
                case .failed(let error):
                    self?.isRunning = false
                    self?.statusMessage = "Lỗi máy chủ: \(error.localizedDescription)"
                case .cancelled:
                    self?.isRunning = false
                    self?.statusMessage = "Máy chủ đã dừng"
                default:
                    break
                }
            }
        }
        
        self.listener?.start(queue: queue)
    }
    
    /// Dừng máy chủ cục bộ
    public func stopServer() {
        listener?.cancel()
        listener = nil
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusMessage = "Đã dừng"
        }
    }
    
    // MARK: - Direct Installation Action
    
    /// Bắt đầu quy trình cài đặt OTA trực tiếp cho ứng dụng đã ký
    @MainActor
    public func installAppDirectly(_ app: AppItem) {
        self.currentServedApp = app
        
        if !isRunning {
            try? startServer(port: self.serverPort)
        }
        
        // Tạo manifest URL
        let localIP = getWiFiAddress() ?? "127.0.0.1"
        let manifestEndpoint = "http://\(localIP):\(serverPort)/manifest.plist"
        guard let encodedManifest = manifestEndpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let itmsURL = URL(string: "itms-services://?action=download-manifest&url=\(encodedManifest)") else {
            return
        }
        
        // Mở itms-services:// để iOS tải và cài đặt
        UIApplication.shared.open(itmsURL, options: [:]) { success in
            if success {
                print("[LocalServer] Đã mở yêu cầu cài đặt itms-services thành công!")
            } else {
                print("[LocalServer] Không thể mở URL itms-services.")
            }
        }
    }
    
    // MARK: - HTTP Request Handling
    
    private func handleConnection(_ connection: NWConnection) {
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
            
            if path.contains("manifest.plist") {
                self.serveManifest(connection: connection)
            } else if path.contains("download.ipa") {
                self.serveIPA(connection: connection)
            } else {
                self.serveNotFound(connection: connection)
            }
        }
    }
    
    private func serveManifest(connection: NWConnection) {
        let app = currentServedApp ?? AppItem(
            name: "VN-Sign App",
            bundleIdentifier: "com.vnsign.app",
            version: "1.0",
            filePath: "",
            originalIpaPath: ""
        )
        
        let localIP = getWiFiAddress() ?? "127.0.0.1"
        let downloadURL = "http://\(localIP):\(serverPort)/download.ipa"
        
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
    
    // MARK: - Device IP Resolution
    
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "lo0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    if name == "en0" { break } // Ưu tiên Wi-Fi en0
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}
