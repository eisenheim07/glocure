# Testing Guide - Payment & Delivery Integration

## Quick Test Scenarios

### ✅ Scenario 1: Serviceable Area (Both Payment Methods Available)

**Test Pincode:** 110085 (Delhi) or 400086 (Mumbai)

**Expected Result:**
```
╔═══════════════════════════════════════════════════════╗
║  Select Payment Method                            ✕   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║  ┃  💳  Pre-paid                                → ┃ ║  ← BRIGHT PINK ICON
║  ┃      UPI / Online Payment                       ┃ ║  ← BLACK TEXT
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║  ← CLICKABLE ✓
║                                                       ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║  ┃  💵  Cash on Delivery                        → ┃ ║  ← BRIGHT PINK ICON
║  ┃      Pay when you receive                       ┃ ║  ← BLACK TEXT
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║  ← CLICKABLE ✓
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Console Log:**
```
✅ SERVICEABILITY CHECK RESULT
📮 Pincode: 110085
🏙️ City: Delhi
🗺️ State: Delhi
✓ Serviceable: YES ✓
💳 Payment Types Available: 5
   • Pre-paid
   • COD
   • Pickup
   • Cash
   • REPL
🎯 Supported Payment Methods:
   Pre-paid (UPI): ✓ Available
   COD: ✓ Available
```

---

### ❌ Scenario 2: Non-Serviceable Area

**Test Pincode:** Any non-serviceable pincode

**Expected Result:**
```
╔═══════════════════════════════════════════════════════╗
║  Select Payment Method                            ✕   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  ┌───────────────────────────────────────────────┐   ║
║  │  💳  Pre-paid                              🚫 │   ║  ← GRAY ICON (FADED)
║  │      UPI / Online Payment                     │   ║  ← GRAY TEXT (FADED)
║  └───────────────────────────────────────────────┘   ║  ← NOT CLICKABLE ✗
║                                                       ║
║  ┌───────────────────────────────────────────────┐   ║
║  │  💵  Cash on Delivery                      🚫 │   ║  ← GRAY ICON (FADED)
║  │      Pay when you receive                     │   ║  ← GRAY TEXT (FADED)
║  └───────────────────────────────────────────────┘   ║  ← NOT CLICKABLE ✗
║                                                       ║
║  ┌───────────────────────────────────────────────┐   ║
║  │  ⚠️  Delivery is unavailable at this pincode │   ║  ← RED ERROR BOX
║  └───────────────────────────────────────────────┘   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Console Log:**
```
✅ SERVICEABILITY CHECK RESULT
📮 Pincode: 123456
🏙️ City: N/A
🗺️ State: N/A
✓ Serviceable: NO ✗
💳 Payment Types Available: 0
🎯 Supported Payment Methods:
   Pre-paid (UPI): ✗ Not Available
   COD: ✗ Not Available
```

---

### ⚠️ Scenario 3: Network Error

**Test:** Disable internet or use invalid API token

