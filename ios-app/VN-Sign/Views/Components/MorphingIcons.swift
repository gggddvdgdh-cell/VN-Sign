import SwiftUI

/// Các biểu tượng vector biến hình mượt mà (Animated Morphing Vector Icons / Morphicons)

// MARK: - 1. Pen Writing Morphicon (Biểu tượng Bút Ký viết chuyển động)
public struct PenMorphIcon: View {
    @State private var isWriting = false
    public var tintColor: Color = AppTheme.cyan400
    public var size: CGFloat = 20
    
    public init(tintColor: Color = AppTheme.cyan400, size: CGFloat = 20) {
        self.tintColor = tintColor
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Nét ký uốn lượn dưới ngòi bút
            Path { path in
                path.move(to: CGPoint(x: 2, y: 16))
                path.addCurve(to: CGPoint(x: 18, y: 16),
                              control1: CGPoint(x: 6, y: 12),
                              control2: CGPoint(x: 12, y: 19))
            }
            .trim(from: 0, to: isWriting ? 1.0 : 0.2)
            .stroke(tintColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            .frame(width: size, height: size)
            
            // Cây bút nghiêng và di chuyển theo nét viết
            Image(systemName: "pencil.tip")
                .font(.system(size: size * 0.75, weight: .bold))
                .foregroundColor(tintColor)
                .rotationEffect(.degrees(isWriting ? -18 : -32))
                .offset(x: isWriting ? 4 : -3, y: isWriting ? -2 : -1)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isWriting = true
            }
        }
    }
}

// MARK: - 2. Folder Morphicon (Thư mục mở nắp biến hình)
public struct FolderMorphIcon: View {
    public var isActive: Bool
    public var tintColor: Color = AppTheme.cyan400
    public var size: CGFloat = 22
    
    public init(isActive: Bool, tintColor: Color = AppTheme.cyan400, size: CGFloat = 22) {
        self.isActive = isActive
        self.tintColor = tintColor
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Nền thư mục
            Image(systemName: isActive ? "folder.fill" : "folder")
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(tintColor)
                .scaleEffect(isActive ? 1.08 : 1.0)
                .animation(AppTheme.springAnimation, value: isActive)
            
            // Giấy trồi lên khi tab đang chọn
            if isActive {
                Image(systemName: "doc.fill")
                    .font(.system(size: size * 0.55))
                    .foregroundColor(.white)
                    .offset(y: -4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 3. Gear Rotate Morphicon (Bánh răng xoay mượt)
public struct GearMorphIcon: View {
    public var isActive: Bool
    public var tintColor: Color = AppTheme.cyan400
    public var size: CGFloat = 22
    
    public init(isActive: Bool, tintColor: Color = AppTheme.cyan400, size: CGFloat = 22) {
        self.isActive = isActive
        self.tintColor = tintColor
        self.size = size
    }
    
    public var body: some View {
        Image(systemName: isActive ? "gearshape.fill" : "gearshape")
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(tintColor)
            .rotationEffect(.degrees(isActive ? 90 : 0))
            .scaleEffect(isActive ? 1.08 : 1.0)
            .animation(AppTheme.springAnimation, value: isActive)
            .frame(width: size, height: size)
    }
}

// MARK: - 4. Checkmark Stroke Morphicon (Dấu tích vẽ hoàn thành)
public struct CheckmarkMorphIcon: View {
    @State private var progress: CGFloat = 0.0
    public var size: CGFloat = 28
    public var color: Color = Color(red: 16/255, green: 185/255, blue: 129/255)
    
    public init(size: CGFloat = 28, color: Color = Color(red: 16/255, green: 185/255, blue: 129/255)) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 1.5, height: size * 1.5)
            
            Path { path in
                path.move(to: CGPoint(x: 4, y: size * 0.55))
                path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.85))
                path.addLine(to: CGPoint(x: size * 0.95, y: size * 0.22))
            }
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - 5. Shield Pulse Icon (Khiên bảo vệ xung nhịp cho Anti-Revoke)
public struct ShieldPulseIcon: View {
    public var isEnabled: Bool
    @State private var pulse = false
    
    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
    
    public var body: some View {
        ZStack {
            if isEnabled {
                Circle()
                    .stroke(AppTheme.cyan400.opacity(pulse ? 0.0 : 0.5), lineWidth: 2)
                    .scaleEffect(pulse ? 1.5 : 0.9)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
            }
            
            Image(systemName: isEnabled ? "checkmark.shield.fill" : "shield.slash.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isEnabled ? AppTheme.cyan400 : .secondary)
        }
        .frame(width: 32, height: 32)
        .onAppear {
            pulse = true
        }
    }
}
