import SwiftUI

public struct SigningProgressBar: View {
    public var progress: Double // 0.0 -> 1.0
    public var title: String
    
    public init(progress: Double, title: String) {
        self.progress = progress
        self.title = title
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.cyan400)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 7)
                    
                    // Filled Progress
                    Capsule()
                        .fill(AppTheme.cyanGradient)
                        .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 7)
                        .animation(.easeOut(duration: 0.25), value: progress)
                        .cyanGlow(radius: 6)
                }
            }
            .frame(height: 7)
        }
    }
}
