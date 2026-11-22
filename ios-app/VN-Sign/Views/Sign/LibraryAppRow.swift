import SwiftUI

public struct LibraryAppRow: View {
    public var app: AppItem
    public var onSignTapped: () -> Void
    
    public init(app: AppItem, onSignTapped: @escaping () -> Void) {
        self.app = app
        self.onSignTapped = onSignTapped
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "app.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppTheme.cyan400)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            
            // App Details
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(app.bundleIdentifier)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("v\(app.version)")
                        .font(.system(size: 11, weight: .semibold))
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
            
            // Nút Ký gọn gàng với Pen Morphicon (Compact in-row signing button)
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSignTapped()
            }) {
                HStack(spacing: 5) {
                    PenMorphIcon(tintColor: .black, size: 15)
                    
                    Text(NSLocalizedString("sign_btn_sign", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.cyanGradient)
                .clipShape(Capsule())
                .cyanGlow(radius: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .frostedGlassCard(cornerRadius: 16, strokeOpacity: 0.12)
    }
}
