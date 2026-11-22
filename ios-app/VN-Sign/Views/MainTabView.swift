import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .sign // Mặc định mở tab Ký ứng dụng
    @AppStorage("wallpaper_choice") private var wallpaperChoice: String = WallpaperChoice.featured.rawValue
    @AppStorage("glass_blur_intensity") private var blurIntensity: Double = 24.0
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Nền hình nền ứng dụng với lớp phủ kính mờ tuỳ biến
            backgroundLayer
                .ignoresSafeArea()
            
            // Nội dung tab đang chọn
            Group {
                switch selectedTab {
                case .files:
                    FileListView()
                case .sign:
                    SignView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Thanh Dock nổi phía dưới với con trượt chỉ báo chuyển tab mượt mà
            SlidingDock(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        if wallpaperChoice == WallpaperChoice.darkOLED.rawValue {
            AppTheme.oledBlack
        } else {
            ZStack {
                // Hình nền đặc trưng người dùng
                Image("Wallpaper")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                // Lớp kính mờ điều chỉnh được
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(min(1.0, blurIntensity / 30.0))
                
                // Lớp phủ tối OLED để chữ và thẻ kính nổi bật sắc nét
                Color.black.opacity(0.45)
            }
        }
    }
}
