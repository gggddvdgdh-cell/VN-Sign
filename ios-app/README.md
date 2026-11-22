# VN-Sign Pro - Native iOS Application (Swift & SwiftUI)

Ứng dụng ký số IPA trực tiếp trên thiết bị iOS (On-Device IPA Signing Tool), thiết kế chuẩn **Dark OLED Glassmorphism** (.ultraThinMaterial), tích hợp **Morphicons vector animation**, bộ ký mã nhị phân **Mach-O**, tiêm dylib, và máy chủ OTA nội bộ (`itms-services://`).

---

## 🌟 Tính Năng Nổi Bật

1. **Giao Diện Dark OLED Glassmorphic (.ultraThinMaterial)**:
   - Tối ưu cho màn hình Super Retina XDR OLED (màu đen sâu, viền kính siêu mỏng, bóng mờ khuếch tán).
   - Tích hợp hình nền đặc trưng người dùng từ `D:\VN-Sign\nền app VN-Sign` vào asset catalog kèm thanh trượt điều chỉnh độ mờ kính mượt mà.
   - Thanh Dock nổi (Floating Dock Bar) với con trượt chỉ báo mềm mại (`SlidingDock.swift`) áp dụng vật lý lò xo Apple SF Spring (`response: 0.36, dampingFraction: 0.72`).

2. **Hệ Thống Morphicons (Animated Morphing Vector Icons)**:
   - **PenMorphIcon**: Biểu tượng ngòi bút nghiêng và nét ký uốn lượn chuyển động sống động.
   - **FolderMorphIcon**: Hoạt ảnh mở nắp thư mục và trồi tài liệu khi chọn tab Tệp.
   - **GearMorphIcon**: Bánh răng xoay góc mượt mà khi tương tác cài đặt.
   - **CheckmarkMorphIcon**: Nét vẽ dấu tích hoàn thành chuyển động sau khi ký thành công.
   - **ShieldPulseIcon**: Khiên bảo vệ xung nhịp phát sáng cho tính năng Anti-Revoke DNS.

3. **Động Cơ Ký Số Trực Tiếp Trên Thiết Bị (On-Device Signing Engine)**:
   - **`CertManager.swift`**:
     * Phân tích tệp chứng chỉ thực tế `.p12` qua `SecPKCS12Import`, trích xuất Common Name, Team ID, Organization, Expiration Date, SHA-1 fingerprint.
     * Phân tích tệp `.mobileprovision` trích xuất XML plist từ CMS container: UUID, TeamIdentifier, Entitlements (Wildcard `*`, application-identifier, keychain-access-groups), ProvisionedDevices.
   - **`MachOParser.swift`**:
     * Đọc và phân tích cấu trúc nhị phân 64-bit Mach-O (ARM64) và Universal Fat Binary: `mach_header_64`, `load_command`, `LC_SEGMENT_64`, `__LINKEDIT`, `LC_CODE_SIGNATURE`.
   - **`DylibInjector.swift`**:
     * Tiêm dylib vào ứng dụng bằng cách chèn `LC_LOAD_DYLIB` vào khoảng đệm header của binary Mach-O và sao chép vào `Frameworks/`.
   - **`CodeSigner.swift`**:
     * Tạo cây mã băm `_CodeSignature/CodeResources` (SHA-1 / SHA-256) cho tất cả tài nguyên trong app bundle.
     * Xây dựng SuperBlob: `CodeDirectory` (CSMAGIC_CODEDIRECTORY), `Entitlements` (CSMAGIC_EMBEDDED_ENTITLEMENTS), và `CMS Signature` (CSMAGIC_BLOBWRAPPER).
     * Niêm phong và cập nhật `LC_CODE_SIGNATURE` trong Mach-O.
   - **`ZipArchiveManager.swift`**:
     * Giải nén và đóng gói tái cấu trúc file IPA với các mức nén: Nhanh (Store), Cân bằng, Tối đa (Ultra).
   - **`LocalServer.swift`**:
     * Máy chủ HTTPS/HTTP daemon chạy ngầm bằng `NWListener` (`Network.framework`).
     * Phục vụ `manifest.plist` và stream IPA file qua giao thức `itms-services://?action=download-manifest&url=...` để người dùng cài đặt ứng dụng trực tiếp bằng 1 chạm mà không cần qua máy tính!

4. **Cấu Trúc Màn Hình & Trải Nghiệm**:
   - **`FileListView.swift`**: Trình quản lý tệp E-Sign: nút (+) nhập file IPA, P12, Mobileprovision, Dylib qua `UIDocumentPickerViewController`; menu (...) với chế độ chọn nhiều (multi-select), sắp xếp theo tên/ngày/kích thước, và vuốt swipe xóa/chia sẻ/ký nhanh.
   - **`SignView.swift`**: 2 subtab gồm:
     * *App thư viện*: Danh sách ứng dụng kèm nút ký dạng viên thuốc nhỏ gọn tích hợp Pen Morphicon.
     * *App đã ký*: Danh sách ứng dụng đã ký thành công kèm nút cài đặt trực tiếp qua LocalServer, chia sẻ AirDrop và xoá.
   - **`SignSheetView.swift`**: Modal kính mờ hiển thị thông tin ứng dụng, chứng chỉ, thiết bị (UIDevice model & iOS version), tùy chọn nâng cao (Custom App Name, Custom Bundle ID, Inject Dylib, Remove Limits, File Sharing) và nút Ký ngay với hiệu ứng tiến trình 4 giai đoạn.
   - **`SettingsView.swift`**: Cài đặt toàn diện:
     * Mục liên hệ: Discord (`https://discord.gg/679mFrKtH`), Zalo CSKH (`0788843545`).
     * Tùy biến hình nền (Hình nền Featured từ `nền app VN-Sign`, OLED Đen nguyên bản, tùy chỉnh).
     * Anti-Revoke DNS chặn máy chủ thu hồi chứng chỉ Apple.
     * Chế độ nén IPA (Store / Balanced / Ultra).
     * Dọn dẹp cache và Sao lưu/Khôi phục.

