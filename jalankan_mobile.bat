@echo off
echo ===================================================
echo [1/2] Menghubungkan HP ke Laravel (adb reverse)...
echo ===================================================
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
if %ERRORLEVEL% EQU 0 (
    echo [OK] Port 8000 berhasil dihubungkan ke HP!
) else (
    echo [PERINGATAN] HP belum terdeteksi via USB ADB.
)
echo.
echo ===================================================
echo [2/2] Menjalankan Flutter Run...
echo ===================================================
flutter run
