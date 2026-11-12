# Technical Analysis: Gear S3 Compatibility on Modern Android (2024+)

## 1. Introduction & Context
The **Samsung Gear S3** (Frontier `SM-R760`, Classic `SM-R770`, LTE `SM-R765`) is a smartwatch powered by **Tizen OS** (up to Tizen 4.0.0.7). Despite remaining physically capable with robust hardware (AMOLED display, rotating bezel, speaker, microphone, NFC, MST, GPS, HRM), Samsung announced an intentional deprecation cutoff starting with devices released in **2024** (e.g., Galaxy S24 series, Galaxy Z Fold 6, Galaxy Z Flip 6).

When attempting to pair a Gear S3 with a 2024+ phone running Android 14+ (One UI 6.x / One UI 7.x), the Galaxy Wearable app refuses connection with an incompatibility notice:
> *"This watch is not supported on this phone."*

---

## 2. Smali Bytecode Disassembly & Smoking Gun Findings

Through disassembly with `apktool`, we located the exact classes and logic responsible for this artificial deprecation in both **Galaxy Wearable** (`com.samsung.android.app.watchmanager`) and **Gear S Plugin** (`com.samsung.android.gearoplugin`).

### A. The EOS (End Of Service) Rule Definition: `l3/a.smali`
Inside Galaxy Wearable, Samsung defines device capability matrices directly in bytecode:

```smali
# File: com/samsung/android/app/twatchmanager/rules/l3/a.smali
new-instance v1, Lcom/samsung/android/app/twatchmanager/rules/WearableDeviceRule;
const-string v30, "com.samsung.android.gearoplugin"
const-string v31, "Gear S Plugin"
...
const/16 v38, 0x22    # 0x22 = 34 (Android 14 / API 34 maxSdkVersion!)
const/16 v39, 0x7e8   # 0x7e8 = 2024 (eosYear: End-of-Service Year!)
...
const-string v2, "Gear S3"
invoke-interface {v0, v2, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
```

Samsung explicitly hardcoded:
* `0x22` (34, Android 14): see the correction below, this is **`eosStartSdkVersion`**
* `eosYear = 0x7e8` (2024)
* `productLaunchYear = 0x7de` (2014-2016)

> **Correction (verified in Galaxy Wearable 2.2.57.23102461):** the call is to the Kotlin synthetic constructor
> `WearableDeviceRule.<init>(..., int mask, DefaultConstructorMarker)` with default mask `0x3bfcf4`.
> Mapping the registers to parameters gives `v38` = parameter 9 = **`eosStartSdkVersion` = 34** and `v39` = parameter 10 = **`eosYear` = 2024**.
> `maxSdkVersion` (parameter 8) has its mask bit set, so it uses the default **`0x3e8` = 1000** (no limit).
> `supportNonSamsung` (parameter 6) also uses the default: **`true`**.
>
> `eosStartSdkVersion` is read in exactly one place: `l3/a.p(String)`, called by `PlatformUtils.isEOSPackage()`, which
> `UpdateDownLoadURLTask` uses to refuse **downloading** the plugin (`DOWNLOAD_FAIL_BY_EOS_PACKAGE`).
> `eosYear` is only formatted into a dialog string (`HMConnectFragment`).
> So with this Galaxy Wearable version, `isNotSupportedOSVersionOverMax()` is `false` on Android 16, and pairing isn't blocked as long as the Gear S Plugin is already installed.

### B. The Runtime Check: `WearableDevice.smali` & `RuleUtil$Companion.smali`
When pairing starts, `WearableDevice.smali` verifies if the current phone's Android SDK exceeds `maxSdkVersion`:

```smali
# File: com/samsung/android/app/twatchmanager/connectionmanager/define/WearableDevice.smali
.method public isNotSupportedOSVersionOverMax()Z
    .locals 3

    iget-object v0, p0, Lcom/samsung/android/app/twatchmanager/connectionmanager/define/WearableDevice;->rule:Lcom/samsung/android/app/twatchmanager/rules/WearableDeviceRule;
    if-eqz v0, :cond_0

    invoke-virtual {v0}, Lcom/samsung/android/app/twatchmanager/rules/WearableDeviceRule;->getMaxSdkVersion()I
    move-result v0
    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    # If phone SDK_INT > maxSdkVersion (34), flag as UNSUPPORTED!
    if-ge v0, v1, :cond_0
    ...
```

If `SDK_INT > maxSdkVersion`, `PairingProblemChecker.smali` maps the status to:
`Problem.UNSUPPORTED_OS_VERSION_OVER_MAX`, triggering the error dialog (`0x7f110112` - *"This watch is not supported on this phone."*).

