import SwiftUI

public struct GlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var strokeOpacity: Double
    @ViewBuilder public var content: Content
    
    public init(
        cornerRadius: CGFloat = 16,
        strokeOpacity: Double = 0.12,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .frostedGlassCard(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity)
    }
}