5. **Đa Ngôn Ngữ & Cấu Hình**:
   - Đầy đủ ngôn ngữ Tiếng Việt (`vi.lproj/Localizable.strings`) và Tiếng Anh (`en.lproj/Localizable.strings`).
   - `Info.plist` tích hợp sẵn `UISupportsDocumentBrowser = YES`, `UIFileSharingEnabled = YES`, `LSSupportsOpeningDocumentsInPlace = YES`, định nghĩa `CFBundleDocumentTypes` cho `.ipa`, `.p12`, `.mobileprovision`, `.dylib`.
   - Tương thích Xcode 14/15/16, iOS 16.0+, macOS Catalyst, Swift 5.9+.

---

## 📁 Cấu Trúc Thư Mục Dự Án

```
d:\VN-Sign\ios-app
├── Package.swift                             # Swift Package Manager manifest
├── VN-Sign.xcodeproj/
│   └── project.pbxproj                       # Xcode Project Configuration
├── VN-Sign/
│   ├── Info.plist                            # App permissions & Document Types
│   ├── App/
│   │   ├── VNSignApp.swift                   # SwiftUI @main entry
│   │   └── AppDelegate.swift                 # Document opening & Lifecycle
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/           # Icon ứng dụng 1024x1024
│   │   │   └── Wallpaper.imageset/           # Hình nền đặc trưng người dùng
│   │   ├── vi.lproj/Localizable.strings      # Bản địa hóa Tiếng Việt
│   │   └── en.lproj/Localizable.strings      # Bản địa hóa Tiếng Anh
│   ├── Models/
│   │   ├── Certificate.swift                 # Mô hình chứng chỉ .p12
│   │   ├── ProvisioningProfile.swift         # Mô hình hồ sơ .mobileprovision
│   │   ├── AppItem.swift                     # Mô hình ứng dụng thư viện/đã ký
│   │   ├── FileItem.swift                    # Mô hình tệp tin quản lý
│   │   └── SignConfig.swift                  # Mô hình cấu hình phiên ký
│   ├── Services/
│   │   ├── CertManager.swift                 # Xử lý nhập & giải mã .p12 / profile
│   │   ├── SigningEngine.swift               # Động cơ ký 4 giai đoạn
│   │   ├── MachOParser.swift                 # Phân tích binary ARM64 Mach-O
│   │   ├── CodeSigner.swift                  # Tạo SuperBlob & LC_CODE_SIGNATURE
│   │   ├── DylibInjector.swift               # Tiêm dylib vào load commands
│   │   ├── ZipArchiveManager.swift           # Giải nén & đóng gói IPA
│   │   └── LocalServer.swift                 # Máy chủ OTA itms-services daemon
│   ├── Views/
│   │   ├── MainTabView.swift                 # Màn hình chính & chuyển đổi tab
│   │   ├── Files/
│   │   │   ├── FileListView.swift            # Quản lý tệp, menu, chọn nhiều
│   │   │   └── FileRowView.swift             # Dòng hiển thị tệp tin & swipe
│   │   ├── Sign/
│   │   │   ├── SignView.swift                # 2 Subtab thư viện và đã ký
│   │   │   ├── LibraryAppRow.swift           # Dòng app thư viện + Pen Morphicon
│   │   │   ├── SignedAppRow.swift            # Dòng app đã ký + nút Cài đặt OTA
│   │   │   └── SignSheetView.swift           # Modal kính mờ cấu hình ký
│   │   ├── Settings/
│   │   │   └── SettingsView.swift            # Discord, Zalo, Wallpaper, DNS
│   │   └── Components/
│   │       ├── GlassCard.swift               # Thẻ kính mờ .ultraThinMaterial
│   │       ├── GlassButton.swift             # Nút kính tương tác haptic
│   │       ├── MorphingIcons.swift           # Pen, Folder, Gear, Checkmark, Shield
│   │       ├── SlidingDock.swift             # Thanh dock nổi với con trượt
│   │       ├── ProgressBar.swift             # Thanh tiến trình ký đa sắc
│   │       └── ToastView.swift               # Thông báo nổi tự động đóng
│   └── Utilities/
│       ├── Theme.swift                       # Bảng màu OLED & hiệu ứng lò xo
│       ├── DeviceInfo.swift                  # Nhận diện dòng iPhone & iOS
│       └── Extensions.swift                  # Tiện ích mở rộng SwiftUI & Color
└── README.md
```

---

## 🛠 Hướng Dẫn Biên Dịch & Chạy

### 1. Mở bằng Xcode trên macOS:
- Nhấp đúp vào `VN-Sign.xcodeproj` hoặc kéo cả thư mục `ios-app` vào Xcode.
- Chọn thiết bị mục tiêu (iPhone 16 Pro hoặc thiết bị iOS thật của bạn).
- Nhấn `Cmd + R` để Build & Run.

### 2. Biên dịch bằng dòng lệnh (xcodebuild):
```bash
xcodebuild -project VN-Sign.xcodeproj -scheme VN-Sign -destination 'generic/platform=iOS' clean build
```

### 3. Mở dưới dạng Swift Package:
- Mở Xcode -> `File` -> `Open...` -> Chọn thư mục `ios-app` (chứa `Package.swift`).
