# API Response Structure Update

## Changes Made

Updated the Delhivery API response parsing to handle the correct response structure.

## Actual API Response Structure

```json
{
  "error": "",
  "success": true,
  "data": [
    {
      "center": "Delhi_Sector31_L (Delhi)",
      "city": "Delhi",
      "state": "Delhi",
      "locality": "",
      "wt": 0,
      "pincode": "110085",
      "fm_serviceable": true,
      "payment_type": "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]",
      "center_code": "INDLBCCU",
      "self_collect_enabled": false
    }
  ]
}
```

## Key Fields

### Response Root
- `success` (boolean): Indicates if API call was successful
- `error` (string): Error message if any
- `data` (array): Array containing serviceability information

### Data Object
- `fm_serviceable` (boolean): **Main flag** - true if delivery is available
- `payment_type` (string): JSON string array of available payment methods
- `pincode` (string): The pincode checked
- `city` (string): City name
- `state` (string): State name
- `center` (string): Delivery center information
- `center_code` (string): Center code

## Payment Types

The `payment_type` field contains a JSON string array with possible values:
- `"Pre-paid"` - Online payment/UPI (we show this as "Pre-paid")
- `"COD"` - Cash on Delivery (we show this as "Cash on Delivery")
- `"Pickup"` - Self pickup (not shown in UI)
- `"Cash"` - Cash payment (not shown in UI)
- `"REPL"` - Replacement (not shown in UI)

## Implementation Logic

### 1. Parse Response
```dart
final data = json.decode(response.body);
final success = data['success'] ?? false;
final dataList = data['data'];
final serviceabilityData = dataList[0]; // Get first item from array
```

### 2. Check Serviceability Flag
```dart
final fmServiceable = serviceabilityData['fm_serviceable'] ?? false;
```

### 3. Parse Payment Types
```dart
// payment_type comes as: "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]"
// We parse it to: ["Pre-paid", "COD", "Pickup", "Cash", "REPL"]
final paymentTypeStr = serviceabilityData['payment_type'].toString();
final cleaned = paymentTypeStr
    .replaceAll('[', '')
    .replaceAll(']', '')
    .replaceAll('"', '')
    .replaceAll('\\', '');
final paymentTypes = cleaned.split(',').map((e) => e.trim()).toList();
```

### 4. Check Available Payment Methods
```dart
final supportsPrepaid = paymentTypes.contains('Pre-paid');
final supportsCOD = paymentTypes.contains('COD');
```

### 5. Show UI Based on Flags

**If `fm_serviceable` is true:**
- Show Pre-paid option (enabled if `supportsPrepaid` is true)
- Show COD option (enabled if `supportsCOD` is true)

**If `fm_serviceable` is false:**
- Show both options as disabled
- Display error: "Delivery is unavailable at this pincode"

## Example Scenarios

### Scenario 1: Serviceable with Both Payment Methods
```json
{
  "success": true,
  "data": [{
    "fm_serviceable": true,
    "payment_type": "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]"
  }]
}
```
**Result**: Both Pre-paid and COD options enabled ✓

### Scenario 2: Serviceable with Only Pre-paid
```json
{
  "success": true,
  "data": [{
    "fm_serviceable": true,
    "payment_type": "[\"Pre-paid\", \"Pickup\", \"Cash\"]"
  }]
}
```
**Result**: Pre-paid enabled ✓, COD disabled ✗

### Scenario 3: Non-Serviceable
```json
{
  "success": true,
  "data": [{
    "fm_serviceable": false,
    "payment_type": "[]"
  }]
}
```
**Result**: Both options disabled ✗, error message shown

### Scenario 4: API Error
```json
{
  "success": false,
  "error": "Invalid pincode",
  "data": []
}
```
**Result**: Error state with retry button

## Console Logs

When you click "Proceed to Pay", you'll see detailed logs:

```
═══════════════════════════════════════════════════════
🚚 DELHIVERY API REQUEST
═══════════════════════════════════════════════════════
📍 Endpoint: https://track.delhivery.com/api/dc/fetch/serviceability/pincode?product_type=Heavy&pincode=110085
🔑 Method: GET
📦 Product Type: Heavy
📮 Pincode: 110085
🔐 Authorization: Token 9b0c726bc3...
⏰ Timestamp: 2026-03-01T14:30:45.123Z
═══════════════════════════════════════════════════════

═══════════════════════════════════════════════════════
📥 DELHIVERY API RESPONSE
═══════════════════════════════════════════════════════
📊 Status Code: 200
⏱️ Response Time: 1234ms
📏 Response Length: 456 bytes
───────────────────────────────────────────────────────
📄 Response Headers:
   content-type: application/json
───────────────────────────────────────────────────────
📝 Response Body:
{
  "error": "",
  "success": true,
  "data": [
    {
      "center": "Delhi_Sector31_L (Delhi)",
      "city": "Delhi",
      "state": "Delhi",
      "pincode": "110085",
      "fm_serviceable": true,
      "payment_type": "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]"
    }
  ]
}
═══════════════════════════════════════════════════════
───────────────────────────────────────────────────────
🔍 Parsing Response Structure...
   Success: true
   Error: 
═══════════════════════════════════════════════════════
✅ SERVICEABILITY CHECK RESULT
═══════════════════════════════════════════════════════
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
───────────────────────────────────────────────────────
🎯 Supported Payment Methods:
   Pre-paid (UPI): ✓ Available
   COD: ✓ Available
═══════════════════════════════════════════════════════
```

## Files Updated

1. **`lib/services/delivery_service.dart`**
   - Updated response parsing to handle `{success, error, data[]}` structure
   - Added comprehensive logging for debugging
   - Added error handling for API errors

2. **`lib/models/serviceability_model.dart`**
   - Already correctly parses `payment_type` JSON string array
   - Provides helper methods: `supportsPrepaid`, `supportsCOD`

## Testing

Test with these pincodes:
- **110085** (Delhi) - Should show both Pre-paid and COD enabled
- **400086** (Mumbai) - Should show both Pre-paid and COD enabled
- Any non-serviceable pincode - Should show disabled options with error

## Summary

✅ Correctly parses the actual API response structure  
✅ Checks `fm_serviceable` flag  
✅ Extracts and parses `payment_type` array  
✅ Shows only Pre-paid and COD options in UI  
✅ Enables/disables based on availability  
✅ Comprehensive logging for debugging  
✅ Proper error handling  

The implementation now correctly handles the real Delhivery API response and will show the appropriate payment options based on what's available for each pincode!
