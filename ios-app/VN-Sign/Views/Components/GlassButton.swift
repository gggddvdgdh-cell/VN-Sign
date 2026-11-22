import SwiftUI

public struct GlassButton: View {
    public var title: String
    public var systemIcon: String?
    public var isAccent: Bool
    public var action: () -> Void
    
    public init(
        title: String,
        systemIcon: String? = nil,
        isAccent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemIcon = systemIcon
        self.isAccent = isAccent
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = systemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isAccent ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isAccent
                        ? AnyShapeStyle(AppTheme.cyanGradient)
                        : AnyShapeStyle(Color.white.opacity(0.10))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAccent ? AppTheme.cyan400 : Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.fastSpring, value: configuration.isPressed)
    }
}
