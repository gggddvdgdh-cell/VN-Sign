import SwiftUI

public struct ToastMessage: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let isError: Bool
    
    public init(title: String, message: String, isError: Bool = false) {
        self.title = title
        self.message = message
        self.isError = isError
    }
}

public struct ToastModifier: ViewModifier {
    @Binding public var toast: ToastMessage?
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toast {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(toast.isError ? .red : AppTheme.cyan400)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(toast.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(toast.message)
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .frostedGlassCard(cornerRadius: 16, strokeOpacity: 0.25)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(AppTheme.fastSpring) {
                                self.toast = nil
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 48)
                .zIndex(999)
            }
        }
    }
}

extension View {
    public func toast(item: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(toast: item))
    }
}
