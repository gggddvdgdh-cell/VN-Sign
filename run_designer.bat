@echo off
title VN-Sign Mobile App Designer (Rust)
cd /d "%~dp0designer"
echo ========================================================
echo   Starting VN-Sign Mobile UI Designer (Native Rust)
echo ========================================================
echo.
if exist "target\debug\designer.exe" (
    "target\debug\designer.exe"
) else (
    cargo run
)
pause
