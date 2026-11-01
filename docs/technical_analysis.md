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
* `maxSdkVersion = 0x22` (34, Android 14)
* `eosYear = 0x7e8` (2024)
* `productLaunchYear = 0x7de` (2014-2016)

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
