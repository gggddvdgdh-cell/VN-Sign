import SwiftUI

public enum SignSubTab: String, CaseIterable {
    case library = "imported"
    case signed = "signed"
    
    public var title: String {
        switch self {
        case .library:
            return NSLocalizedString("subtab_imported", comment: "")
        case .signed:
            return NSLocalizedString("subtab_signed", comment: "")
        }
    }
}

public struct SignView: View {
    @ObservedObject var signingEngine = SigningEngine.shared
    @ObservedObject var localServer = LocalServer.shared
    
    @State private var activeSubTab: SignSubTab = .library
    @State private var selectedAppToSign: AppItem?
    @State private var toastMessage: ToastMessage?
    @State private var showInstallAlert: Bool = false
    @State private var appToInstall: AppItem?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    Text(NSLocalizedString("sign_title", comment: ""))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Thẻ trạng thái Server cục bộ (nếu đang chạy)
                    if localServer.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: 16/255, green: 185/255, blue: 129/255))
                                .frame(width: 6, height: 6)
                            Text("OTA Port \(localServer.serverPort)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                
                // Bộ chuyển đổi Subtab phân đoạn (Segmented Subtab Switcher)
                HStack(spacing: 0) {
                    ForEach(SignSubTab.allCases, id: \.rawValue) { subtab in
                        let isSelected = (activeSubTab == subtab)
                        Button(action: {
                            withAnimation(AppTheme.springAnimation) {
                                activeSubTab = subtab
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            HStack(spacing: 6) {
                                Text(subtab.title)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                                
                                // Badge đếm số lượng
                                let count = (subtab == .library) ? signingEngine.libraryApps.count : signingEngine.signedApps.count
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isSelected ? AppTheme.cyan400 : Color.white.opacity(0.4))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.white.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(3)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Nội dung các Subtab
                if activeSubTab == .library {
                    librarySubTabContent
                } else {
                    signedSubTabContent
                }
            }
        }
        .sheet(item: $selectedAppToSign) { app in
            SignSheetView(app: app) { newlySignedApp in
                toastMessage = ToastMessage(title: "Ký thành công!", message: "\(newlySignedApp.name) đã sẵn sàng cài đặt.")
                withAnimation(AppTheme.springAnimation) {
                    activeSubTab = .signed
                }
            }
        }
        .toast(item: $toastMessage)
        .alert(isPresented: $showInstallAlert) {
            Alert(
                title: Text(NSLocalizedString("install_prompt_title", comment: "")),
                message: Text(String(format: NSLocalizedString("install_prompt_message", comment: ""), appToInstall?.name ?? "")),
                primaryButton: .default(Text(NSLocalizedString("install_confirm", comment: "")), action: {
                    if let app = appToInstall {
                        LocalServer.shared.installAppDirectly(app)
                    }
                }),
                secondaryButton: .cancel(Text(NSLocalizedString("install_cancel", comment: "")))
            )
        }
    }
    
    // MARK: - Subviews
    
    private var librarySubTabContent: some View {
        ScrollView {
            if signingEngine.libraryApps.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Color.white.opacity(0.4))
                    Text(NSLocalizedString("sign_library_empty_title", comment: ""))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(NSLocalizedString("sign_library_empty_subtitle", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(signingEngine.libraryApps) { app in
                        LibraryAppRow(app: app) {
                            selectedAppToSign = app
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var signedSubTabContent: some View {
        ScrollView {
            if signingEngine.signedApps.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 40))
                        .foregroundColor(Color.white.opacity(0.4))
                    Text(NSLocalizedString("sign_signed_empty_title", comment: ""))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(NSLocalizedString("sign_signed_empty_subtitle", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(signingEngine.signedApps) { app in
                        SignedAppRow(
                            app: app,
                            onInstallAction: {
                                appToInstall = app
                                showInstallAlert = true
                            },
                            onShareAction: {
                                shareApp(app: app)
                            },
                            onDeleteAction: {
                                deleteSignedApp(app: app)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareApp(app: AppItem) {
        let path = app.signedIpaPath ?? app.filePath
        let fileURL = URL(fileURLWithPath: path)
        let av = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    private func deleteSignedApp(app: AppItem) {
        withAnimation(AppTheme.springAnimation) {
            signingEngine.signedApps.removeAll { $0.id == app.id }
        }
        if let path = app.signedIpaPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        toastMessage = ToastMessage(title: "Đã xoá", message: app.name)
    }
}
