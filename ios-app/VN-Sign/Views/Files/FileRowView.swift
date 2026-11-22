import SwiftUI

public struct FileRowView: View {
    public var file: FileItem
    public var isSelecting: Bool
    public var onSelectToggle: () -> Void
    public var onSignAction: () -> Void
    public var onShareAction: () -> Void
    public var onDeleteAction: () -> Void
    
    public init(
        file: FileItem,
        isSelecting: Bool,
        onSelectToggle: @escaping () -> Void,
        onSignAction: @escaping () -> Void,
        onShareAction: @escaping () -> Void,
        onDeleteAction: @escaping () -> Void
    ) {
        self.file = file
        self.isSelecting = isSelecting
        self.onSelectToggle = onSelectToggle
        self.onSignAction = onSignAction
        self.onShareAction = onShareAction
        self.onDeleteAction = onDeleteAction
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Select Mode Checkbox
            if isSelecting {
                Button(action: onSelectToggle) {
                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(file.isSelected ? AppTheme.cyan400 : Color.white.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
            
            // Icon Badge theo loại file
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: file.fileType.badgeColorHex).opacity(0.18))
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: file.fileType.badgeColorHex).opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: file.fileType.iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: file.fileType.badgeColorHex))
            }
            
            // Tên và thông số tệp
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.formattedSize)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text(file.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Quick action button nếu là tệp IPA
            if file.fileType == .ipa && !isSelecting {
                Button(action: onSignAction) {
                    HStack(spacing: 4) {
                        PenMorphIcon(tintColor: .black, size: 14)
                        Text(NSLocalizedString("files_action_sign", comment: ""))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.cyanGradient)
                    .clipShape(Capsule())
                    .cyanGlow(radius: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frostedGlassCard(cornerRadius: 14, strokeOpacity: 0.12)
        .contextMenu {
            if file.fileType == .ipa {
                Button(action: onSignAction) {
                    Label(NSLocalizedString("files_action_sign", comment: ""), systemImage: "signature")
                }
            }
            Button(action: onShareAction) {
                Label(NSLocalizedString("files_action_share", comment: ""), systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive, action: onDeleteAction) {
                Label(NSLocalizedString("files_action_delete", comment: ""), systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDeleteAction) {
                Label(NSLocalizedString("files_action_delete", comment: ""), systemImage: "trash")
            }
            Button(action: onShareAction) {
                Label(NSLocalizedString("files_action_share", comment: ""), systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}
