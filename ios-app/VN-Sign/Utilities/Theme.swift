import SwiftUI

/// Hệ thống màu sắc và giao diện chuẩn Dark OLED Glassmorphic của VN-Sign Pro
public enum AppTheme {
    // Màu nền OLED nguyên bản
    public static let oledBlack = Color(red: 0.0, green: 0.0, blue: 0.0)
    public static let slate950 = Color(red: 5/255, green: 7/255, blue: 14/255)
    public static let slate900 = Color(red: 11/255, green: 15/255, blue: 25/255)
    public static let slate800 = Color(red: 23/255, green: 30/255, blue: 46/255)
    
    // Màu điểm nhấn Cyan hiện đại
    public static let cyan500 = Color(red: 6/255, green: 182/255, blue: 212/255)
    public static let cyan400 = Color(red: 34/255, green: 211/255, blue: 238/255)
    public static let cyan600 = Color(red: 8/255, green: 145/255, blue: 178/255)
    
    // Màu kính mờ (Frosted Glass)
    public static let glassFill = Color.white.opacity(0.06)
    public static let glassFillPressed = Color.white.opacity(0.12)
    public static let glassBorder = Color.white.opacity(0.12)
    public static let glassBorderActive = Color(red: 34/255, green: 211/255, blue: 238/255).opacity(0.4)
    
    // Gradient ánh sáng
    public static let cyanGradient = LinearGradient(
        colors: [Color(red: 6/255, green: 182/255, blue: 212/255), Color(red: 14/255, green: 165/255, blue: 233/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let darkSurfaceGradient = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Hiệu ứng lò xo chuyển động mượt mà
    public static let springAnimation = Animation.spring(response: 0.36, dampingFraction: 0.72)
    public static let fastSpring = Animation.spring(response: 0.25, dampingFraction: 0.70)
}