**Expected Result:**
```
╔═══════════════════════════════════════════════════════╗
║  Select Payment Method                            ✕   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║                      ❌                               ║
║                                                       ║
║         Unable to check delivery availability         ║
║                                                       ║
║         Unable to check delivery availability:        ║
║         [Error message]                               ║
║                                                       ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║  ┃                    Retry                        ┃ ║  ← RETRY BUTTON
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

---

## Step-by-Step Testing

### Test 1: Serviceable Area with UPI Apps

1. ✅ Ensure Google Pay or PhonePe is installed
2. ✅ Add items to cart
3. ✅ Set address with pincode: 110085
4. ✅ Navigate to Order Summary
5. ✅ Click "Proceed to Pay"
6. ✅ Verify loading state appears
7. ✅ Verify both options are enabled (bright, clickable)
8. ✅ Click "Pre-paid"
9. ✅ Verify UPI app selection appears
10. ✅ Select a UPI app
11. ✅ Verify success message

### Test 2: Serviceable Area with COD

1. ✅ Add items to cart
2. ✅ Set address with pincode: 400086
3. ✅ Navigate to Order Summary
4. ✅ Click "Proceed to Pay"
5. ✅ Verify loading state appears
6. ✅ Verify both options are enabled
7. ✅ Click "Cash on Delivery"
8. ✅ Verify success message
9. ✅ Verify bottom sheet closes

### Test 3: Non-Serviceable Area

1. ✅ Add items to cart
2. ✅ Set address with non-serviceable pincode
3. ✅ Navigate to Order Summary
4. ✅ Click "Proceed to Pay"
5. ✅ Verify loading state appears
6. ✅ **Verify both options are shown but FADED/GRAYED**
7. ✅ **Verify both options are NOT clickable**
8. ✅ **Verify block icon (🚫) instead of arrow**
9. ✅ **Verify red error message at bottom**
10. ✅ **Verify message: "Delivery is unavailable at this pincode"**

### Test 4: No UPI Apps Installed

1. ✅ Uninstall all UPI apps (or test on emulator)
2. ✅ Add items to cart
3. ✅ Set address with serviceable pincode
4. ✅ Navigate to Order Summary
5. ✅ Click "Proceed to Pay"
6. ✅ Click "Pre-paid"
7. ✅ Verify dialog: "No UPI Apps Found"
8. ✅ Verify message suggests installing UPI app

### Test 5: Validation Errors

**No Address:**
1. ✅ Login but don't add address
2. ✅ Add items to cart
3. ✅ Navigate to Order Summary
4. ✅ Click "Proceed to Pay"
5. ✅ Verify error: "Please add a delivery address with pincode"

**Empty Cart:**
1. ✅ Login and add address
2. ✅ Ensure cart is empty
3. ✅ Navigate to Order Summary
4. ✅ Click "Proceed to Pay"
5. ✅ Verify error: "Your cart is empty"

**Not Logged In:**
1. ✅ Logout
2. ✅ Try to access Order Summary
3. ✅ Verify error: "Please login to continue"

---

## Visual Indicators Checklist

### Enabled State (Serviceable)
- [ ] White background
- [ ] Pink icon with light pink background
- [ ] Black text (title)
- [ ] Gray text (subtitle)
- [ ] Arrow icon (→)
- [ ] Ripple effect on tap
- [ ] Cursor changes on hover (web)

### Disabled State (Non-Serviceable)
- [ ] Light gray background
- [ ] Gray icon with gray background
- [ ] Gray text (title)
- [ ] Gray text (subtitle)
- [ ] Block icon (🚫)
- [ ] No ripple effect
- [ ] No cursor change
- [ ] Cannot be clicked

### Error Message
- [ ] Light red background
- [ ] Red border
- [ ] Red error icon (⚠️)
- [ ] Red text
- [ ] Medium font weight
- [ ] Positioned below payment options

---

## Console Log Verification

### Check These Logs

1. **Request Log:**
   ```
   🚚 DELHIVERY API REQUEST
   📍 Endpoint: [URL]
   📮 Pincode: [pincode]
   ```

2. **Response Log:**
   ```
   📥 DELHIVERY API RESPONSE
   📊 Status Code: 200
   ⏱️ Response Time: [ms]
   📝 Response Body: [JSON]
   ```

3. **Result Log:**
   ```
   ✅ SERVICEABILITY CHECK RESULT
   ✓ Serviceable: YES/NO
   💳 Payment Types Available: [count]
   🎯 Supported Payment Methods:
      Pre-paid (UPI): ✓/✗
      COD: ✓/✗
   ```

---

## Common Issues & Solutions

### Issue: Bottom sheet doesn't open
**Solution:** Check console for validation errors

### Issue: Both options always disabled
**Solution:** 
- Check API token is correct
- Verify pincode format (6 digits)
- Check network connection

### Issue: UPI apps not detected
**Solution:**
- Test on physical device (not emulator)
- Ensure UPI apps are installed
- Check app permissions

### Issue: Error message not showing
**Solution:**
- Verify `fm_serviceable` is false in API response
- Check console logs for parsing errors

---

## Success Criteria

✅ All test scenarios pass  
✅ Visual states match specifications  
✅ Error messages are clear and helpful  
✅ Console logs show detailed information  
✅ User cannot proceed when non-serviceable  
✅ User can select payment when serviceable  

---

## Quick Test Commands

```bash
# Run the app
flutter run

# Check for errors
flutter analyze

# View logs
flutter logs
```

---

## Test Data

### Serviceable Pincodes (Test with these)
- 110085 (Delhi)
- 400086 (Mumbai)
- 560001 (Bangalore)
- 600001 (Chennai)

### Non-Serviceable Pincodes (Test with these)
- Try remote area pincodes
- Or mock the response to return `fm_serviceable: false`

---

## Final Checklist

Before marking as complete:

- [ ] Tested with serviceable pincode
- [ ] Tested with non-serviceable pincode
- [ ] Verified disabled state (faded, not clickable)
- [ ] Verified error message appears
- [ ] Verified error message text is correct
- [ ] Tested with UPI apps installed
- [ ] Tested without UPI apps
- [ ] Tested COD selection
- [ ] Tested all validation errors
- [ ] Verified console logs are detailed
- [ ] Tested on physical device
- [ ] Tested network error scenario
- [ ] Verified loading states
- [ ] Verified success messages

---

**Status:** ✅ Feature is fully implemented and ready for testing!
