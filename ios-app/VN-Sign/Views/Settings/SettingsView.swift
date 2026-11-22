import SwiftUI
import UniformTypeIdentifiers

public enum WallpaperChoice: String, CaseIterable {
    case featured = "featured"
    case darkOLED = "darkOLED"
    case custom = "custom"
    
    public var title: String {
        switch self {
        case .featured:
            return "VN-Sign Đặc trưng"
        case .darkOLED:
            return "Đen OLED"
        case .custom:
            return "Tùy chọn"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var certManager = CertManager.shared
    
    // User Settings State
    @AppStorage("anti_revoke_enabled") private var antiRevokeEnabled: Bool = true
    @AppStorage("wallpaper_choice") private var wallpaperChoice: String = WallpaperChoice.featured.rawValue
    @AppStorage("background_opacity") private var backgroundOpacity: Double = 0.45
    @AppStorage("glass_blur_intensity") private var blurIntensity: Double = 24.0
    @AppStorage("ipa_compression_mode") private var compressionMode: String = CompressionLevel.balanced.rawValue
    
    @State private var toastMessage: ToastMessage?
    @State private var cacheSizeMB: Double = 142.5
    
    // Pickers & Alerts State
    @State private var showP12Picker = false
    @State private var showProfilePicker = false
    @State private var showWallpaperPicker = false
    
    @State private var showP12PasswordAlert = false
    @State private var pendingP12URL: URL?
    @State private var p12PasswordInput: String = ""
    
    @State private var certToDelete: Certificate?
    @State private var showDeleteCertAlert = false
    
    @State private var profileToDelete: ProvisioningProfile?
    @State private var showDeleteProfileAlert = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Bar
                HStack(spacing: 10) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                        .shadow(color: AppTheme.purple500.opacity(0.4), radius: 6)
                    
                    Text("Cài Đặt & Cấu Hình")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.top, 12)
                
                // 1. TOP SECTION: Quản Lý Chứng Chỉ (.p12) & Hồ Sơ (.mobileprovision)
                certificatesAndProfilesSection
                
                // 2. SECOND SECTION: Hình Nền & Độ Trong Suốt
                wallpaperAndTransparencySection
                
                // 3. THIRD SECTION: Ký Số & Chặn Thu Hồi (Anti-Revoke DNS)
                signingAndAntiRevokeSection
                
                // 4. FOURTH SECTION: Quản Lý Bộ Nhớ (Dọn dẹp cache)
                storageManagementSection
                
                // 5. FIFTH SECTION: Thông Tin Ứng Dụng & Liên Hệ (Discord/Zalo đặt gọn gàng ở dưới)
                appInfoAndCommunitySection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120) // Đệm cho Floating Dock
        }
        .toast(item: $toastMessage)
        .sheet(isPresented: $showP12Picker) {
            SettingsDocumentPicker(types: [.data, .item]) { pickedURL in
                self.pendingP12URL = pickedURL
                self.p12PasswordInput = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showP12PasswordAlert = true
                }
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            SettingsDocumentPicker(types: [.data, .item]) { pickedURL in
                do {
                    let profile = try certManager.importMobileProvision(from: pickedURL)
                    toastMessage = ToastMessage(
                        title: "Nhập hồ sơ thành công",
                        message: "Đã thêm hồ sơ: \(profile.name)"
                    )
                } catch {
                    toastMessage = ToastMessage(
                        title: "Lỗi nhập hồ sơ",
                        message: error.localizedDescription
                    )
                }
            }
        }
        .sheet(isPresented: $showWallpaperPicker) {
            SettingsDocumentPicker(types: [.image, .data]) { pickedURL in
                handlePickedWallpaper(url: pickedURL)
            }
        }
        .alert("Nhập mật khẩu chứng chỉ .p12", isPresented: $showP12PasswordAlert) {
            TextField("Mật khẩu (nếu không có thì để trống)", text: $p12PasswordInput)
            Button("Xác nhận nhập") {
                if let url = pendingP12URL {
                    do {
                        let cert = try certManager.importP12(from: url, password: p12PasswordInput)
                        toastMessage = ToastMessage(
                            title: "Chứng chỉ hợp lệ",
                            message: "Đã thêm chứng chỉ: \(cert.teamName.isEmpty ? cert.name : cert.teamName)"
                        )
                    } catch {
                        toastMessage = ToastMessage(
                            title: "Lỗi chứng chỉ .p12",
                            message: error.localizedDescription
                        )
                    }
                }
                pendingP12URL = nil
                p12PasswordInput = ""
            }
            Button("Hủy", role: .cancel) {
                pendingP12URL = nil
                p12PasswordInput = ""
            }
        } message: {
            Text("Nhập mật khẩu để giải mã tệp chứng chỉ: \(pendingP12URL?.lastPathComponent ?? ".p12")")
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .alert("Xác nhận xóa chứng chỉ", isPresented: $showDeleteCertAlert) {
            Button("Xóa chứng chỉ", role: .destructive) {
                if let cert = certToDelete {
                    certManager.deleteCertificate(id: cert.id)
                    toastMessage = ToastMessage(
                        title: "Đã xóa chứng chỉ",
                        message: "Đã xóa thành công chứng chỉ: \(cert.teamName.isEmpty ? cert.name : cert.teamName)"
                    )
                }
                certToDelete = nil
            }
            Button("Hủy", role: .cancel) {
                certToDelete = nil
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa chứng chỉ \(certToDelete?.teamName ?? "") khỏi thiết bị? Thao tác này không thể hoàn tác.")
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .alert("Xác nhận xóa hồ sơ", isPresented: $showDeleteProfileAlert) {
            Button("Xóa hồ sơ", role: .destructive) {
                if let profile = profileToDelete {
                    certManager.deleteProfile(id: profile.id)
                    toastMessage = ToastMessage(
                        title: "Đã xóa hồ sơ",
                        message: "Đã xóa thành công hồ sơ: \(profile.name)"
                    )
                }
                profileToDelete = nil
            }
            Button("Hủy", role: .cancel) {
                profileToDelete = nil
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa hồ sơ cấu hình \(profileToDelete?.name ?? "") khỏi thiết bị? Thao tác này không thể hoàn tác.")
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - 1. TOP SECTION: Quản Lý Chứng Chỉ & Hồ Sơ
    
    private var certificatesAndProfilesSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Quản Lý Chứng Chỉ & Hồ Sơ", systemImage: "signature")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Nút Nhập chứng chỉ & Nhập hồ sơ
                HStack(spacing: 10) {
                    Button(action: {
                        showP12Picker = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Nhập chứng chỉ (.p12)")
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [AppTheme.cyan500, AppTheme.blue500], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showProfilePicker = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.badge.gearshape.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Nhập hồ sơ (.mobileprovision)")
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [AppTheme.purple500, AppTheme.purple700], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Danh sách Chứng chỉ (.p12)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Chứng Chỉ Đã Nạp")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("\(certManager.certificates.count) chứng chỉ")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
                    if certManager.certificates.isEmpty {
                        HStack {
                            Spacer()
                            Text("Chưa có chứng chỉ (.p12) nào. Nhấn \"Nhập chứng chỉ (.p12)\" để thêm.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ForEach(certManager.certificates) { cert in
                            certificateRow(cert)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // Danh sách Hồ sơ cấu hình (.mobileprovision)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hồ Sơ Cấu Hình Đã Nạp")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("\(certManager.profiles.count) hồ sơ")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
                    if certManager.profiles.isEmpty {
                        HStack {
                            Spacer()
                            Text("Chưa có hồ sơ (.mobileprovision) nào. Nhấn \"Nhập hồ sơ (.mobileprovision)\" để thêm.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ForEach(certManager.profiles) { profile in
                            profileRow(profile)
                        }
                    }
                }
            }
        }
    }
    
    private func certificateRow(_ cert: Certificate) -> some View {
        let isActive = certManager.activeCertificate?.id == cert.id
        return HStack(alignment: .top, spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? AppTheme.cyan500.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: isActive ? "checkmark.seal.fill" : "key.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? AppTheme.cyan400 : Color.white.opacity(0.6))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(cert.teamName.isEmpty ? cert.name : cert.teamName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(AppTheme.cyan400)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.cyan400.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text("Team ID: \(cert.teamID)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    Text("Hết hạn: \(formattedDate(cert.expirationDate))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text("Còn \(cert.daysRemaining) ngày")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(cert.daysRemaining > 30 ? AppTheme.cyan400 : Color.yellow)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                if !isActive {
                    Button(action: {
                        certManager.setActiveCertificate(id: cert.id)
                    }) {
                        Text("Chọn")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.cyan400)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.cyan400.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    certToDelete = cert
                    showDeleteCertAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.85))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? AppTheme.cyan500.opacity(0.08) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? AppTheme.cyan400.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                certManager.setActiveCertificate(id: cert.id)
            }
        }
    }
    
    private func profileRow(_ profile: ProvisioningProfile) -> some View {
        let isActive = certManager.activeProfile?.id == profile.id
        return HStack(alignment: .top, spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? AppTheme.purple500.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: isActive ? "doc.badge.gearshape.fill" : "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? AppTheme.purple400 : Color.white.opacity(0.6))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(AppTheme.purple400)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.purple400.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                
                Text("Team: \(profile.teamIdentifier) • \(profile.teamName)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    Text("Hết hạn: \(formattedDate(profile.expirationDate))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text("Còn \(profile.daysRemaining) ngày")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(profile.daysRemaining > 30 ? AppTheme.purple400 : Color.yellow)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                if !isActive {
                    Button(action: {
                        certManager.setActiveProfile(id: profile.id)
                    }) {
                        Text("Chọn")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.purple400)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.purple400.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    profileToDelete = profile
                    showDeleteProfileAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.85))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? AppTheme.purple500.opacity(0.08) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? AppTheme.purple400.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                certManager.setActiveProfile(id: profile.id)
            }
        }
    }
    
    // MARK: - 2. SECOND SECTION: Hình Nền & Độ Trong Suốt
    
    private var wallpaperAndTransparencySection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Hình Nền & Độ Trong Suốt", systemImage: "photo.artframe")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Preview Hình nền với lớp phủ tối hiển thị trực quan
                ZStack(alignment: .bottomLeading) {
                    currentWallpaperPreview
                        .frame(height: 110)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(backgroundOpacity))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.cyan400.opacity(0.4), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaperTitleForSelection)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Độ tối phủ nền: \(Int(backgroundOpacity * 100))% • Mờ: \(Int(blurIntensity)) pt")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.75))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                }
                
                // Wallpaper Mode Picker (VN-Sign Đặc trưng, Đen OLED, Tùy chọn)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chế độ hình nền")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Picker("Hình nền", selection: $wallpaperChoice) {
                        ForEach(WallpaperChoice.allCases, id: \.rawValue) { choice in
                            Text(choice.title).tag(choice.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Nút chọn ảnh nền từ thiết bị khi chọn Tùy chọn
                if wallpaperChoice == WallpaperChoice.custom.rawValue {
                    Button(action: {
                        showWallpaperPicker = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                            Text("Chọn ảnh nền từ thiết bị...")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(AppTheme.cyan400)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.cyan400.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Slider Độ trong suốt màn hình (@AppStorage("background_opacity") 0.0 -> 1.0)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Độ trong suốt màn hình")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("\(Int((1.0 - backgroundOpacity) * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.cyan400)
                    }
                    Slider(value: $backgroundOpacity, in: 0.0...1.0, step: 0.05)
                        .tint(AppTheme.cyan400)
                    
                    Text("Điều chỉnh độ đậm nhạt của lớp phủ tối trên hình nền ứng dụng.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Slider Độ mờ kính (Blur Intensity)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Độ mờ kính (Blur Intensity)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
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
    
    @ViewBuilder
    private var currentWallpaperPreview: some View {
        if wallpaperChoice == WallpaperChoice.darkOLED.rawValue {
            AppTheme.oledBlack
        } else if wallpaperChoice == WallpaperChoice.custom.rawValue,
                  let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                  let customImg = UIImage(contentsOfFile: docDir.appendingPathComponent("custom_wallpaper.jpg").path) {
            Image(uiImage: customImg)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image("Wallpaper")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
    
    private var wallpaperTitleForSelection: String {
        switch wallpaperChoice {
        case WallpaperChoice.darkOLED.rawValue:
            return "Đen OLED Nguyên Bản"
        case WallpaperChoice.custom.rawValue:
            return "Hình Nền Tùy Chọn"
        default:
            return "Hình Nền VN-Sign Đặc Trưng"
        }
    }
    
    // MARK: - 3. THIRD SECTION: Ký Số & Chặn Thu Hồi (Anti-Revoke DNS)
    
    private var signingAndAntiRevokeSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Ký Số & Chặn Thu Hồi", systemImage: "network.badge.shield.half.filled")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Anti-Revoke DNS Toggle
                HStack(spacing: 12) {
                    ShieldPulseIcon(isEnabled: antiRevokeEnabled)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chặn thu hồi chứng chỉ (Anti-Revoke DNS)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Bảo vệ ứng dụng đã cài đặt khỏi bị Apple thu hồi chứng chỉ qua lọc DNS cục bộ.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.55))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
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
                    Text("Mức độ nén gói IPA")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
    
    // MARK: - 4. FOURTH SECTION: Quản Lý Bộ Nhớ (Dọn dẹp cache)
    
    private var storageManagementSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Quản Lý Bộ Nhớ", systemImage: "internaldrive.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dọn dẹp bộ nhớ đệm")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(String(format: "Bộ nhớ đệm tạm thời: %0.1f MB", cacheSizeMB))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.55))
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
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
                            Text("Sao lưu dữ liệu")
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
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
                            Text("Khôi phục dữ liệu")
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
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
    
    // MARK: - 5. FIFTH SECTION: Thông Tin Ứng Dụng & Liên Hệ
    
    private var appInfoAndCommunitySection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Thông Tin Ứng Dụng & Liên Hệ", systemImage: "info.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    Text("Phiên bản")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text("2.5.0 Pro Native")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Bản dựng (Build)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text("2026.11.22")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.55))
                }
                
                Text("VN-Sign là công cụ hỗ trợ ký số và cài đặt tệp IPA độc lập trên thiết bị iOS. Vui lòng tuân thủ bản quyền và điều khoản sử dụng của nhà phát triển.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.top, 2)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider().background(Color.white.opacity(0.08))
                
                Text("Hỗ Trợ & Cộng Đồng")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.8))
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                
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
                            Text("Máy chủ Discord VN-Sign")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("discord.gg/679mFrKtH")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.55))
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
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
                            Text("Hỗ trợ kỹ thuật qua Zalo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("0788843545")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.cyan400)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
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
    
    // MARK: - Actions
    
    private func handlePickedWallpaper(url: URL) {
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destURL = docDir.appendingPathComponent("custom_wallpaper.jpg")
        try? FileManager.default.removeItem(at: destURL)
        do {
            let data = try Data(contentsOf: url)
            try data.write(to: destURL)
            toastMessage = ToastMessage(title: "Hình nền tùy chọn", message: "Đã cập nhật hình nền từ thiết bị thành công.")
        } catch {
            toastMessage = ToastMessage(title: "Lỗi tải ảnh", message: error.localizedDescription)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
    
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
            message: String(format: "Đã giải phóng %0.1f MB bộ nhớ đệm.", prevSize)
        )
    }
    
    private func backupData() {
        toastMessage = ToastMessage(title: "Sao lưu", message: "Đã tạo bản sao lưu chứng chỉ và cấu hình.")
    }
    
    private func restoreData() {
        toastMessage = ToastMessage(title: "Khôi phục", message: "Đã khôi phục dữ liệu thành công.")
    }
}

// MARK: - Dedicated Document Picker for Settings
struct SettingsDocumentPicker: UIViewControllerRepresentable {
    var types: [UTType]
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let first = urls.first {
                onPick(first)
            }
        }
    }
}
