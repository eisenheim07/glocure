# PayU Test Mode Credentials

## Current Configuration
- **Environment**: TEST MODE ✅
- **Merchant Key**: `nF8ogF`
- **Merchant Salt**: `r4CQCenbDSnnxL1I8q7ATB4j2oHV7fba`
- **Payment URL**: `https://test.payu.in/_payment`

## Test Payment Methods

### 1. UPI (Test Mode)
⚠️ **IMPORTANT: UPI testing in PayU test mode is unreliable and often shows validation errors.**

PayU's test environment has strict UPI validation that often fails even with their official test UPI IDs:
- `success@payu` - Often shows "Please enter a valid Paytm VPA" error
- `failure@payu` - May not work consistently

**Recommendation:** Use test credit card instead of UPI for testing in test mode.

**Note:** UPI will work perfectly in production mode with real UPI IDs. The validation issue only exists in test environment.

### 2. Credit Card (Test Mode)

**Successful Transaction:**
- Card Number: `5123456789012346`
- CVV: `123`
- Expiry: Any future date (e.g., `12/25`)
- Name: Any name

**Failed Transaction:**
- Card Number: `4000000000000002`
- CVV: `123`
- Expiry: Any future date
- Name: Any name

### 3. Debit Card (Test Mode)

**Successful Transaction:**
- Card Number: `4012001037141112`
- CVV: `123`
- Expiry: Any future date (e.g., `05/26`)
- Name: Any name

### 4. Net Banking (Test Mode)

**Test Banks Available:**
- Select any bank from the list
- Use test credentials provided on the bank's test page
- Most test banks will have a "Success" and "Failure" button

**⚠️ Known Issue in Test Mode:**
Net banking in PayU test mode can sometimes show "Pardon, some problem occurred" error even when trying to simulate success. This is a limitation of PayU's test environment and does not affect production.

**Recommendation:** Use credit card for testing. Net banking works perfectly in production mode.

## Payment Flow in Test Mode

### For UPI:
1. Select UPI payment option
2. Enter test UPI ID: `success@payu`
3. Click Pay
4. Payment will be processed as successful

### For Cards:
1. Select Credit/Debit Card
2. Enter test card details (see above)
3. Click Pay
4. You may see a 3D Secure page - click "Success" button
5. Payment will be processed

### For Net Banking:
1. Select Net Banking
2. Choose any bank
3. On the bank's test page, click "Success" button
4. Payment will be processed

## Important Notes

1. **Test Mode Limitations:**
   - Real UPI IDs won't work
   - Real card numbers won't work
   - No actual money is charged
   - All transactions are simulated
   - ⚠️ **UPI validation is very strict and unreliable in test mode - use credit card for testing**

2. **Production Mode:**
   - When you switch to production (`payuIsProduction = true`)
   - Use production merchant key and salt
   - Real payment methods will work
   - Actual money will be charged

3. **Current Payment Options Enabled:**
   - ✅ UPI
   - ✅ Credit Cards
   - ✅ Debit Cards
   - ✅ Net Banking
   - ❌ Wallets (disabled)
   - ❌ EMI (disabled)
   - ❌ Cash Cards (disabled)

## Testing Checklist

- [ ] Test UPI payment with `success@payu`
- [ ] Test UPI failure with `failure@payu`
- [ ] Test Credit Card with test card number
- [ ] Test Debit Card with test card number
- [ ] Test Net Banking with any test bank
- [ ] Verify order status updates after successful payment
- [ ] Verify error handling for failed payments
- [ ] Verify payment cancellation flow

## Switching to Production

When ready for production:

1. Update `lib/config/api_config.dart`:
```dart
static const bool payuIsProduction = true;
```

2. Update merchant credentials:
```dart
static const String payuMerchantKey = 'YOUR_PRODUCTION_KEY';
static const String payuMerchantSalt = 'YOUR_PRODUCTION_SALT';
```

3. Test with real payment methods
4. Verify all flows work correctly

## Support

If you face issues:
- Check PayU test mode documentation: https://docs.payu.in/docs/test-cards
- Verify merchant key and salt are correct
- Check console logs for detailed error messages
- Ensure you're using test credentials in test mode
