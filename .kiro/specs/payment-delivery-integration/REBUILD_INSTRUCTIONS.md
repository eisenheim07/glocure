# 🚨 IMPORTANT: Rebuild Required for UPI Detection

## What Changed

Added Android manifest queries to detect installed UPI apps on Android 11+ devices.

## Why Rebuild is Needed

Android manifest changes are NOT hot-reloaded. You must rebuild the app completely for the changes to take effect.

## Quick Rebuild Steps

### Option 1: Clean Rebuild (Recommended)

```bash
flutter clean
flutter pub get
flutter run
```

### Option 2: Simple Rebuild

```bash
flutter run
```

## What to Expect After Rebuild

### Console Logs

When you click "Pre-paid", you'll see:

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

### UI Behavior

**If UPI apps found:**
- Pre-paid option expands
- Shows list of installed UPI apps
- Each app is clickable

**If no UPI apps found:**
- Pre-paid option expands
- Shows orange warning message
- Suggests installing UPI apps

## Changes Made

### 1. AndroidManifest.xml
Added package queries for 10+ UPI apps:
- Google Pay
- PhonePe
- Paytm
- Amazon Pay
- BHIM
- WhatsApp Pay
- And more...

### 2. Payment Selection Widget
Added enhanced logging to show:
- Which apps are detected
- Which apps are not found
- Total count
- Troubleshooting tips

## Troubleshooting

### Still showing "No UPI apps found"?

1. **Did you rebuild?**
   ```bash
   flutter clean
   flutter run
   ```

2. **Check console logs**
   - Look for the detection logs
   - See which apps are found

3. **Verify UPI apps are installed**
   - Open Google Pay, PhonePe manually
   - Ensure they work

4. **Check Android version**
   - Android 11+: Requires manifest queries ✓
   - Android 10 and below: Should work without queries

5. **Restart the app**
   - Close and reopen the app
   - Try again

## Testing Checklist

After rebuild:
- [ ] App launches successfully
- [ ] Navigate to Order Summary
- [ ] Click "Proceed to Pay"
- [ ] Click "Pre-paid" option
- [ ] Check console for detection logs
- [ ] Verify installed UPI apps appear
- [ ] Click a UPI app to test selection

## Files Modified

1. `android/app/src/main/AndroidManifest.xml` - Added `<queries>` section
2. `lib/widgets/payment_selection_bottom_sheet.dart` - Added logging

## Summary

✅ Added Android manifest queries for UPI app detection  
✅ Enhanced logging for debugging  
✅ Supports 10+ popular UPI apps  
⚠️ **REBUILD REQUIRED** - Manifest changes need full rebuild  

## Next Steps

1. Run `flutter clean && flutter run`
2. Test UPI app detection
3. Check console logs
4. Verify UI shows installed apps

---

**Remember:** Always rebuild after manifest changes! 🔄
