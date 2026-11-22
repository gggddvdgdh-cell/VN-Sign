@echo off
chcp 65001 >nul
title VN-Sign - Tự Động Đẩy Code Lên GitHub & Build IPA
color 0B

echo ==============================================================================
echo           VN-SIGN: TỰ ĐỘNG ĐẨY MÃ NGUỒN LÊN GITHUB & TẠO FILE IPA
echo ==============================================================================
echo.

:: 1. Kiểm tra Git đã được cài đặt chưa
where git >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [LỖI] Chưa tìm thấy Git trên máy tính của bạn!
    echo.
    echo Để đẩy code lên GitHub, bạn cần cài đặt Git:
    echo 1. Tải bộ cài chính thức tại: https://git-scm.com/download/win
    echo 2. Hoặc mở PowerShell và gõ: winget install Git.Git
    echo.
    echo Sau khi cài đặt xong, vui lòng khởi động lại cửa sổ này và chạy lại file bat.
    echo.
    pause
    exit /b 1
)

echo [✓] Đã phát hiện Git trên hệ thống.
echo.

:: 2. Khởi tạo Git repository nếu chưa có
if not exist ".git" (
    echo [*] Đang khởi tạo kho lưu trữ Git cục bộ...
    git init
    git branch -M main
    echo [✓] Đã khởi tạo Git repository với nhánh mặc định là 'main'.
    echo.
) else (
    echo [✓] Đã có sẵn kho Git cục bộ.
    echo.
)

:: 3. Kiểm tra hoặc thiết lập Remote URL
set "EXISTING_REMOTE="
for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set "EXISTING_REMOTE=%%i"

if defined EXISTING_REMOTE (
    echo Remote 'origin' hiện tại: %EXISTING_REMOTE%
    set /p "USE_EXISTING=Bạn có muốn tiếp tục đẩy lên Repository này? (Y/N, Mặc định: Y): "
    if /i "%USE_EXISTING%"=="N" (
        set "EXISTING_REMOTE="
    )
)

if not defined EXISTING_REMOTE (
    echo.
    echo ==============================================================================
    echo HƯỚNG DẪN TẠO REPOSITORY TRÊN GITHUB:
    echo 1. Truy cập: https://github.com/new
    echo 2. Repository name: VN-Sign (hoặc tên tuỳ ý bạn muốn)
    echo 3. Chọn Public hoặc Private (Private vẫn chạy GitHub Actions bình thường)
    echo 4. KHÔNG tích chọn "Add a README file"
    echo 5. Bấm nút "Create repository"
    echo 6. Sao chép đường dẫn HTTPS (VD: https://github.com/username/VN-Sign.git)
    echo ==============================================================================
    echo.
    :ENTER_URL
    set /p "REPO_URL=Dán đường dẫn GitHub Repository của bạn vào đây: "
    if "%REPO_URL%"=="" (
        echo [!] Vui lòng không để trống link GitHub!
        goto ENTER_URL
    )
    git remote remove origin >nul 2>&1
    git remote add origin %REPO_URL%
    echo [✓] Đã cấu hình remote origin: %REPO_URL%
    echo.
)

:: 4. Nhập ghi chú commit
echo.
set /p "COMMIT_MSG=Nhập mô tả phiên bản [Nhấn Enter để dùng mặc định: 'Cập nhật VN-Sign iOS']: "
if "%COMMIT_MSG%"=="" set "COMMIT_MSG=Cập nhật VN-Sign iOS và GitHub Actions CI/CD"

echo.
echo [*] Đang chuẩn bị các tệp tin để tải lên...
git add -A

echo [*] Đang tạo commit: "%COMMIT_MSG%"...
git commit -m "%COMMIT_MSG%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Không có thay đổi mới cần commit. Tiếp tục tiến trình...
) else (
    echo [✓] Tạo commit thành công!
)

:: 5. Tiến hành Push lên GitHub
echo.
echo [*] Đang tải mã nguồn lên GitHub (git push -u origin main)...
git push -u origin main
if %errorlevel% neq 0 (
    echo.
    echo [!] Quá trình push gặp lỗi xung đột hoặc branch chưa đồng bộ.
    echo [*] Thử kéo dữ liệu mới nhất với --rebase...
    git pull origin main --rebase
    echo [*] Đang thử đẩy lại lên GitHub...
    git push -u origin main
    if %errorlevel% neq 0 (
        color 0C
        echo.
        echo [CẢNH BÁO] Không thể tự động push lên GitHub!
        echo Nguyên nhân có thể do:
        echo 1. Bạn chưa đăng nhập tài khoản GitHub trong Git Credential Manager.
        echo 2. Repository trên GitHub đã có sẵn các commit khác.
        echo.
        echo Bạn có muốn ép buộc ghi đè lên nhánh main (Force Push)? (Y/N): 
        set /p "DO_FORCE=Lựa chọn của bạn: "
        if /i "%DO_FORCE%"=="Y" (
            git push -u origin main --force
        ) else (
            echo Đã huỷ thao tác. Vui lòng kiểm tra lại cấu hình Git.
            pause
            exit /b 1
        )
    )
)

color 0A
echo.
echo ==============================================================================
echo [CHÚC MỪNG] ĐÃ ĐẨY MÃ NGUỒN LÊN GITHUB THÀNH CÔNG!
echo ==============================================================================
echo.
echo CÁCH TẢI FILE VN-Sign.ipa VỀ MÁY TÍNH HOẶC IPHONE:
echo.
echo 1. Mở trình duyệt và truy cập trang GitHub Repository của bạn.
echo 2. Nhìn lên thanh menu ngang phía trên, bấm vào tab "Actions".
echo 3. Bạn sẽ thấy quy trình "Build & Package VN-Sign iOS IPA" đang tự động chạy.
echo 4. Chờ khoảng 2 đến 3 phút cho đến khi biểu tượng chuyển sang dấu TÍCH XANH.
echo 5. Bấm chuột vào tên lần chạy đó (Run vừa xong).
echo 6. Cuộn xuống phần "Artifacts" ở cuối trang Summary.
echo 7. Bấm chuột vào "VN-Sign-ipa" để tải file IPA hoàn chỉnh về máy!
echo.
echo Hỗ trợ kỹ thuật:
echo - Discord: https://discord.gg/679mFrKtH
echo - Zalo: 0788843545
echo ==============================================================================
echo.
pause
