#!/usr/bin/env bash
# ==============================================================================
# Samsung Gear S3 Modern Phone Compatibility Setup Tool (Linux / macOS)
# Automates APK installation, runtime permissions, AppOps, and Doze whitelisting
# ==============================================================================

set -e

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}      Samsung Gear S3 Compatibility Setup Tool (Android 14+)     ${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo ""

# 1. Check prerequisites
if ! command -v adb &> /dev/null; then
    echo -e "${RED}[ERROR] 'adb' (Android Debug Bridge) is not installed or not in PATH.${NC}"
    echo -e "Please install it via: sudo apt install adb (Debian/Ubuntu) or brew install android-platform-tools (macOS)"
    exit 1
fi

echo -e "${BLUE}[*] Checking for connected Android devices via ADB...${NC}"
DEVICE_COUNT=$(adb devices | grep -v "List" | grep -v "^$" | grep -c "device" || true)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}[!] No authorized Android device detected.${NC}"
    echo -e "Please make sure:"
    echo -e "  1. USB Debugging is ENABLED on your phone (Settings > Developer options)."
    echo -e "  2. Your phone is connected via USB and you have tapped 'Allow USB debugging'."
    echo ""
    read -rp "Press Enter once your device is connected and authorized..."
fi

# Confirm device
DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null || echo "Unknown Device")
DEVICE_SDK=$(adb shell getprop ro.build.version.sdk 2>/dev/null || echo "Unknown SDK")
echo -e "${GREEN}[+] Device connected:${NC} $DEVICE_MODEL (Android SDK: $DEVICE_SDK)"
echo ""

# 2. Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
APK_DIR="$REPO_DIR/apks"

mkdir -p "$APK_DIR"

GEAR_PLUGIN_PKG="com.samsung.android.gearsplugin"
WATCH_MANAGER_PKG="com.samsung.android.app.watchmanager"
ACCESSORY_PKG="com.samsung.accessory"

echo -e "${YELLOW}[*] Step 1: Checking APK packages in '${APK_DIR}'...${NC}"
echo "Required files:"
echo " - gear_s_plugin.apk (Gear S Plugin v2.2.03.23121551 or compatible)"
echo " - galaxy_wearable.apk (Galaxy Wearable v2.2.57.23102461 or compatible)"
echo ""

MISSING=0
if [ ! -f "$APK_DIR/gear_s_plugin.apk" ]; then
    echo -e "${YELLOW}[!] Missing: $APK_DIR/gear_s_plugin.apk${NC}"
    MISSING=1
fi

if [ ! -f "$APK_DIR/galaxy_wearable.apk" ]; then
    echo -e "${YELLOW}[!] Missing: $APK_DIR/galaxy_wearable.apk${NC}"
    MISSING=1
fi

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Please download the verified late-2023 APKs from a trusted repository (e.g. APKMirror):${NC}"
    echo -e "  1. Gear S Plugin:       https://www.apkmirror.com/apk/samsung-electronics-co-ltd/gear-s-plugin/"
    echo -e "  2. Galaxy Wearable:    https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsung-gear/"
    echo ""
    echo "Place the files in '$APK_DIR' with the filenames:"
    echo "  - gear_s_plugin.apk"
    echo "  - galaxy_wearable.apk"
    echo ""
    read -rp "Press [Enter] to continue if already installed or when APKs are placed in folder..."
fi

# 3. Install APKs if present
if [ -f "$APK_DIR/galaxy_wearable.apk" ]; then
    echo -e "${BLUE}[*] Installing Galaxy Wearable...${NC}"
    adb install -r -d --bypass-low-target-sdk-block "$APK_DIR/galaxy_wearable.apk" 2>/dev/null || adb install -r -d "$APK_DIR/galaxy_wearable.apk"
fi

if [ -f "$APK_DIR/gear_s_plugin.apk" ]; then
    echo -e "${BLUE}[*] Installing Gear S Plugin...${NC}"
    adb install -r -d --bypass-low-target-sdk-block "$APK_DIR/gear_s_plugin.apk" 2>/dev/null || adb install -r -d "$APK_DIR/gear_s_plugin.apk"
fi

# 4. Grant Runtime Permissions via ADB
echo ""
echo -e "${BLUE}[*] Step 2: Granting runtime permissions to Gear S Plugin...${NC}"

PERMISSIONS=(
    "android.permission.BLUETOOTH_CONNECT"
    "android.permission.BLUETOOTH_SCAN"
    "android.permission.BLUETOOTH_ADVERTISE"
    "android.permission.ACCESS_FINE_LOCATION"
    "android.permission.ACCESS_COARSE_LOCATION"
    "android.permission.POST_NOTIFICATIONS"
    "android.permission.READ_PHONE_STATE"
    "android.permission.CALL_PHONE"
    "android.permission.READ_CALL_LOG"
    "android.permission.WRITE_CALL_LOG"
    "android.permission.READ_CONTACTS"
    "android.permission.WRITE_CONTACTS"
    "android.permission.READ_SMS"
    "android.permission.RECEIVE_SMS"
    "android.permission.SEND_SMS"
    "android.permission.READ_CALENDAR"
    "android.permission.WRITE_CALENDAR"
    "android.permission.READ_EXTERNAL_STORAGE"
    "android.permission.WRITE_EXTERNAL_STORAGE"
    "android.permission.BODY_SENSORS"
    "android.permission.ACTIVITY_RECOGNITION"
)

for perm in "${PERMISSIONS[@]}"; do
    adb shell pm grant "$GEAR_PLUGIN_PKG" "$perm" 2>/dev/null || true
done
echo -e "${GREEN}[+] Gear S Plugin permissions configured.${NC}"

# 5. Bypass Android 13/14 Restricted Settings
echo ""
echo -e "${BLUE}[*] Step 3: Enabling Restricted Settings (AppOps) for sideloaded packages...${NC}"
adb shell appops set "$GEAR_PLUGIN_PKG" ACCESS_RESTRICTED_SETTINGS allow 2>/dev/null || true
adb shell appops set "$WATCH_MANAGER_PKG" ACCESS_RESTRICTED_SETTINGS allow 2>/dev/null || true
echo -e "${GREEN}[+] Restricted settings permitted.${NC}"

# 6. Whitelist from Battery Optimization / Doze
echo ""
echo -e "${BLUE}[*] Step 4: Disabling aggressive battery optimizations (Doze whitelist)...${NC}"
adb shell dumpsys deviceidle whitelist +"$GEAR_PLUGIN_PKG" 2>/dev/null || true
adb shell dumpsys deviceidle whitelist +"$WATCH_MANAGER_PKG" 2>/dev/null || true
adb shell dumpsys deviceidle whitelist +"$ACCESSORY_PKG" 2>/dev/null || true
echo -e "${GREEN}[+] Battery optimization whitelisted.${NC}"

# 7. Final Pairing Instructions
echo ""
echo -e "${CYAN}=================================================================${NC}"
echo -e "${GREEN}[SUCCESS] Setup and permission injection complete!${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo ""
echo "Important instructions for the first pairing:"
echo " 1. Turn ON 'Airplane Mode' on your phone, then turn ON Bluetooth only."
echo " 2. (If the app forces an update): Temporarily change your phone's date to December 2023."
echo " 3. Put your Gear S3 in pairing mode (or factory reset it if needed)."
echo " 4. Open Galaxy Wearable on your phone and complete pairing."
echo " 5. Once the watch face appears, restore Automatic Date and disable Airplane Mode."
echo ""
echo -e "${CYAN}Enjoy your Gear S3!${NC}"
