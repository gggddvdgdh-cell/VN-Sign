import SwiftUI

public enum AppTab: Int, CaseIterable {
    case files = 0
    case sign = 1
    case settings = 2
    
    public var title: String {
        switch self {
        case .files:
            return NSLocalizedString("tab_files", comment: "")
        case .sign:
            return NSLocalizedString("tab_sign", comment: "")
        case .settings:
            return NSLocalizedString("tab_settings", comment: "")
        }
    }
}

/// Thanh dock nổi phía dưới màn hình với con trượt chỉ báo mềm mại (Floating Dock Bar with Sliding Pill)
public struct SlidingDock: View {
    @Binding public var selectedTab: AppTab
    
    public init(selectedTab: Binding<AppTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    withAnimation(AppTheme.springAnimation) {
                        selectedTab = tab
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    VStack(spacing: 3) {
                        tabIcon(for: tab)
                            .frame(height: 22)
                        
                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? AppTheme.cyan400 : Color.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            ZStack(alignment: .leading) {
                // Nền kính mờ .ultraThinMaterial
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                // Con trượt chỉ báo sáng chuyển động (Sliding Pill Indicator)
                GeometryReader { geo in
                    let tabWidth = (geo.size.width - 12) / CGFloat(AppTab.allCases.count)
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(AppTheme.cyan400.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: tabWidth, height: geo.size.height - 8)
                        .offset(x: 6 + CGFloat(selectedTab.rawValue) * tabWidth, y: 4)
                        .animation(AppTheme.springAnimation, value: selectedTab)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func tabIcon(for tab: AppTab) -> some View {
        let isActive = (selectedTab == tab)
        let tint = isActive ? AppTheme.cyan400 : Color.white.opacity(0.6)
        
        switch tab {
        case .files:
            FolderMorphIcon(isActive: isActive, tintColor: tint, size: 20)
        case .sign:
            if isActive {
                PenMorphIcon(tintColor: tint, size: 20)
            } else {
                Image(systemName: "signature")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tint)
            }
        case .settings:
            GearMorphIcon(isActive: isActive, tintColor: tint, size: 20)
        }
    }
}
