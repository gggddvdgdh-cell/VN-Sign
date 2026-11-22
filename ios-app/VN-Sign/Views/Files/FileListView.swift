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
    
    // P12 Password Prompt State
    @State private var showP12PasswordAlert = false
    @State private var p12PasswordInput = ""
    @State private var pendingP12File: FileItem?
    
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
                HStack(spacing: 10) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                        .shadow(color: AppTheme.purple500.opacity(0.4), radius: 6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("files_title", comment: ""))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        if isSelecting {
                            Text(String(format: NSLocalizedString("files_selected_count", comment: ""), selectedCount))
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.cyan400)
                        } else {
                            Text("\(files.count) tệp tin trong máy")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.55))
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
                
                // Danh sách tệp tin thực tế
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
                                        handleFileAction(file: file)
                                    },
                                    onShareAction: {
                                        shareFile(file: file)
                                    },
                                    onDeleteAction: {
                                        deleteFile(file: file)
                                    }
                                )
                                .onTapGesture {
                                    if isSelecting {
                                        if let idx = files.firstIndex(where: { $0.id == file.id }) {
                                            files[idx].isSelected.toggle()
                                        }
                                    } else {
                                        handleFileAction(file: file)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Đệm cho Floating Dock
                    }
                }
                
                // Thanh tác vụ chọn nhiều
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
        .alert("Nhập mật khẩu P12", isPresented: $showP12PasswordAlert) {
            TextField("Mật khẩu (nếu không có thì để trống)", text: $p12PasswordInput)
            Button("Nhập chứng chỉ") {
                if let p12 = pendingP12File {
                    do {
                        let cert = try CertManager.shared.importP12(from: p12.url, password: p12PasswordInput)
                        toastMessage = ToastMessage(title: "Chứng chỉ hợp lệ", message: "Đã thêm: \(cert.teamName)")
                    } catch {
                        toastMessage = ToastMessage(title: "Lỗi P12", message: error.localizedDescription)
                    }
                }
                p12PasswordInput = ""
                pendingP12File = nil
            }
            Button("Hủy", role: .cancel) {
                p12PasswordInput = ""
                pendingP12File = nil
            }
        } message: {
            Text("Nhập mật khẩu để giải mã chứng chỉ \(pendingP12File?.name ?? ""):")
        }
        .toast(item: $toastMessage)
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.purple500.opacity(0.15))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 34, weight: .semibold))
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
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("files_import_button", comment: ""))
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 22)
                .padding(.vertical, 11)
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
    
    private func handleFileAction(file: FileItem) {
        switch file.fileType {
        case .ipa:
            prepareSign(file: file)
        case .p12:
            self.pendingP12File = file
            self.p12PasswordInput = ""
            self.showP12PasswordAlert = true
        case .mobileprovision:
            do {
                let prof = try CertManager.shared.importMobileProvision(from: file.url)
                toastMessage = ToastMessage(title: "Đã nạp Profile", message: prof.name)
            } catch {
                toastMessage = ToastMessage(title: "Lỗi Profile", message: error.localizedDescription)
            }
        default:
            shareFile(file: file)
        }
    }
    
    private func deleteFile(file: FileItem) {
        withAnimation(AppTheme.springAnimation) {
            files.removeAll { $0.id == file.id }
        }
        try? FileManager.default.removeItem(at: file.url)
        SigningEngine.shared.reloadLibraryApps()
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
        SigningEngine.shared.reloadLibraryApps()
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
            bundleIdentifier: "com.vnsign.\(file.name.lowercased().filter { $0.isLetter || $0.isNumber })",
            version: "1.0",
            fileSize: file.size,
            filePath: file.url.path,
            originalIpaPath: file.url.path,
            isSigned: false
        )
        self.selectedSignApp = app
    }
    
    private func importFiles(urls: [URL]) {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        var importedCount = 0
        
        for url in urls {
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }
            
            let name = url.lastPathComponent
            let targetURL = docURL.appendingPathComponent(name)
            
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.copyItem(at: url, to: targetURL)
                importedCount += 1
                
                // Tự động nhận diện hồ sơ Mobileprovision
                if url.pathExtension.lowercased() == "mobileprovision" {
                    _ = try? CertManager.shared.importMobileProvision(from: targetURL)
                }
            } catch {
                print("Lỗi chép tệp: \(error)")
            }
        }
        
        loadInitialFiles()
        
        if importedCount > 0 {
            toastMessage = ToastMessage(title: "Nhập thành công", message: "\(importedCount) tệp đã được thêm vào VN-Sign")
        }
    }
    
    private func loadInitialFiles() {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: docURL,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            var loadedFiles: [FileItem] = []
            for url in fileURLs {
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
                
                let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                let size = Int64(resourceValues?.fileSize ?? 0)
                let date = resourceValues?.contentModificationDate ?? Date()
                
                loadedFiles.append(FileItem(name: name, url: url, size: size, modificationDate: date, fileType: type))
            }
            
            self.files = loadedFiles
            SigningEngine.shared.reloadLibraryApps()
        } catch {
            print("Error loading documents: \(error)")
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
