# Android Manifest Setup for UPI App Detection

## Problem

On Android 11+ (API level 30+), apps cannot see other installed apps by default due to package visibility restrictions. This causes UPI app detection to fail even when apps are installed.

## Solution

Add package queries to `AndroidManifest.xml` to declare which apps we need to detect.

## Changes Made

### File: `android/app/src/main/AndroidManifest.xml`

Added the following `<queries>` section with UPI app package names:

```xml
<queries>
    <!-- Existing queries -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    
    <!-- UPI Payment Apps - Required for Android 11+ (API 30+) package visibility -->
    
    <!-- Google Pay -->
    <package android:name="com.google.android.apps.nbu.paisa.user" />
    
    <!-- PhonePe -->
    <package android:name="com.phonepe.app" />
    
    <!-- Paytm -->
    <package android:name="net.one97.paytm" />
    
    <!-- Amazon Pay -->
    <package android:name="in.amazon.mShop.android.shopping" />
    
    <!-- BHIM UPI -->
    <package android:name="in.org.npci.upiapp" />
    
    <!-- BHIM Axis Pay -->
    <package android:name="com.upi.axispay" />
    
    <!-- BHIM SBI Pay -->
    <package android:name="com.sbi.upi" />
    
    <!-- BHIM ICICI Pay -->
    <package android:name="com.csam.icici.bank.imobile" />
    
    <!-- BHIM HDFC Pay -->
    <package android:name="com.snapwork.hdfc" />
    
    <!-- WhatsApp (for WhatsApp Pay) -->
    <package android:name="com.whatsapp" />
    
    <!-- Generic UPI intent for any UPI app -->
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="upi" />
    </intent>
</queries>
```

## UPI Apps Supported

The following UPI apps are now detectable:

1. **Google Pay** - `com.google.android.apps.nbu.paisa.user`
2. **PhonePe** - `com.phonepe.app`
3. **Paytm** - `net.one97.paytm`
4. **Amazon Pay** - `in.amazon.mShop.android.shopping`
5. **BHIM** - `in.org.npci.upiapp`
6. **BHIM Axis Pay** - `com.upi.axispay`
7. **BHIM SBI Pay** - `com.sbi.upi`
8. **BHIM ICICI Pay** - `com.csam.icici.bank.imobile`
9. **BHIM HDFC Pay** - `com.snapwork.hdfc`
10. **WhatsApp Pay** - `com.whatsapp`

## How It Works

### Before (Android 10 and below)
- Apps could see all installed apps
- No manifest declarations needed
- `canLaunchUrl()` worked automatically

### After (Android 11+)
- Apps can only see explicitly declared packages
- Must add `<queries>` in manifest
- `canLaunchUrl()` only works for declared packages

## Testing After Changes

### Step 1: Rebuild the App

**IMPORTANT:** You must rebuild the app after manifest changes!

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Rebuild and run
flutter run
```

Or simply:
```bash
flutter run
```

### Step 2: Test UPI Detection

1. Open the app
2. Navigate to Order Summary
3. Click "Proceed to Pay"
4. Click "Pre-paid" option
5. Check console logs for detection results

### Expected Console Output

```
═══════════════════════════════════════════════════════
🔍 Checking for installed UPI apps...
═══════════════════════════════════════════════════════
Google Pay: ✓ Installed
PhonePe: ✓ Installed
Paytm: ✗ Not found
Amazon Pay: ✗ Not found
BHIM: ✗ Not found
WhatsApp Pay: ✓ Installed
───────────────────────────────────────────────────────
📱 Total UPI apps found: 3
Available apps:
   • Google Pay
   • PhonePe
   • WhatsApp Pay
═══════════════════════════════════════════════════════
```

## Troubleshooting

### Issue: Still showing "No UPI apps found"

**Solutions:**

1. **Rebuild the app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
   Manifest changes require a full rebuild!

2. **Check Android version**
   - Android 11+ (API 30+): Requires manifest queries
   - Android 10 and below: Should work without queries

3. **Verify UPI apps are installed**
   - Open Google Pay, PhonePe, etc. manually
   - Ensure they're not disabled

4. **Check manifest syntax**
   - Ensure `<queries>` is inside `<manifest>` but outside `<application>`
   - Check for XML syntax errors

5. **Check console logs**
   - Look for detailed detection logs
   - Each app shows ✓ or ✗ status

### Issue: Some apps detected, others not

**Possible causes:**

1. **App not installed** - Install the missing UPI app
2. **Wrong package name** - Verify package name is correct
3. **App disabled** - Enable the app in Android settings
4. **Custom ROM** - Some ROMs have different package names

### Issue: Build fails after manifest changes

**Check:**

1. **XML syntax** - Ensure all tags are properly closed
2. **Duplicate queries** - Don't add `<queries>` twice
3. **Location** - `<queries>` should be at manifest level, not inside `<application>`

## Adding More UPI Apps

To add support for additional UPI apps:

1. **Find the package name:**
   ```bash
   adb shell pm list packages | grep upi
   ```

2. **Add to manifest:**
   ```xml
   <package android:name="com.example.upiapp" />
   ```

3. **Add to widget code:**
   ```dart
   {
     'name': 'New UPI App',
     'package': 'com.example.upiapp',
     'scheme': 'newupiapp://',
   },
   ```

4. **Rebuild the app**

## Common UPI App Package Names

| App Name | Package Name |
|----------|-------------|
| Google Pay | `com.google.android.apps.nbu.paisa.user` |
| PhonePe | `com.phonepe.app` |
| Paytm | `net.one97.paytm` |
| Amazon Pay | `in.amazon.mShop.android.shopping` |
| BHIM | `in.org.npci.upiapp` |
| WhatsApp | `com.whatsapp` |
| Axis Pay | `com.upi.axispay` |
| SBI Pay | `com.sbi.upi` |
| ICICI Pay | `com.csam.icici.bank.imobile` |
| HDFC Pay | `com.snapwork.hdfc` |

## Enhanced Logging

The widget now includes detailed logging for debugging:

```dart
debugPrint('═══════════════════════════════════════════════════════');
debugPrint('🔍 Checking for installed UPI apps...');
debugPrint('═══════════════════════════════════════════════════════');

for (final app in upiApps) {
  final canLaunch = await canLaunchUrl(uri);
  debugPrint('${app['name']}: ${canLaunch ? "✓ Installed" : "✗ Not found"}');
}

debugPrint('📱 Total UPI apps found: ${availableApps.length}');
```

This helps identify:
- Which apps are detected
- Which apps are not found
- Total count of available apps
- Helpful troubleshooting tips

## Important Notes

1. **Rebuild Required**: Always rebuild after manifest changes
2. **Android 11+**: Queries are mandatory for API 30+
3. **Privacy**: Only declare apps you actually need to detect
4. **Testing**: Test on physical device (emulator may not have UPI apps)
5. **Production**: Ensure manifest is properly configured before release

## Verification Checklist

Before testing:
- [ ] Added `<queries>` section to AndroidManifest.xml
- [ ] Added all UPI app package names
- [ ] Saved the manifest file
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Rebuilt the app with `flutter run`
- [ ] Verified UPI apps are installed on device
- [ ] Checked console logs for detection results

## Summary

✅ Added package queries to AndroidManifest.xml  
✅ Declared 10+ popular UPI apps  
✅ Added generic UPI intent  
✅ Enhanced logging for debugging  
✅ Supports Android 11+ package visibility  

The app can now detect installed UPI apps on Android 11+ devices!
