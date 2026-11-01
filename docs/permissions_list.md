# Android Permissions & AppOps Reference for Gear S Plugin

This reference lists all runtime permissions, specialized AppOps, and battery optimization exclusions required to ensure full functionality (calls, notifications, health sync, background connectivity) on modern Android versions (Android 13, 14, and 15 / One UI 6+).

---

## 1. Runtime Permissions (`pm grant`)

### Gear S Plugin (`com.samsung.android.gearsplugin`)

```bash
# Bluetooth connectivity & discovery
adb shell pm grant com.samsung.android.gearsplugin android.permission.BLUETOOTH_CONNECT
adb shell pm grant com.samsung.android.gearsplugin android.permission.BLUETOOTH_SCAN
adb shell pm grant com.samsung.android.gearsplugin android.permission.BLUETOOTH_ADVERTISE

# Location (required for Bluetooth LE beaconing & Wi-Fi transfer)
adb shell pm grant com.samsung.android.gearsplugin android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.samsung.android.gearsplugin android.permission.ACCESS_COARSE_LOCATION

# Notifications & Alerts
adb shell pm grant com.samsung.android.gearsplugin android.permission.POST_NOTIFICATIONS

# Telephony & Calls (Call forwarding, answering from watch)
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_PHONE_STATE
adb shell pm grant com.samsung.android.gearsplugin android.permission.CALL_PHONE
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_CALL_LOG
adb shell pm grant com.samsung.android.gearsplugin android.permission.WRITE_CALL_LOG

# Contacts & Messaging
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_CONTACTS
adb shell pm grant com.samsung.android.gearsplugin android.permission.WRITE_CONTACTS
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_SMS
adb shell pm grant com.samsung.android.gearsplugin android.permission.RECEIVE_SMS
adb shell pm grant com.samsung.android.gearsplugin android.permission.SEND_SMS

# Calendar & Scheduling
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_CALENDAR
adb shell pm grant com.samsung.android.gearsplugin android.permission.WRITE_CALENDAR

# Media & Storage (Watch face transfer, music sync)
adb shell pm grant com.samsung.android.gearsplugin android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.samsung.android.gearsplugin android.permission.WRITE_EXTERNAL_STORAGE

# Sensors & Activity
adb shell pm grant com.samsung.android.gearsplugin android.permission.BODY_SENSORS
adb shell pm grant com.samsung.android.gearsplugin android.permission.ACTIVITY_RECOGNITION
```

---

## 2. Android 13/14+ Restricted Settings (`appops`)

On Android 13 and later, sideloaded applications have critical accessibility and notification access blocked under the "Restricted Settings" security model. ADB can grant this permission directly:

```bash
adb shell appops set com.samsung.android.gearsplugin ACCESS_RESTRICTED_SETTINGS allow
adb shell appops set com.samsung.android.app.watchmanager ACCESS_RESTRICTED_SETTINGS allow
```

---

## 3. Battery Optimization / Doze Whitelist

To prevent One UI / Android from killing the background service that maintains the Bluetooth SAP connection:

```bash
adb shell dumpsys deviceidle whitelist +com.samsung.android.gearsplugin
adb shell dumpsys deviceidle whitelist +com.samsung.android.app.watchmanager
adb shell dumpsys deviceidle whitelist +com.samsung.accessory
```
