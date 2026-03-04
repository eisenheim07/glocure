# Payment & Delivery Integration - Quick Reference

## How to Use

### For Developers

#### Testing the Feature
1. Run the app: `flutter run`
2. Navigate to Order Summary screen (add items to cart first)
3. Click "Proceed to Pay" button
4. Observe the payment selection bottom sheet

#### Test Scenarios

**Scenario 1: Serviceable Area**
- Use pincode: `400086` (Mumbai)
- Expected: Both Pre-paid and COD options enabled
- Test Pre-paid: Should show UPI app selection
- Test COD: Should confirm selection

**Scenario 2: Non-Serviceable Area**
- Use pincode: `110001` (or any non-serviceable pincode)
- Expected: Both options disabled with error message

**Scenario 3: No Internet**
- Disable internet connection
- Click "Proceed to Pay"
- Expected: Error state with retry button

#### Modifying the Code

**Change API Token:**
```dart
// lib/config/api_config.dart
static const String delhiveryApiToken = 'YOUR_NEW_TOKEN';
```

**Change Product Type:**
```dart
// lib/config/api_config.dart
static const String delhiveryProductType = 'Light'; // or 'Heavy'
```

**Add More UPI Apps:**
```dart
// lib/widgets/payment_selection_bottom_sheet.dart
// In _getAvailableUpiApps() method, add:
{
  'name': 'New UPI App',
  'package': 'com.example.upiapp',
  'scheme': 'newupiapp://',
},
```

**Customize UI Colors:**
```dart
// Primary color (pink): Color(0xFFFF5C9A)
// Success color (green): Color(0xFF4CAF50)
// Error color: Colors.red
```

### For Product Managers

#### Feature Capabilities
- ✅ Checks delivery availability before payment
- ✅ Shows only available payment methods
- ✅ Prevents checkout for non-serviceable areas
- ✅ Supports UPI and Cash on Delivery
- ✅ Handles network errors gracefully

#### User Flow
1. User adds products to cart
2. User proceeds to Order Summary
3. User clicks "Proceed to Pay"
4. System checks delivery availability
5. User selects payment method
6. System confirms selection

#### Limitations
- Only checks default address pincode
- No payment processing (selection only)
- No order creation yet
- No delivery date estimation

### For QA/Testers

#### Test Cases

**TC-1: Valid Serviceable Pincode**
- Precondition: User logged in, cart has items, address has pincode 400086
- Steps: Click "Proceed to Pay"
- Expected: Bottom sheet shows enabled Pre-paid and COD options

**TC-2: Invalid/Non-Serviceable Pincode**
- Precondition: User logged in, cart has items, address has non-serviceable pincode
- Steps: Click "Proceed to Pay"
- Expected: Bottom sheet shows disabled options with error message

**TC-3: No Address**
- Precondition: User logged in, cart has items, no default address
- Steps: Click "Proceed to Pay"
- Expected: Error snackbar: "Please add a delivery address with pincode"

**TC-4: Empty Cart**
- Precondition: User logged in, cart is empty
- Steps: Click "Proceed to Pay"
- Expected: Error snackbar: "Your cart is empty"

**TC-5: Not Logged In**
- Precondition: User not logged in
- Steps: Click "Proceed to Pay"
- Expected: Error snackbar: "Please login to continue"

**TC-6: Network Timeout**
- Precondition: Slow/unstable network
- Steps: Click "Proceed to Pay", wait 30+ seconds
- Expected: Error state with timeout message and retry button

**TC-7: UPI App Selection (Apps Installed)**
- Precondition: Google Pay or PhonePe installed
- Steps: Click "Proceed to Pay" → Select "Pre-paid"
- Expected: Shows list of installed UPI apps

**TC-8: UPI App Selection (No Apps)**
- Precondition: No UPI apps installed
- Steps: Click "Proceed to Pay" → Select "Pre-paid"
- Expected: Dialog: "No UPI Apps Found"

**TC-9: COD Selection**
- Precondition: Serviceable area
- Steps: Click "Proceed to Pay" → Select "Cash on Delivery"
- Expected: Success snackbar, bottom sheet closes

**TC-10: Retry After Error**
- Precondition: Network error occurred
- Steps: Click "Retry" button in error state
- Expected: Loading state, then success/error based on network

#### Bug Report Template
```
Title: [Brief description]
Steps to Reproduce:
1. 
2. 
3. 

Expected Result:
Actual Result:
Pincode Used:
Device:
OS Version:
App Version:
Screenshots:
```

## API Reference

### Delhivery Serviceability API

**Endpoint:**
```
GET https://track.delhivery.com/api/dc/fetch/serviceability/pincode
```

**Query Parameters:**
- `product_type`: "Heavy" or "Light"
- `pincode`: 6-digit Indian pincode

**Headers:**
```
Accept: application/json
Authorization: Token 9b0c726bc350e5f6a8d4fa8fe278666b3d6fd853
```

**Success Response (200):**
```json
{
  "400086": {
    "fm_serviceable": true,
    "payment_type": "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]",
    "pincode": "400086",
    "city": "Mumbai",
    "state": "Maharashtra"
  }
}
```

**Non-Serviceable Response (200):**
```json
{
  "110001": {
    "fm_serviceable": false,
    "payment_type": "[]",
    "pincode": "110001"
  }
}
```

**Error Response (404):**
```json
{
  "error": "Pincode not found"
}
```

## Troubleshooting

### Issue: Bottom sheet doesn't open
**Solution:** Check console for validation errors (no address, empty cart, not logged in)

### Issue: Always shows "non-serviceable"
**Solution:** 
1. Check API token is correct
2. Verify pincode format (6 digits)
3. Check network connection
4. Try different pincode

### Issue: UPI apps not detected
**Solution:**
1. Ensure UPI apps are installed
2. Check app permissions
3. Try on physical device (not emulator)

### Issue: API timeout
**Solution:**
1. Check internet connection
2. Try again after some time
3. Check Delhivery API status

### Issue: "Unable to check delivery availability"
**Solution:**
1. Check network connection
2. Verify API token
3. Check API endpoint URL
4. Review console logs for detailed error

## Code Snippets

### Call Payment Selection from Any Screen
```dart
import '../widgets/payment_selection_bottom_sheet.dart';

// In your button onPressed:
PaymentSelectionBottomSheet.show(
  context,
  pincode: '400086',
  onPaymentSelected: (paymentMethod) {
    print('Selected: $paymentMethod');
    // Handle payment method
  },
);
```

### Check Serviceability Programmatically
```dart
import '../services/delivery_service.dart';

final service = DeliveryService();
try {
  final result = await service.checkServiceability('400086');
  if (result.isServiceable) {
    print('Delivery available');
    print('Supports Pre-paid: ${result.supportsPrepaid}');
    print('Supports COD: ${result.supportsCOD}');
  } else {
    print('Delivery not available');
  }
} catch (e) {
  print('Error: $e');
}
```

### Use Payment Selection Cubit Directly
```dart
import '../cubits/payment_selection/payment_selection_cubit.dart';

final cubit = PaymentSelectionCubit();
cubit.checkServiceability('400086');

// Listen to state changes
cubit.stream.listen((state) {
  if (state is PaymentSelectionSuccess) {
    print('Serviceable: ${state.serviceability.isServiceable}');
  } else if (state is PaymentSelectionError) {
    print('Error: ${state.message}');
  }
});
```

## Contact & Support

For issues or questions:
1. Check console logs for detailed error messages
2. Review implementation-summary.md for architecture details
3. Check design.md for UI/UX specifications
4. Review requirements.md for feature specifications
