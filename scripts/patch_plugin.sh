#!/usr/bin/env bash
# ==============================================================================
# Gear S Plugin Decompiler & Patcher Script
# Unpacks Gear S Plugin APK, facilitates Smali inspection/patching, and rebuilds
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}             Gear S Plugin Smali Decompiler & Patcher            ${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo ""

if ! command -v apktool &> /dev/null; then
    echo -e "${RED}[ERROR] 'apktool' is required but not installed.${NC}"
    echo "Install via: sudo apt install apktool"
    exit 1
fi

INPUT_APK="${1:-}"

if [ -z "$INPUT_APK" ] || [ ! -f "$INPUT_APK" ]; then
    echo -e "${YELLOW}Usage: ./scripts/patch_plugin.sh <path_to_gear_s_plugin.apk>${NC}"
    echo ""
    echo "Example: ./scripts/patch_plugin.sh apks/gear_s_plugin.apk"
    exit 1
fi

WORK_DIR="decompiled_plugin"
OUTPUT_APK="dist/gear_s_plugin_modded.apk"

echo -e "${GREEN}[*] Decompiling $INPUT_APK into $WORK_DIR...${NC}"
rm -rf "$WORK_DIR"
apktool d "$INPUT_APK" -o "$WORK_DIR" -f

echo ""
echo -e "${CYAN}[*] Searching for device support and compatibility check classes...${NC}"
grep -rnE "(isNotSupportedOSVersion|isEOSPackage|getEosStartSdkVersion|getMaxSdkVersion|showEOSDialog)" "$WORK_DIR"/smali* 2>/dev/null | head -n 25 || true

echo ""
echo -e "${YELLOW}[!] Ready for manual/automated Smali patching in '$WORK_DIR'.${NC}"
echo "    Key targets:"
echo "    - Return 'const/4 v0, 0x1' on device capability and model validation methods."
echo "    - Bypass targetSdkVersion checks in AndroidManifest.xml if modifying manifest."
echo ""
echo -e "${YELLOW}[!] Note: re-signed APKs can't coexist with Samsung-signed apps in the shared UID com.samsung.accessory.wmanager.${NC}"
echo "    For first-time pairing problems, try Samsung Accessory Service 3.1.96.41110 first (no patching needed)."
read -rp "Press [Enter] when edits are finished to recompile and sign..."

mkdir -p dist
echo -e "${GREEN}[*] Building APK into $OUTPUT_APK...${NC}"
apktool b "$WORK_DIR" -o "$OUTPUT_APK"

# Android 11+ refuses APKs whose resources.arsc isn't uncompressed and 4-byte aligned.
if command -v zipalign &> /dev/null; then
    echo -e "${GREEN}[*] zipalign...${NC}"
    zipalign -f -p 4 "$OUTPUT_APK" "${OUTPUT_APK%.apk}_aligned.apk" && mv "${OUTPUT_APK%.apk}_aligned.apk" "$OUTPUT_APK"
else
    echo -e "${YELLOW}[!] zipalign not found (Android build-tools). Unaligned APKs fail to install on Android 11+.${NC}"
fi

echo -e "${GREEN}[*] Checking for signing tools (apksigner / jarsigner / uber-apk-signer)...${NC}"
KEYSTORE="debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    echo -e "${YELLOW}[*] Generating temporary debug keystore...${NC}"
    keytool -genkey -v -keystore "$KEYSTORE" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null || true
fi

if command -v apksigner &> /dev/null; then
    apksigner sign --ks "$KEYSTORE" --ks-pass pass:android --ks-key-alias androiddebugkey "$OUTPUT_APK"
    echo -e "${GREEN}[+] Signed with apksigner.${NC}"
elif command -v jarsigner &> /dev/null; then
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore "$KEYSTORE" -storepass android -keypass android "$OUTPUT_APK" androiddebugkey
    echo -e "${GREEN}[+] Signed with jarsigner.${NC}"
else
    echo -e "${YELLOW}[!] Notice: No apksigner/jarsigner found. Remember to sign $OUTPUT_APK before installing.${NC}"
fi

echo ""
echo -e "${GREEN}[SUCCESS] Modified APK ready at: $OUTPUT_APK${NC}"
