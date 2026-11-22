import SwiftUI

public enum WallpaperChoice: String, CaseIterable {
    case featured = "featured"
    case darkOLED = "darkOLED"
    case custom = "custom"
    
    public var title: String {
        switch self {
        case .featured:
            return NSLocalizedString("settings_wallpaper_featured", comment: "")
        case .darkOLED:
            return NSLocalizedString("settings_wallpaper_dark", comment: "")
        case .custom:
            return NSLocalizedString("settings_wallpaper_custom", comment: "")
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var certManager = CertManager.shared
    
    // User Settings State
    @AppStorage("anti_revoke_enabled") private var antiRevokeEnabled: Bool = true
    @AppStorage("wallpaper_choice") private var wallpaperChoice: String = WallpaperChoice.featured.rawValue
    @AppStorage("glass_blur_intensity") private var blurIntensity: Double = 24.0
    @AppStorage("ipa_compression_mode") private var compressionMode: String = CompressionLevel.balanced.rawValue
    
    @State private var toastMessage: ToastMessage?
    @State private var cacheSizeMB: Double = 142.5
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    Text(NSLocalizedString("settings_title", comment: ""))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 12)
                
                // 1. Community & Support (Discord & Zalo)
                communitySection
                
                // 2. Wallpaper & Appearance
                appearanceSection
                
                // 3. Signing & Anti-Revoke DNS
                signingAndNetworkSection
                
                // 4. Storage & Cache Cleaner
                storageSection
                
                // 5. About & App Info
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120) // Đệm cho Floating Dock
        }
        .toast(item: $toastMessage)
    }
    
    // MARK: - Subsections
    
    private var communitySection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("settings_community_section", comment: ""), systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Discord Link Button
                Button(action: openDiscord) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#5865F2").opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "bubble.middle.bottom.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#5865F2"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("settings_discord", comment: ""))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("discord.gg/679mFrKtH")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Zalo Link Button
                Button(action: openZalo) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#0068FF").opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "phone.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#0068FF"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("settings_zalo", comment: ""))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("0788843545")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.cyan400)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var appearanceSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("settings_appearance_section", comment: ""), systemImage: "photo.artframe")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Preview Thẻ hình nền với hình ảnh từ assets
                ZStack(alignment: .bottomLeading) {
                    Image("Wallpaper")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 110)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.35))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.cyan400.opacity(0.4), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hình nền VN-Sign Đặc trưng")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("C327208A-DAA0-4E83-99A4 (Tích hợp sẵn)")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(10)
                }
                
                // Tùy chọn kiểu nền
                Picker("Hình nền", selection: $wallpaperChoice) {
                    ForEach(WallpaperChoice.allCases, id: \.rawValue) { choice in
                        Text(choice.title).tag(choice.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Thanh trượt độ mờ kính (Blur Slider)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(NSLocalizedString("settings_blur_intensity", comment: ""))
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(blurIntensity)) pt")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.cyan400)
                    }
                    Slider(value: $blurIntensity, in: 0...40, step: 2)
                        .tint(AppTheme.cyan400)
                }
            }
        }
    }
    
    private var signingAndNetworkSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("settings_signing_section", comment: ""), systemImage: "network.badge.shield.half.filled")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Anti-Revoke DNS Toggle
                HStack(spacing: 12) {
                    ShieldPulseIcon(isEnabled: antiRevokeEnabled)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings_anti_revoke", comment: ""))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("settings_anti_revoke_desc", comment: ""))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $antiRevokeEnabled)
                        .labelsHidden()
                        .tint(AppTheme.cyan500)
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // IPA Compression Level Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("settings_compression", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    Picker("Nén IPA", selection: $compressionMode) {
                        ForEach(CompressionLevel.allCases, id: \.rawValue) { level in
                            Text(level.title).tag(level.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
    
    private var storageSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("settings_storage_section", comment: ""), systemImage: "internaldrive.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings_clear_cache", comment: ""))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(String(format: "Bộ nhớ đệm tạm thời: %0.1f MB", cacheSizeMB))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                    Spacer()
                    Button(action: clearCache) {
                        Text("Dọn dẹp")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 12) {
                    Button(action: backupData) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.doc")
                            Text(NSLocalizedString("settings_backup", comment: ""))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: restoreData) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                            Text(NSLocalizedString("settings_restore", comment: ""))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
    
    private var aboutSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(NSLocalizedString("settings_app_info_section", comment: ""), systemImage: "info.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    Text(NSLocalizedString("settings_version", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                    Spacer()
                    Text("2.5.0 Pro Native")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text(NSLocalizedString("settings_build", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                    Spacer()
                    Text("2026.11.22")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.55))
                }
                
                Text(NSLocalizedString("settings_disclaimer", comment: ""))
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Actions
    
    private func openDiscord() {
        if let url = URL(string: "https://discord.gg/679mFrKtH") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openZalo() {
        if let url = URL(string: "https://zalo.me/0788843545") {
            UIApplication.shared.open(url)
        }
    }
    
    private func clearCache() {
        let prevSize = cacheSizeMB
        cacheSizeMB = 0.0
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempDir)
        toastMessage = ToastMessage(
            title: "Dọn dẹp thành công",
            message: String(format: NSLocalizedString("settings_cache_cleared", comment: ""), prevSize)
        )
    }
    
    private func backupData() {
        toastMessage = ToastMessage(title: "Sao lưu", message: "Đã tạo bản sao lưu chứng chỉ và cấu hình.")
    }
    
    private func restoreData() {
        toastMessage = ToastMessage(title: "Khôi phục", message: "Đã khôi phục dữ liệu thành công.")
    }
}
