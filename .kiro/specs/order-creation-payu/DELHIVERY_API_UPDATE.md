# Delhivery API Integration Update

## Changes Made

### 1. API Endpoint Update
- **Old Endpoint**: `https://track.delhivery.com/api/dc/fetch/serviceability/pincode`
- **New Endpoint**: `https://track.delhivery.com/c/api/pin-codes/json/`

### 2. Query Parameters
- **Old**: `?product_type=Heavy&pincode={pincode}`
- **New**: `?filter_codes={pincode}`

### 3. API Token Update
- **Old Token**: `9b0c726bc350e5f6a8d4fa8fe278666b3d6fd853`
- **New Token**: `2edc11122eef90a095d861f5d9ccbb09ddd0928a`

### 4. Response Structure Change

**Old Response:**
```json
{
  "success": true,
  "data": [{
    "fm_serviceable": true,
    "payment_type": ["COD", "Prepaid"]
  }]
}
```

**New Response:**
```json
{
  "delivery_codes": [{
    "postal_code": {
      "pin": 110085,
      "city": "Delhi",
      "state_code": "DL",
      "district": "North West Delhi",
      "cod": "Y",
      "pre_paid": "Y",
      "pickup": "Y",
      "cash": "Y",
      "is_oda": "N"
    }
  }]
}
```

### 5. Model Updates

**ServiceabilityModel** now uses:
- `codAvailable` (boolean) - from `cod` field ("Y" = true, "N" = false)
- `prepaidAvailable` (boolean) - from `pre_paid` field ("Y" = true, "N" = false)
- `pickupAvailable` (boolean) - from `pickup` field
- `cashAvailable` (boolean) - from `cash` field
- `isOda` (boolean) - from `is_oda` field (Out of Delivery Area)

### 6. Payment Option Logic

**In Payment Selection Bottom Sheet:**
- If `cod == "Y"` → COD option is enabled
- If `cod == "N"` → COD option is faded/disabled
- If `pre_paid == "Y"` → Pre-paid option is enabled
- If `pre_paid == "N"` → Pre-paid option is faded/disabled

## Files Modified

1. **lib/services/delivery_service.dart**
   - Updated API endpoint to `/c/api/pin-codes/json/`
   - Changed query parameter to `filter_codes`
   - Updated response parsing to handle `delivery_codes` array
   - Enhanced logging to show all payment method availability

2. **lib/config/api_config.dart**
   - Updated `delhiveryBaseUrl` to `https://track.delhivery.com`
   - Updated `delhiveryApiToken` to new token
   - Removed `delhiveryProductType` (no longer needed)

3. **lib/models/serviceability_model.dart**
   - Already updated in previous iteration
   - Parses `postal_code` object from response
   - Converts "Y"/"N" strings to boolean values

## Testing

Test with pincode: `110085`

Expected behavior:
- API call to: `https://track.delhivery.com/c/api/pin-codes/json/?filter_codes=110085`
- Response should show COD and Pre-paid availability
- Payment options in bottom sheet should be enabled/disabled accordingly

## Logging

Comprehensive logging includes:
- API request details (endpoint, method, pincode, token)
- Response details (status code, response time, headers, body)
- Parsed serviceability data (pincode, city, state, district)
- Payment method availability (Pre-paid, COD, Pickup, Cash)
- Additional info (Is ODA)

All logs use emoji prefixes for easy identification in console.
