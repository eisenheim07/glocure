# Order Creation API Debugging Guide

## Issue
Order creation API works in Postman but fails in the Flutter app.

## Enhanced Logging

The order service now includes comprehensive logging to help identify the issue:

### 1. Cart Items Processing
```
🔍 Processing X cart items...
📦 Item 0: Product Name
   Variant ID (GID): gid://shopify/ProductVariant/123456
   Variant ID (Numeric): 123456
   ✅ Added to order: variant_id=123456, quantity=2
```

### 2. Address Validation
```
📍 Preparing shipping address...
   First Name: John
   Last Name: Doe
   Address1: 123 Street
   City: Mumbai
   Province: Maharashtra
   Country: India
   Zip: 400086
   Phone: 9876543210
```

### 3. API Request
```
═══════════════════════════════════════════════════════
📦 SHOPIFY ORDER CREATION REQUEST
═══════════════════════════════════════════════════════
🔗 Endpoint: https://glocure.com/admin/api/2025-10/orders.json
📧 Email: customer@example.com
📦 Items: 2
💳 Payment Method: Pre-paid
📍 Shipping: Mumbai, 400086
───────────────────────────────────────────────────────
📝 Payload:
{
  "order": {
    "email": "customer@example.com",
    "line_items": [...],
    ...
  }
}
═══════════════════════════════════════════════════════
```

### 4. API Response
```
═══════════════════════════════════════════════════════
📥 SHOPIFY ORDER CREATION RESPONSE
═══════════════════════════════════════════════════════
📊 Status Code: 422
⏱️ Response Time: 1234ms
📏 Response Length: 567 bytes
───────────────────────────────────────────────────────
📝 Response Body:
{
  "errors": {
    "field_name": ["error message"]
  }
}
═══════════════════════════════════════════════════════
```

## Common Issues & Solutions

### Issue 1: Invalid Variant ID
**Symptom:** Error parsing variant ID
**Cause:** Variant ID is not in expected GID format
**Solution:** Check cart data - variant IDs should be like `gid://shopify/ProductVariant/123456`

**Check logs for:**
```
❌ Failed to parse variant ID: FormatException
```

### Issue 2: Missing Email
**Symptom:** Validation error on email field
**Cause:** Customer email is null or empty
**Solution:** Ensure customer object has valid email

**Check logs for:**
```
❌ Customer email is required
```

### Issue 3: Invalid Address
**Symptom:** Validation error on address fields
**Cause:** Required address fields are missing
**Solution:** Ensure address has: address1, city, zip

**Check logs for:**
```
❌ Invalid shipping address
```

### Issue 4: Authentication Error (401)
**Symptom:** 401 status code
**Cause:** Invalid or expired access token
**Solution:** Verify `ApiConfig.shopifyAdminAccessToken`

**Check logs for:**
```
❌ AUTHENTICATION ERROR (401)
Access token may be invalid or expired
```

### Issue 5: Permission Error (403)
**Symptom:** 403 status code
**Cause:** Access token doesn't have order creation permission
**Solution:** Check Shopify API access scopes - needs `write_orders`

**Check logs for:**
```
❌ PERMISSION ERROR (403)
Access token does not have permission to create orders
```

### Issue 6: Validation Error (422)
**Symptom:** 422 status code with error details
**Cause:** Invalid data in request
**Solution:** Check the specific field errors in logs

**Check logs for:**
```
❌ VALIDATION ERROR (422)
Full Response: {...}
Errors Object: {...}
```

## Debugging Steps

### Step 1: Check Console Logs
Run the app and click "Proceed to Pay" → Select payment method. Check the console for:
1. Cart items processing logs
2. Address validation logs
3. API request payload
4. API response with status code
5. Error details if any

### Step 2: Compare with Postman
Compare the logged payload from the app with your working Postman request:
- Are variant IDs the same format?
- Is the email present and valid?
- Are address fields identical?
- Are headers the same?

### Step 3: Verify Data
Check if the issue is with the data:
```dart
// In order_summary_screen.dart, before calling PaymentSelectionBottomSheet.show()
debugPrint('Cart: ${cart.lines.length} items');
debugPrint('Customer Email: ${_customer?.email}');
debugPrint('Address Zip: ${_customer?.defaultAddress?.zip}');
```

### Step 4: Test with Minimal Data
Try creating an order with just one product to isolate the issue.

### Step 5: Check API Version
Verify the API version in the endpoint:
- Current: `https://glocure.com/admin/api/2025-10/orders.json`
- Postman: Check if using the same version

## What to Share for Help

If the issue persists, share these logs:
1. Full console output from "📦 SHOPIFY ORDER CREATION REQUEST" to "📥 SHOPIFY ORDER CREATION RESPONSE"
2. The status code and error response
3. Your working Postman request (hide sensitive data)
4. Cart data structure
5. Customer data structure

## Quick Fixes

### Fix 1: Ensure Email is Present
```dart
// In order_service.dart - already added
if (customer.email == null || customer.email!.isEmpty) {
  throw Exception('Customer email is required');
}
```

### Fix 2: Handle Empty Address2
```dart
// In order_service.dart - already added
// Only include address2 if it's not empty
if (address.address2 != null && address.address2!.isNotEmpty) {
  shippingAddress['address2'] = address.address2!;
}
```

### Fix 3: Provide Default Names
```dart
// In order_service.dart - already added
'first_name': address.firstName ?? customer.firstName ?? 'Customer',
'last_name': address.lastName ?? customer.lastName ?? 'Name',
```

## Testing Checklist

- [ ] Console shows cart items being processed
- [ ] Console shows address fields
- [ ] Console shows complete API payload
- [ ] Console shows API response with status code
- [ ] If error, console shows detailed error message
- [ ] Compare logged payload with Postman request
- [ ] Verify all variant IDs are numeric
- [ ] Verify email is present
- [ ] Verify address has required fields

## Next Steps

1. Run the app and trigger order creation
2. Copy the complete console logs
3. Share the logs to identify the exact issue
4. Compare with your working Postman request

The enhanced logging will help us pinpoint exactly where the issue is! 🔍
