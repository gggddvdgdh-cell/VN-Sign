@echo off
chcp 65001 >nul
title VN-Sign Pro - Cong Cu Ky & Dong Goi iOS
cls
echo =====================================================================
echo              VN-SIGN PRO - CÔNG CỤ KÝ & ĐÓNG GÓI CHO IPHONE
echo =====================================================================
echo.
echo [1] Kiem tra file chung chi trong thu muc d:\VN-Sign...

set P12_FILE=
set PROV_FILE=

for %%F in ("%~dp0*.p12") do set "P12_FILE=%%F"
for %%F in ("%~dp0*.mobileprovision") do set "PROV_FILE=%%F"

if "%P12_FILE%"=="" (
    echo [!] CHUA TIM THAY FILE CHUNG CHI .P12 TRONG THU MUC: %~dp0
    echo     Hay copy file chung chi .p12 ban da mua vao thu muc:
    echo     %~dp0
    echo.
) else (
    echo [OK] Da tim thay file P12: %P12_FILE%
)

if "%PROV_FILE%"=="" (
    echo [!] CHUA TIM THAY FILE .MOBILEPROVISION TRONG THU MUC: %~dp0
    echo     Hay copy file .mobileprovision vao thu muc:
    echo     %~dp0
    echo.
) else (
    echo [OK] Da tim thay file Profile: %PROV_FILE%
)

if "%P12_FILE%"=="" goto NO_CERT
if "%PROV_FILE%"=="" goto NO_CERT

echo.
echo =====================================================================
echo Nhap mat khau file .P12 cua ban (neu khong co thi an Enter):
set /p P12_PASS="Mat khau P12: "

echo.
echo Dang tien hanh ky VN-Sign.ipa bang chung chi cua ban...
"%~dp0tools\zsign.exe" -k "%P12_FILE%" -p "%P12_PASS%" -m "%PROV_FILE%" -o "%~dp0VN-Sign-ReadyToInstall.ipa" -n "VN-Sign" "%~dp0VN-Sign.ipa"

if exist "%~dp0VN-Sign-ReadyToInstall.ipa" (
    echo.
    echo =====================================================================
    echo [THANH CONG!] Da tao file: VN-Sign-ReadyToInstall.ipa
    echo =====================================================================
    echo.
    echo Ban co the cai file nay vao iPhone bang cac cach:
    echo 1. Dung Sideloadly hoac 3uTools cam cap Lightning/Type-C vao may.
    echo 2. Hoac gui file 'VN-Sign-ReadyToInstall.ipa' qua Telegram/AirDrop/Google Drive
    echo    de cai truc tiep.
    echo.
) else (
    echo.
    echo [LOI] Ky that bai! Hay kiem tra lai mat khau P12 hoac file chung chi.
)

pause
exit /b

:NO_CERT
echo ---------------------------------------------------------------------
echo HUONG DAN:
echo 1. Copy 2 file ban da mua (.p12 va .mobileprovision) vao thu muc nay:
echo    %~dp0
echo 2. Chay lai file 'sign_my_app.bat' nay.
echo 3. Cong cu se tu dong ky file VN-Sign.ipa thanh file san sang cai len iPhone.
echo ---------------------------------------------------------------------
echo.
pause