### C. The Plugin EOS Dialog: `HMRootActivity.smali`
In `com.samsung.android.gearoplugin`:
```smali
# File: com/samsung/android/gearoplugin/activity/HMRootActivity.smali
.method private showEOSDialog()V
    ...
    # String 0x7f110752 = popup_end_of_service_message
    const v5, 0x7f110752
    invoke-virtual {v4, v5}, Landroid/content/res/Resources;->getString(I)Ljava/lang/String;
```

---

## 3. How the Smali Patches Work

To bypass this check permanently without requiring clock manipulations:

1. **In `WearableDevice.smali`**:
   Force `isNotSupportedOSVersionOverMax()` to unconditionally return `false`:
   ```smali
   .method public isNotSupportedOSVersionOverMax()Z
       .locals 1
       const/4 v0, 0x0
       return v0
   .end method
   ```

2. **In `RuleUtil$Companion.smali`**:
   Force `isNotSupportedOSVersion()` to return `false`:
   ```smali
   .method public final isNotSupportedOSVersion(Lcom/samsung/android/app/twatchmanager/rules/WearableDeviceRule;)Z
       .locals 1
       const/4 v0, 0x0
       return v0
   .end method
   ```

3. **In `HMRootActivity.smali`**:
   Stub `showEOSDialog()` to immediately return:
   ```smali
   .method private showEOSDialog()V
       .locals 0
       return-void
   .end method
   ```


---

## 4. Root cause of the "Finishing pairing" hang: Samsung Accessory Service

Tested November 2026: Gear S3 Frontier (SM-R760) + Xiaomi 15, Android 16. With the Galaxy Wearable / Gear S Plugin versions above, pairing still hung forever on **"Finishing pairing"** (last dot animating, no error). `adb logcat` showed:

1. The SAP connection and the JSON handshake complete normally (`mgr_watch_info`, `mgr_wearable_status`, `mgr_status_exchange_done`, `mgr_wearable_ready_for_restore_res`).
2. The watch then pushes `full_resource.zip` and `rsrc-default_001.zip` through the SAP file transfer profile (`/system/filetransfer`).
3. **Samsung Accessory Service 3.1.96.61123** rejects each transfer:
   ```
   SAServiceNativeV2: getAgentDetails(): com.samsung.accessory does not own agentId <id>
   FTConsumerImpl: tid:1[null] null
   FTConsumerImpl: SASP_ERROR: Package name not found. Rejecting transfer
   ```

### Why
`FTConsumerImpl.handleSetupRequest()` (inside `com.samsung.accessory`) resolves the destination agent with
`SAManagerAgent.getAgentPackagename(peerId)` -> `getAgentDetails()` -> framework `SAServiceNativeV2.getAgentDetails(long, String)`.

In 3.1.96.61123 that framework method contains:
```smali
invoke-static {p2, p1}, Lcom/samsung/accessory/platform/SAPlatformUtils;->isPackageNameRight(Ljava/lang/String;I)Z
...
invoke-static {p3, p1}, Lcom/samsung/accessory/platform/SAPlatformUtils;->isAgentOwnedBy(Ljava/lang/String;Ljava/lang/String;)Z
if-nez p1, :cond_0
    # "<caller> does not own agentId <id>" -> returns an EMPTY Bundle
```
The caller is Accessory Service's own file-transfer consumer (`com.samsung.accessory`), but the target agent
(`HMSAPProviderService`) belongs to `com.samsung.android.gearoplugin`. So the ownership check fails, the bundle has no
`packageName`, and the transfer is rejected.

In **3.1.96.41110** the same method only calls `isPackageNameRight(String)` and then `getAgentDetails()`, with no ownership check.
With it the transfer is routed correctly:
```
FTConsumerImpl: tid:6[com.samsung.android.gearoplugin] com.samsung.android.hostmanager.service.HMSAPProviderService
SAFTManager: onFileRequest [com.samsung.android.gearoplugin] peerId:<id>
```

### Why that freezes the setup UI
In Gear S Plugin 2.2.03.23121541N, `SetupWizardConnectFragment$2.onReceive()`:
* on `SAPCONNECT` (Ready_For_Restore): proceeds **only if `getIsEulaPassed()` is true**, which isn't the case on a first setup;
* on `MGR_APPS_ICON_RES` (broadcast after the resources/icons from the watch are processed): calls `setView(3002)`.

`setView(3002)` posts `launchNextActivity()` after 3 s, which opens `launchOOBETermsAndCondition` when the EULA isn't passed yet.
Because the resources never arrive, `MGR_APPS_ICON_RES` never fires and the screen waits forever.

### Fix
Install Samsung Accessory Service **3.1.96.41110** (Samsung-signed, same certificate as the rest of the shared UID), pair, then optionally update again.
After first-time setup the Gear S3 keeps working with Accessory Service 3.1.96.61123 + Galaxy Wearable 2.2.72.26092361 (notifications tested).
Features that rely on SAP file transfer (sending watch faces/apps from the phone, media sync) weren't tested on 3.1.96.61123 and may fail.

Log excerpts: [evidence/](evidence/).
