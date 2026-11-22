import SwiftUI

public struct SignSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var certManager = CertManager.shared
    @ObservedObject var signingEngine = SigningEngine.shared
    
    public var app: AppItem
    public var onSignCompleted: ((AppItem) -> Void)?
    
    // Tùy chọn nâng cao
    @State private var customAppName: String = ""
    @State private var customBundleID: String = ""
    @State private var injectDylib: Bool = true
    @State private var selectedDylibName: String = "Rocket.dylib"
    @State private var removeLimits: Bool = true
    @State private var fileSharing: Bool = true
    @State private var compressionLevel: CompressionLevel = .balanced
    
    // Trạng thái tiến trình ký
    @State private var isExecuting: Bool = false
    @State private var signProgress: Double = 0.0
    @State private var stageText: String = ""
    @State private var isSuccess: Bool = false
    @State private var errorMessage: String?
    
    public init(app: AppItem, onSignCompleted: ((AppItem) -> Void)? = nil) {
        self.app = app
        self.onSignCompleted = onSignCompleted
    }
    
    public var body: some View {
        ZStack {
            // Nền tối OLED Kính mờ
            AppTheme.slate950
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Sheet
                sheetHeader
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. App Info Card
                        appInfoSection
                        
                        // 2. Certificate & Profile Info Card
                        certProfileSection
                        
                        // 3. Device Info Card (UIDevice Model & iOS Version)
                        deviceInfoSection
                        
                        // 4. Advanced Options Card
                        advancedOptionsSection
                        
                        // 5. Signing Progress / Action Area
                        signingActionArea
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sheetHeader: some View {
        VStack(spacing: 8) {
            // Thanh gạt (Drag Handle)
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            HStack {
                Text(NSLocalizedString("modal_title", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }
    
    private var appInfoSection: some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    
                    Image(systemName: "app.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.cyan400)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(app.bundleIdentifier)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.55))
                    
                    HStack(spacing: 8) {
                        Text("Phiên bản: \(app.version)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.cyan400)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.3))
                        
                        Text(app.formattedSize)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var certProfileSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(NSLocalizedString("modal_cert_section", comment: ""), systemImage: "signature")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.cyan400)
                    
                    Spacer()
                    
                    Text(certManager.activeCertificate?.isValid == true ? "Còn hiệu lực" : "Cần cấu hình")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // Chi tiết chứng chỉ
                if let cert = certManager.activeCertificate {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cert.teamName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Team ID: \(cert.teamID)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: NSLocalizedString("modal_cert_days_left", comment: ""), cert.daysRemaining))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.cyan400)
                            Text("Apple Enterprise")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
                
                // Chi tiết hồ sơ cấu hình
                if let profile = certManager.activeProfile {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.85))
                            Text("UUID: \(profile.uuid.prefix(12))...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                        Spacer()
                        if profile.isWildcard {
                            Text("Wildcard (*)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    private var deviceInfoSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Label(NSLocalizedString("modal_device_section", comment: ""), systemImage: "iphone")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DeviceInfo.shared.modelName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("iOS \(DeviceInfo.shared.systemVersion)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("UDID Thiết bị")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.45))
                        Text(DeviceInfo.shared.deviceUDID.prefix(16) + "...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AppTheme.cyan400)
                    }
                }
            }
        }
    }
    
    private var advancedOptionsSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("modal_advanced_section", comment: ""), systemImage: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Custom App Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("modal_app_name", comment: ""))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                    TextField(NSLocalizedString("modal_custom_name_placeholder", comment: ""), text: $customAppName)
                        .font(.system(size: 13))
                        .padding(9)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Custom Bundle ID
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("modal_bundle_id", comment: ""))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                    TextField(NSLocalizedString("modal_custom_bundle_placeholder", comment: ""), text: $customBundleID)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(9)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Toggles
                Toggle(isOn: $injectDylib) {
                    HStack {
                        Text(NSLocalizedString("modal_inject_dylib", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        if injectDylib {
                            Text("(\(selectedDylibName))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.cyan400)
                        }
                    }
                }
                .tint(AppTheme.cyan500)
                
                Toggle(isOn: $removeLimits) {
                    Text(NSLocalizedString("modal_remove_limits", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .tint(AppTheme.cyan500)
                
                Toggle(isOn: $fileSharing) {
                    Text(NSLocalizedString("modal_file_sharing", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .tint(AppTheme.cyan500)
            }
        }
    }
    
    private var signingActionArea: some View {
        VStack(spacing: 12) {
            if isExecuting {
                VStack(spacing: 10) {
                    SigningProgressBar(progress: signProgress, title: stageText)
                    
                    Text("Vui lòng giữ ứng dụng mở trong quá trình ký...")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(14)
                .frostedGlassCard(cornerRadius: 14)
            } else if isSuccess {
                HStack(spacing: 10) {
                    CheckmarkMorphIcon(size: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("modal_action_success", comment: ""))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                        Text("Ứng dụng đã được thêm vào mục 'App đã ký'.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(14)
                .frostedGlassCard(cornerRadius: 14, strokeOpacity: 0.3)
            } else {
                Button(action: startSigning) {
                    HStack(spacing: 8) {
                        PenMorphIcon(tintColor: .black, size: 18)
                        Text(NSLocalizedString("modal_action_start_sign", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.cyanGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .cyanGlow(radius: 8)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    
    private func startSigning() {
        isExecuting = true
        isSuccess = false
        signProgress = 0.05
        stageText = NSLocalizedString("step_extract", comment: "")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        Task {
            let config = SignConfig(
                appItem: app,
                certificate: certManager.activeCertificate,
                provisioningProfile: certManager.activeProfile,
                customAppName: customAppName,
                customBundleIdentifier: customBundleID,
                injectDylibURL: injectDylib ? URL(fileURLWithPath: "d:\\VN-Sign\\Rocket.dylib") : nil,
                removeDeviceLimits: removeLimits,
                enableFileSharing: fileSharing,
                compressionLevel: compressionLevel
            )
            
            // Giả lập trực quan 4 bước chuyển động mượt mà
            withAnimation(.easeInOut(duration: 0.6)) {
                signProgress = 0.25
                stageText = NSLocalizedString("step_extract", comment: "")
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            withAnimation(.easeInOut(duration: 0.6)) {
                signProgress = 0.50
                stageText = NSLocalizedString("step_inject", comment: "")
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            withAnimation(.easeInOut(duration: 0.6)) {
                signProgress = 0.85
                stageText = NSLocalizedString("step_codesign", comment: "")
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            withAnimation(.easeInOut(duration: 0.4)) {
                signProgress = 1.0
                stageText = NSLocalizedString("step_package", comment: "")
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            do {
                let signedApp = try await signingEngine.sign(config: config)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                await MainActor.run {
                    isExecuting = false
                    isSuccess = true
                    onSignCompleted?(signedApp)
                    
                    // Tự động đóng sheet sau 1.5s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isExecuting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
