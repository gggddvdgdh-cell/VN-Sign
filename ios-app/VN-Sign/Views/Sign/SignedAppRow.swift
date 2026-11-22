import SwiftUI

public struct SignedAppRow: View {
    public var app: AppItem
    public var onInstallAction: () -> Void
    public var onShareAction: () -> Void
    public var onDeleteAction: () -> Void
    
    public init(
        app: AppItem,
        onInstallAction: @escaping () -> Void,
        onShareAction: @escaping () -> Void,
        onDeleteAction: @escaping () -> Void
    ) {
        self.app = app
        self.onInstallAction = onInstallAction
        self.onShareAction = onShareAction
        self.onDeleteAction = onDeleteAction
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // App Icon với huy hiệu dấu tích xanh
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    
                    Image(systemName: "app.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppTheme.cyan400)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                        .background(Circle().fill(.black))
                        .offset(x: 4, y: 4)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(app.bundleIdentifier)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(app.teamName ?? "VNSIGN PRO")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.cyan400)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.cyan500.opacity(0.15))
                            .clipShape(Capsule())
                        
                        Text(app.formattedSize)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Hàng nút tương tác: Cài đặt, Chia sẻ, Xoá
            HStack(spacing: 8) {
                // Nút Cài đặt trực tiếp (LocalServer itms-services)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onInstallAction()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(NSLocalizedString("sign_btn_install", comment: ""))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.cyanGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .cyanGlow(radius: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Nút Chia sẻ
                Button(action: onShareAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                        Text(NSLocalizedString("sign_btn_share", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Nút Xoá
                Button(action: onDeleteAction) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(14)
        .frostedGlassCard(cornerRadius: 16, strokeOpacity: 0.15)
    }
}
