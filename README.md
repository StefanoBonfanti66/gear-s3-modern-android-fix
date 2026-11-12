# Samsung Gear S3 Modern Phone Compatibility Toolkit (Android 14+ / 2024+)

[![Platform](https://img.shields.io/badge/Platform-Android%2014%2B%20%7C%20One%20UI%206%2B-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Gear%20S3%20Frontier%20%2F%20Classic-orange.svg)](https://www.samsung.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete toolkit, automated provisioner, and reverse engineering suite to reconnect and restore full functionality of the **Samsung Gear S3 (Frontier / Classic)** on modern Android smartphones released in 2024 and later (including **Galaxy Z Fold 6**, **Galaxy S24 series**, **Galaxy Z Flip 6**, Google Pixel, Xiaomi, etc.).

---

## 📖 The Problem (Planned Obsolescence)

Beginning in **2024**, Samsung officially dropped companion support for legacy Tizen wearables (Gear S2, Gear S3, Gear Sport, Gear Fit2) on smartphones running newer One UI / Android versions.

When pairing a Gear S3 with a 2024+ phone, users are met with a hard stop:
> *"This watch is not supported on this phone."*

### Key Technical Facts:
1. **The Gear S3 watch is NOT the blocker**: The watch firmware (Tizen) does not know what a 2024 phone is. When reset to factory defaults, it simply broadcasts standard Bluetooth discovery waiting for Samsung Accessory Protocol (SAP) handshakes.
2. **The restriction is 100% on Android**: Modern releases of `Galaxy Wearable` and `Gear S Plugin` on Google Play / Galaxy Store query device release dates and blacklist legacy watch models (`maxSdkVersion = 34`, `eosYear = 2024`).
3. **Android 14+ Security Restraints**: Sideloaded legacy plugins are prevented from running by default due to Android 14's Target SDK checks, "Restricted Settings" (AppOps), and aggressive battery optimization (Doze).

This repository provides **automated scripts** and **decompiled Smali patches** to bypass all these restrictions and restore full pairing, notifications, calls, and health sync.

---

## ✅ Confirmed root cause: stuck on "Finishing pairing" (Samsung Accessory Service)

Tested November 2026 on a **Gear S3 Frontier (SM-R760)** with a **Xiaomi 15, Android 16 (HyperOS)**:

| Symptom | Cause | Fix |
|---|---|---|
| Pairing hangs forever on **"Finishing pairing"** (last dot keeps animating, no error) | **Samsung Accessory Service 3.1.96.61123** rejects the resource file the watch sends during first-time setup | Pair once with **Samsung Accessory Service 3.1.96.41110**, then update everything again |

What happens (from `adb logcat` + decompiled code):
1. Bluetooth/SAP connection and the JSON handshake complete normally.
2. During first-time setup the watch sends `full_resource.zip` / `rsrc-default_001.zip` over SAP file transfer.
3. Accessory Service 3.1.96.61123 added an ownership check (`SAPlatformUtils.isAgentOwnedBy`) in
   `SAServiceNativeV2.getAgentDetails()`. Its own built-in file-transfer receiver can't look up the Gear S Plugin's agent anymore, so it rejects the transfer:
   ```
   SAServiceNativeV2: getAgentDetails(): com.samsung.accessory does not own agentId <id>
   FTConsumerImpl: SASP_ERROR: Package name not found. Rejecting transfer
   ```
4. Before the EULA is accepted, the Gear S Plugin (`SetupWizardConnectFragment`) waits for `MGR_APPS_ICON_RES`, which only fires after those resources arrive, so the Terms & Conditions screen never opens.
5. **3.1.96.41110** doesn't have that check: the transfer goes through and setup continues.

See [docs/evidence/](docs/evidence/) for the relevant log lines and [docs/technical_analysis.md](docs/technical_analysis.md#4-root-cause-of-the-finishing-pairing-hang-samsung-accessory-service) for details.

**After setup is done** you can update Galaxy Wearable and Accessory Service to the latest versions again: the watch stays connected and notifications keep working (tested with Galaxy Wearable 2.2.72.26092361 + Accessory Service 3.1.96.61123). That means newer Galaxy watches on the same phone keep working too. Only downgrade again if you reset or re-pair the Gear S3.

All APKs used are **unmodified, Samsung-signed** (certificate SHA-256 `34df0e7a9f1cf1892e45c056b4973cd81ccf148a4050d11aea4ac5a65f900a42`, check with `apksigner verify --print-certs`):

| App | Package | Version that worked | SHA-256 of the APK used |
|---|---|---|---|
| Samsung Accessory Service | `com.samsung.accessory` | **3.1.96.41110** | `dc2f2a6edfbe87d0fa46ae47e355cb9ffce8f23d233baa9d2fffc68404b572d5` |
| Galaxy Wearable | `com.samsung.android.app.watchmanager` | 2.2.57.23102461 | `4bb986ebb10255ceb64ecd2d240b8ddd4c66682aacba5a7c1b9a4a826df92f48` |
| Gear S Plugin | `com.samsung.android.gearoplugin` | 2.2.03.23121541N | `15270bf53dad76573ac5033189793cd4317b6c1cf8bf0b4923ad861c06b7bf4e` |

---

## 🚀 Two Methods to Fix

### Method A: Automated ADB Provisioning (Recommended)

Connect your phone to your PC via USB with **USB Debugging enabled** in Developer Options.

#### On Linux / macOS:
```bash
git clone https://github.com/stefanobonfanti66/gear-s3-modern-android-fix.git
cd gear-s3-modern-android-fix
./scripts/setup_linux_mac.sh
```

#### On Windows:
1. Clone or download the repository ZIP and extract it.
2. Double-click or run from command prompt:
```cmd
scripts\setup_windows.bat
```

The script will automatically:
- ✅ Detect connected Android devices via ADB.
- ✅ Auto-detect and prioritize **Modded APKs** in `dist/` (if compiled) or fallback to late-2023 stock APKs in `apks/`.
- ✅ Install companion APKs with `--bypass-low-target-sdk-block`.
- ✅ Automatically grant all runtime permissions (Bluetooth, Notifications, Contacts, SMS, Calls, Calendar, Storage, Sensors).
- ✅ Enable Android 13/14 **Restricted Settings** via `appops`.
- ✅ Whitelist the plugin and services from **battery optimization (Doze)** to guarantee permanent background connectivity.

---

### Method B: Manual On-Device Pairing (No PC Required)

If you don't have a PC available:

1. **Uninstall** any pre-existing *Galaxy Wearable* or *Gear S Plugin* apps.
2. **Download** the verified late-2023 APK releases (e.g. from APKMirror):
   - *Galaxy Wearable*: `v2.2.57.23102461`
   - *Gear S Plugin*: `v2.2.03.23121551` (or `v2.2.03.23112251`)
   - *Samsung Accessory Service*: **`v3.1.96.41110`**. ⚠️ Not the latest: 3.1.96.61123 makes pairing hang on "Finishing pairing" (see above). Uninstall the current one first, since a downgrade can't be installed over it.
3. **Enable Airplane Mode** on your phone, then turn **Bluetooth ON**.
4. **Change Date**: Temporarily set your phone's date to **December 2023** (Settings > General Management > Date and Time > Turn off Automatic date).
5. **Install the APKs** in order:
   - Install `Samsung Accessory Service 3.1.96.41110`.
   - Install `Galaxy Wearable` (do not open yet).
   - Install `Gear S Plugin`.
6. **Enable Restricted Settings (Android 14)**:
   - Go to `Settings > Apps > Galaxy Wearable > 3 dots (top right) > Allow restricted settings`.
   - Do the same for `Gear S Plugin`.
   - Manually grant all permissions.
7. **Pair the Watch**: Open Galaxy Wearable and complete setup.
8. **Restore Settings**: When the setup asks for a **Samsung account / Reactivation lock**, first restore **Automatic Date** and disable Airplane Mode. With a fake 2023 date the sign-in page can't load (TLS certificates aren't valid yet). With Galaxy Wearable 2.2.57 the fake date probably isn't needed at all.
9. **Optional:** once setup is complete you can update all apps to the latest versions again (see the root cause section above).

---

## 🛠️ Reverse Engineering: Bytecode Smali Patches

For developers who want permanent compatibility without changing dates or using airplane mode, we analyzed and patched the decompiled bytecode directly.

### The "Smoking Gun" in Smali:
* **`l3/a.smali`**: Defines the Gear S/S2/S3/Sport `WearableDeviceRule` with `0x22` (34, Android 14) and `eosYear = 0x7e8` (2024).
  ⚠️ **Correction (verified in Galaxy Wearable 2.2.57.23102461):** `0x22` is the 9th constructor argument, **`eosStartSdkVersion`**, not `maxSdkVersion`. `maxSdkVersion` uses the default (bitmask `0x3bfcf4`), which is **1000** (no limit), and `supportNonSamsung` defaults to `true`. `eosStartSdkVersion` is only used by `PlatformUtils.isEOSPackage()`, which blocks *downloading* the plugin from within the app; it doesn't block pairing if the plugin is already installed. `PairingProblemChecker` passes on Android 16 with this version, so the smali patches below aren't needed for it. They may still be relevant for newer Galaxy Wearable builds.
* **`WearableDevice.smali`**: Checks if `Build.VERSION.SDK_INT > maxSdkVersion`, throwing `UNSUPPORTED_OS_VERSION_OVER_MAX` (`0x7f110112`: *"This watch is not supported on this phone"*).
* **`HMRootActivity.smali`**: Calls `showEOSDialog()` displaying `popup_end_of_service_message`.

### Applied Patches:
1. `WearableDevice.isNotSupportedOSVersionOverMax()` -> Returns unconditional `false` (`0x0`).
2. `RuleUtil.isNotSupportedOSVersion()` -> Returns unconditional `false` (`0x0`).
3. `HMRootActivity.showEOSDialog()` & `HMFindMyWearableActivity.showEOSDialog()` -> Patched with immediate `return-void`.
4. Both APKs re-signed with a unified certificate (`gear_s3_custom.keystore`) matching `android:sharedUserId="com.samsung.accessory.wmanager"`.
   ⚠️ Galaxy Wearable, Gear S Plugin **and Samsung Accessory Service** all share `sharedUserId="com.samsung.accessory.wmanager"`, and Galaxy Wearable declares signature-level permissions (e.g. `com.samsung.android.app.watchmanager.permission.GALAXY_WEARABLE_PLUGIN`). A re-signed APK can't be installed next to Samsung-signed members of that shared UID (Android rejects the signature mismatch), so you'd have to re-sign all of them, and they'd stop receiving updates. The Accessory Service downgrade above avoids patching completely.

See [docs/technical_analysis.md](docs/technical_analysis.md) for full Smali diffs and detailed analysis.

---

## 🛡️ Preventing Future Incompatibility

After successful pairing, prevent automatic store updates from breaking your setup:

1. **Disable Auto-Updates in Google Play Store**:
   - Search for `Gear S Plugin` in the Play Store.
   - Tap the **3 dots** in the top right corner and **uncheck "Enable auto update"**.
2. **Disable Auto-Updates in Galaxy Store**:
   - Galaxy Store > Settings > Auto update apps > Set to **Never**.
3. **Battery Optimization**:
   - Settings > Apps > `Galaxy Wearable` & `Gear S Plugin` > Battery > Set to **Unrestricted**.

---

## 🆘 Standalone Mode (Emergency Watch Use)

> ⚠️ Unverified: the hidden "tap the watch icon 3-5 times" standalone setup wizard couldn't be confirmed. Treat it as a rumor until someone confirms it on a real device.

---

## 📂 Repository Structure

```text
gear-s3-modern-android-fix/
├── README.md                      # Main project documentation & user guide
├── LICENSE                        # MIT License
├── .gitignore                     # Git ignore rules for APKs, builds, keystores
├── apks/                          # Working directory for stock companion APKs
├── dist/                          # Target directory for patched/modded APKs
├── docs/
│   ├── technical_analysis.md      # Deep Smali & SAP architectural analysis
│   ├── evidence/                  # Log excerpts: failing vs. working Accessory Service
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
