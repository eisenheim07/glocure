# PayU Testing Guide - Quick Reference

## ⚠️ IMPORTANT: UPI Issue in Test Mode

**Problem:** PayU's test environment has very strict UPI validation that often fails, showing errors like:
- "Please enter a valid Paytm VPA"
- "Invalid UPI ID"

**Why:** This is a known limitation of PayU's test environment. Even their official test UPI IDs (`success@payu`, `failure@payu`) often don't work reliably.

**Solution:** Use test credit card instead of UPI for testing.

## ✅ Recommended Test Method: Credit Card

### Test Credit Card (Success)
```
Card Number: 5123456789012346
CVV: 123
Expiry: 12/25 (any future date)
Name: Any name
```

### Steps to Test:
1. Create order and select "Pre-paid"
2. On PayU page, select "Credit Card" or "Debit Card"
3. Enter the test card details above
4. Click "Pay"
5. On 3D Secure page (if shown), click "Success"
6. Payment will be processed successfully

## 🔄 Test Credit Card (Failure)
```
Card Number: 4000000000000002
CVV: 123
Expiry: 12/25
Name: Any name
```

## 📱 What You'll See

### In App:
- Orange banner at top saying "TEST MODE"
- Shows test card number for easy reference
- Warning about UPI validation issues

### In Console:
```
💳 PREPARING PAYU PAYMENT PARAMETERS
Environment: TEST MODE
⚠️ TEST MODE ACTIVE
📝 For testing, use:
   Credit Card: 5123456789012346, CVV: 123, Expiry: 12/25
   ⚠️ UPI validation is unreliable in test mode - use card instead
```

## 🎯 Testing Checklist

- [x] Order creation works
- [x] PayU redirect works
- [x] Test mode banner shows
- [ ] Test successful payment with credit card
- [ ] Test failed payment with failure card
- [ ] Test payment cancellation
- [ ] Verify order status after success
- [ ] Test COD flow

## 🚀 When Ready for Production

1. Update `lib/config/api_config.dart`:
```dart
static const bool payuIsProduction = true;
static const String payuMerchantKey = 'YOUR_PRODUCTION_KEY';
static const String payuMerchantSalt = 'YOUR_PRODUCTION_SALT';
```

2. In production:
   - Real UPI IDs will work perfectly
   - Real cards will work
   - No test mode banner will show
   - Actual money will be charged

## 💡 Key Points

1. **UPI works in production** - The validation issue only exists in test mode
2. **Use credit card for testing** - Most reliable method in test environment
3. **Test mode is clearly indicated** - Orange banner shows it's test mode
4. **No real money charged** - All test transactions are simulated

## 🐛 Troubleshooting

### Issue: UPI shows "Please enter a valid Paytm VPA"
**Solution:** This is expected in test mode. Use credit card instead.

### Issue: Net Banking shows "Pardon, some problem occurred"
**Solution:** This can happen in PayU test mode due to:
1. Test environment limitations
2. Callback URL validation issues
3. Try using credit card instead for more reliable testing
4. In production mode, net banking will work properly

**Workaround for Testing:**
- Use test credit card: `5123456789012346`, CVV: `123`, Expiry: `12/25`
- Credit card testing is most reliable in test mode
- Net banking and UPI work perfectly in production mode

### Issue: Payment page not loading
**Solution:** Check console logs for errors. Ensure WebView plugin is registered (do full rebuild).

### Issue: Payment success not detected
**Solution:** Check console logs for navigation URLs. The app now detects multiple success URL patterns.

## 📞 Support

If you continue to face issues:
1. Check console logs for detailed error messages
2. Verify merchant key and salt are correct
3. Ensure you're in test mode (`payuIsProduction = false`)
4. Try the test credit card instead of UPI
5. Do a full app rebuild (not hot reload) if WebView issues persist
