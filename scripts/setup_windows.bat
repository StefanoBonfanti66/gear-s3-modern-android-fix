@echo off
REM ==============================================================================
REM Samsung Gear S3 Modern Phone Compatibility Setup Tool (Windows)
REM Automates APK installation, runtime permissions, AppOps, and Doze whitelisting
REM ==============================================================================

echo =================================================================
echo       Samsung Gear S3 Compatibility Setup Tool (Android 14+)
echo =================================================================
echo.

REM 1. Check for adb
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 'adb' is not recognized. Please install Android Platform Tools and add adb to your PATH.
    echo Download: https://developer.android.com/tools/releases/platform-tools
    pause
    exit /b 1
)

echo [*] Checking for connected Android devices via ADB...
adb get-state >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] No authorized device detected.
    echo Please make sure USB Debugging is ENABLED on your phone and you have allowed the prompt.
    echo.
    pause
)

for /f "tokens=*" %%i in ('adb shell getprop ro.product.model 2^>nul') do set DEVICE_MODEL=%%i
for /f "tokens=*" %%i in ('adb shell getprop ro.build.version.sdk 2^>nul') do set DEVICE_SDK=%%i
echo [+] Device detected: %DEVICE_MODEL% (Android SDK: %DEVICE_SDK%)
echo.

set SCRIPT_DIR=%~dp0
set APK_DIR=%SCRIPT_DIR%..\apks

if not exist "%APK_DIR%" mkdir "%APK_DIR%"

set GEAR_PLUGIN_PKG=com.samsung.android.gearoplugin
set GEAR_S_LEGACY_PKG=com.samsung.android.gearsplugin
set WATCH_MANAGER_PKG=com.samsung.android.app.watchmanager
set ACCESSORY_PKG=com.samsung.accessory

echo [*] Step 1: Installing APK packages from '%APK_DIR%'...

REM Install Accessory Service if found
for %%f in ("%APK_DIR%\*accessory*.apk") do (
    echo [*] Installing Accessory Service: %%~nxf
    adb install -r -d --bypass-low-target-sdk-block "%%f" 2>nul || adb install -r -d "%%f"
)

REM Install Galaxy Wearable if found
for %%f in ("%APK_DIR%\*watchmanager*.apk" "%APK_DIR%\galaxy_wearable.apk") do (
    echo [*] Installing Galaxy Wearable: %%~nxf
    adb install -r -d --bypass-low-target-sdk-block "%%f" 2>nul || adb install -r -d "%%f"
)

REM Install Gear Plugin if found
for %%f in ("%APK_DIR%\*gear*plugin*.apk" "%APK_DIR%\gear_s_plugin.apk") do (
    echo [*] Installing Gear Plugin: %%~nxf
    adb install -r -d --bypass-low-target-sdk-block "%%f" 2>nul || adb install -r -d "%%f"
)

echo.
echo [*] Step 2: Granting runtime permissions to Gear Plugin...
for %%p in (%GEAR_PLUGIN_PKG% %GEAR_S_LEGACY_PKG%) do (
    adb shell pm grant %%p android.permission.BLUETOOTH_CONNECT 2>nul
    adb shell pm grant %%p android.permission.BLUETOOTH_SCAN 2>nul
    adb shell pm grant %%p android.permission.BLUETOOTH_ADVERTISE 2>nul
    adb shell pm grant %%p android.permission.ACCESS_FINE_LOCATION 2>nul
    adb shell pm grant %%p android.permission.ACCESS_COARSE_LOCATION 2>nul
    adb shell pm grant %%p android.permission.POST_NOTIFICATIONS 2>nul
    adb shell pm grant %%p android.permission.READ_PHONE_STATE 2>nul
    adb shell pm grant %%p android.permission.CALL_PHONE 2>nul
    adb shell pm grant %%p android.permission.READ_CALL_LOG 2>nul
    adb shell pm grant %%p android.permission.WRITE_CALL_LOG 2>nul
    adb shell pm grant %%p android.permission.READ_CONTACTS 2>nul
    adb shell pm grant %%p android.permission.WRITE_CONTACTS 2>nul
    adb shell pm grant %%p android.permission.READ_SMS 2>nul
    adb shell pm grant %%p android.permission.RECEIVE_SMS 2>nul
    adb shell pm grant %%p android.permission.SEND_SMS 2>nul
    adb shell pm grant %%p android.permission.READ_CALENDAR 2>nul
    adb shell pm grant %%p android.permission.WRITE_CALENDAR 2>nul
    adb shell pm grant %%p android.permission.READ_EXTERNAL_STORAGE 2>nul
    adb shell pm grant %%p android.permission.WRITE_EXTERNAL_STORAGE 2>nul
    adb shell pm grant %%p android.permission.BODY_SENSORS 2>nul
    adb shell pm grant %%p android.permission.ACTIVITY_RECOGNITION 2>nul
)
echo [+] Permissions granted.

echo.
echo [*] Step 3: Enabling Restricted Settings (AppOps)...
adb shell appops set %GEAR_PLUGIN_PKG% ACCESS_RESTRICTED_SETTINGS allow 2>nul
adb shell appops set %GEAR_S_LEGACY_PKG% ACCESS_RESTRICTED_SETTINGS allow 2>nul
adb shell appops set %WATCH_MANAGER_PKG% ACCESS_RESTRICTED_SETTINGS allow 2>nul
echo [+] Restricted settings permitted.

echo.
echo [*] Step 4: Disabling battery optimization (Doze whitelist)...
adb shell dumpsys deviceidle whitelist +%GEAR_PLUGIN_PKG% 2>nul
adb shell dumpsys deviceidle whitelist +%GEAR_S_LEGACY_PKG% 2>nul
adb shell dumpsys deviceidle whitelist +%WATCH_MANAGER_PKG% 2>nul
adb shell dumpsys deviceidle whitelist +%ACCESSORY_PKG% 2>nul
echo [+] Battery optimization configured.

echo.
echo =================================================================
echo [SUCCESS] Setup and permission injection complete!
echo =================================================================
echo.
echo First-time pairing steps:
echo  1. Turn ON 'Airplane Mode' on your phone, then turn ON Bluetooth only.
echo  2. (If the app forces an update): Temporarily change phone date to December 2023.
echo  3. Put your Gear S3 in pairing mode (factory reset if needed).
echo  4. Open Galaxy Wearable and complete pairing.
echo  5. Restore Automatic Date and disable Airplane Mode.
echo.
pause
