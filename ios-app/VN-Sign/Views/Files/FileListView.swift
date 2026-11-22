import SwiftUI
import UniformTypeIdentifiers

public struct FileListView: View {
    @State private var files: [FileItem] = []
    @State private var searchText = ""
    @State private var isSelecting = false
    @State private var showDocumentPicker = false
    @State private var sortOption: SortOption = .dateDesc
    @State private var selectedSignApp: AppItem?
    @State private var toastMessage: ToastMessage?
    
    public enum SortOption {
        case nameAsc, dateDesc, sizeDesc
    }
    
    public init() {}
    
    private var filteredFiles: [FileItem] {
        var result = files
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .nameAsc:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .dateDesc:
            result.sort { $0.modificationDate > $1.modificationDate }
        case .sizeDesc:
            result.sort { $0.size > $1.size }
        }
        return result
    }
    
    private var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("files_title", comment: ""))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        if isSelecting {
                            Text(String(format: NSLocalizedString("files_selected_count", comment: ""), selectedCount))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.cyan400)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Nút Menu (...)
                        Menu {
                            Button(action: {
                                withAnimation(AppTheme.springAnimation) {
                                    isSelecting.toggle()
                                    if !isSelecting {
                                        for i in 0..<files.count { files[i].isSelected = false }
                                    }
                                }
                            }) {
                                Label(isSelecting ? "Thoát chọn" : "Chọn nhiều", systemImage: "checkmark.circle")
                            }
                            
                            if isSelecting {
                                Button(action: selectAll) {
                                    Label(NSLocalizedString("files_menu_select_all", comment: ""), systemImage: "checklist")
                                }
                                Button(action: deselectAll) {
                                    Label(NSLocalizedString("files_menu_deselect_all", comment: ""), systemImage: "circle")
                                }
                            }
                            
                            Divider()
                            
                            Button(action: { sortOption = .nameAsc }) {
                                Label(NSLocalizedString("files_menu_sort_name", comment: ""), systemImage: "textformat")
                            }
                            Button(action: { sortOption = .dateDesc }) {
                                Label(NSLocalizedString("files_menu_sort_date", comment: ""), systemImage: "calendar")
                            }
                            Button(action: { sortOption = .sizeDesc }) {
                                Label(NSLocalizedString("files_menu_sort_size", comment: ""), systemImage: "internaldrive")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        }
                        
                        // Nút Thêm (+)
                        Button(action: { showDocumentPicker = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 38, height: 38)
                                .background(AppTheme.cyanGradient)
                                .clipShape(Circle())
                                .cyanGlow(radius: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Ô tìm kiếm kính mờ
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    TextField(NSLocalizedString("files_search_placeholder", comment: ""), text: $searchText)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frostedGlassCard(cornerRadius: 12, strokeOpacity: 0.12)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Danh sách tệp tin
                if filteredFiles.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredFiles) { file in
                                FileRowView(
                                    file: file,
                                    isSelecting: isSelecting,
                                    onSelectToggle: {
                                        if let idx = files.firstIndex(where: { $0.id == file.id }) {
                                            files[idx].isSelected.toggle()
                                        }
                                    },
                                    onSignAction: {
                                        prepareSign(file: file)
                                    },
                                    onShareAction: {
                                        shareFile(file: file)
                                    },
                                    onDeleteAction: {
                                        deleteFile(file: file)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Đệm cho Floating Dock
                    }
                }
                
                // Thanh tác vụ chọn nhiều (Multi-select bottom action bar)
                if isSelecting && selectedCount > 0 {
                    HStack(spacing: 12) {
                        Button(action: deleteSelected) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(NSLocalizedString("files_menu_delete_selected", comment: ""))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            loadInitialFiles()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { urls in
                importFiles(urls: urls)
            }
        }
        .sheet(item: $selectedSignApp) { app in
            SignSheetView(app: app)
        }
        .toast(item: $toastMessage)
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.cyan500.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppTheme.cyan400)
            }
            
            Text(NSLocalizedString("files_empty_title", comment: ""))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            Text(NSLocalizedString("files_empty_subtitle", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showDocumentPicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(NSLocalizedString("files_import_button", comment: ""))
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.cyanGradient)
                .clipShape(Capsule())
                .cyanGlow(radius: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 6)
        }
    }
    
    // MARK: - Actions
    
    private func selectAll() {
        for i in 0..<files.count { files[i].isSelected = true }
    }
    
    private func deselectAll() {
        for i in 0..<files.count { files[i].isSelected = false }
    }
    
    private func deleteFile(file: FileItem) {
        withAnimation(AppTheme.springAnimation) {
            files.removeAll { $0.id == file.id }
        }
        try? FileManager.default.removeItem(at: file.url)
        toastMessage = ToastMessage(title: "Đã xoá", message: file.name)
    }
    
    private func deleteSelected() {
        let targets = files.filter { $0.isSelected }
        for t in targets {
            try? FileManager.default.removeItem(at: t.url)
        }
        withAnimation(AppTheme.springAnimation) {
            files.removeAll { $0.isSelected }
            isSelecting = false
        }
        toastMessage = ToastMessage(title: "Đã xoá", message: "\(targets.count) tệp tin")
    }
    
    private func shareFile(file: FileItem) {
        let av = UIActivityViewController(activityItems: [file.url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    private func prepareSign(file: FileItem) {
        let app = AppItem(
            name: file.name.replacingOccurrences(of: ".ipa", with: ""),
            bundleIdentifier: "com.vnsign.\(file.name.lowercased().filter { $0.isLetter })",
            version: "1.0",
            fileSize: file.size,
            filePath: file.url.path,
            originalIpaPath: file.url.path,
            isSigned: false
        )
        self.selectedSignApp = app
    }
    
    private func importFiles(urls: [URL]) {
        for url in urls {
            let name = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            let type: FileType
            switch ext {
            case "ipa": type = .ipa
            case "p12": type = .p12
            case "mobileprovision": type = .mobileprovision
            case "dylib": type = .dylib
            case "zip": type = .zip
            default: type = .other
            }
            
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            let newFile = FileItem(name: name, url: url, size: size, modificationDate: Date(), fileType: type)
            files.insert(newFile, at: 0)
        }
        toastMessage = ToastMessage(title: "Nhập thành công", message: "\(urls.count) tệp đã được thêm")
    }
    
    private func loadInitialFiles() {
        if files.isEmpty {
            files = [
                FileItem(
                    name: "VN-Sign.ipa",
                    url: URL(fileURLWithPath: "d:\\VN-Sign\\VN-Sign.ipa"),
                    size: 14_416_039,
                    modificationDate: Date(),
                    fileType: .ipa
                ),
                FileItem(
                    name: "Feather.ipa",
                    url: URL(fileURLWithPath: "d:\\VN-Sign\\Feather.ipa"),
                    size: 14_241_853,
                    modificationDate: Date().addingTimeInterval(-3600),
                    fileType: .ipa
                ),
                FileItem(
                    name: "VNSign_Enterprise.p12",
                    url: URL(fileURLWithPath: "d:\\VN-Sign\\VNSign_Enterprise.p12"),
                    size: 4_096,
                    modificationDate: Date().addingTimeInterval(-7200),
                    fileType: .p12
                ),
                FileItem(
                    name: "VN-Sign_Wildcard.mobileprovision",
                    url: URL(fileURLWithPath: "d:\\VN-Sign\\VN-Sign_Wildcard.mobileprovision"),
                    size: 8_192,
                    modificationDate: Date().addingTimeInterval(-10800),
                    fileType: .mobileprovision
                ),
                FileItem(
                    name: "Rocket_Instagram.dylib",
                    url: URL(fileURLWithPath: "d:\\VN-Sign\\Rocket_Instagram.dylib"),
                    size: 2_458_112,
                    modificationDate: Date().addingTimeInterval(-14400),
                    fileType: .dylib
                )
            ]
        }
    }
}

// MARK: - UIDocumentPickerViewController Wrapper
public struct DocumentPickerView: UIViewControllerRepresentable {
    public var onPick: ([URL]) -> Void
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .archive, .data], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}
