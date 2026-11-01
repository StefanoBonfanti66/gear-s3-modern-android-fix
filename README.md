# Samsung Gear S3 Modern Phone Compatibility Toolkit (Android 14+ / 2024+)

[![Platform](https://img.shields.io/badge/Platform-Android%2014%2B%20%7C%20One%20UI%206%2B-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Gear%20S3%20Frontier%20%2F%20Classic-orange.svg)](https://www.samsung.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete toolkit and reverse engineering guide to reconnect and restore full functionality of the **Samsung Gear S3 (Frontier / Classic)** on modern Android smartphones released in 2024 and later (including **Galaxy Z Fold 6**, **Galaxy S24 series**, **Galaxy Z Flip 6**, Google Pixel, Xiaomi, etc.).

---

## 📖 The Problem (Planned Obsolescence)

Beginning in **2024**, Samsung officially dropped companion support for legacy Tizen wearables (Gear S2, Gear S3, Gear Sport, Gear Fit2) on smartphones running newer One UI / Android versions.

When pairing a Gear S3 with a 2024+ phone, users are met with a hard stop:
> *"This phone does not support this watch."*

### Key Technical Facts:
1. **The Gear S3 watch is NOT the blocker**: The watch firmware (Tizen) does not know what a 2024 phone is. When reset to factory defaults, it simply broadcasts standard Bluetooth discovery waiting for Samsung Accessory Protocol (SAP) handshakes.
2. **The restriction is 100% on Android**: Modern releases of `Galaxy Wearable` and `Gear S Plugin` on Google Play / Galaxy Store query device release dates and blacklist legacy watch models.
3. **Android 14+ Security Restraints**: Sideloaded legacy plugins are prevented from running by default due to Android 14's Target SDK checks, "Restricted Settings" (AppOps), and aggressive battery optimization (Doze).

This repository provides **automated scripts** and **reverse engineering workflows** to bypass all these restrictions and restore full pairing, notifications, calls, and health sync.

---

## 🚀 Quick Start (Automated ADB Method)

Connect your phone to your PC via USB with **USB Debugging enabled** in Developer Options.

### On Linux / macOS:
```bash
git clone https://github.com/YOUR_USERNAME/Galaxy_S3_Reverse_Eng.git
cd Galaxy_S3_Reverse_Eng
./scripts/setup_linux_mac.sh
```

### On Windows:
1. Clone or download the repository ZIP and extract it.
2. Double-click or run from command prompt:
```cmd
scripts\setup_windows.bat
```

The script will automatically:
- ✅ Detect your connected device.
- ✅ Install the compatible companion APKs with `--bypass-low-target-sdk-block`.
- ✅ Grant all required permissions (Bluetooth, Notifications, Contacts, SMS, Calls, Calendar, Storage, Sensors).
- ✅ Enable Android 13/14 **Restricted Settings** via `appops`.
- ✅ Whitelist the plugin from **battery optimization** (prevents background disconnections).

---

## 📱 Manual Method (No PC Required)

If you don't have a PC available, you can perform the initial pairing directly from the phone:

1. **Uninstall** any pre-existing *Galaxy Wearable* or *Gear S Plugin* apps.
2. **Download** the verified late-2023 APK releases (e.g. from APKMirror):
   - *Galaxy Wearable*: `v2.2.57.23102461`
   - *Gear S Plugin*: `v2.2.03.23121551` (or `v2.2.03.23112251`)
   - *Samsung Accessory Service*: Latest from store.
3. **Enable Airplane Mode** on your phone, then turn **Bluetooth ON**.
4. **Change Date**: Temporarily set your phone's date to **December 2023** (Settings > General Management > Date and Time > Turn off Automatic date).
5. **Install the APKs** in order:
   - Install `Galaxy Wearable` (do not open yet).
   - Install `Gear S Plugin`.
6. **Enable Restricted Settings (Android 14)**:
   - Go to `Settings > Apps > Galaxy Wearable > 3 dots (top right) > Allow restricted settings`.
   - Do the same for `Gear S Plugin`.
   - Manually grant all permissions.
7. **Pair the Watch**: Open Galaxy Wearable and complete setup.
8. **Restore Settings**: Once you see the watch face, restore **Automatic Date** and disable Airplane Mode.

---

## 🛡️ Preventing Future Incompatibility

After successful pairing, protect your setup:

1. **Disable Auto-Updates in Google Play Store**:
   - Search for `Gear S Plugin` in the Play Store.
   - Tap the **3 dots** in the top right corner and **uncheck "Enable auto update"**.
2. **Disable Auto-Updates in Galaxy Store**:
   - Galaxy Store > Settings > Auto update apps > Set to **Never**.
3. **Battery Optimization**:
   - Settings > Apps > `Galaxy Wearable` & `Gear S Plugin` > Battery > Set to **Unrestricted**.

---

## 🛠️ Reverse Engineering & Custom Patching

For developers interested in modifying or distributing a patched `Gear S Plugin` APK that removes the certificate check entirely:

See [docs/technical_analysis.md](docs/technical_analysis.md) for deep technical notes on:
- Samsung Accessory Protocol (SAP) packet flow.
- Android 14 AppOps and SDK limits.
- Smali bytecode inspection of device verification logic.

Use the provided patch script:
```bash
./scripts/patch_plugin.sh apks/gear_s_plugin.apk
```

---

## 🆘 Standalone Mode (Emergency Watch Use)

If you factory reset the Gear S3 and don't have a phone available:
1. On the initial pairing screen (watch icon on display), **tap the watch icon 3-5 times** repeatedly (or rotate the bezel while holding the screen).
2. The watch will launch the hidden **Standalone Setup Wizard**.
3. You can use the watch completely offline without a companion phone.

---

## 📂 Repository Structure

```text
├── README.md                      # Main project documentation
├── LICENSE                        # MIT License
├── .gitignore                     # Git ignore rules for APKs & builds
├── apks/                          # Working directory for companion APKs
├── docs/
│   ├── technical_analysis.md      # Protocol & Android 14+ architectural analysis
│   └── permissions_list.md        # Comprehensive permission & AppOps command reference
└── scripts/
    ├── setup_linux_mac.sh         # Linux / macOS automated ADB provisioner
    ├── setup_windows.bat          # Windows automated ADB provisioner
    └── patch_plugin.sh            # Smali decompiler and patch assistant
```

---

## ⚖️ License & Disclaimer

This project is licensed under the [MIT License](LICENSE). 

*Disclaimer: This repository is for educational and interoperability purposes under fair use and right-to-repair principles. Samsung, Gear, Galaxy, and Tizen are trademarks of Samsung Electronics Co., Ltd.*
