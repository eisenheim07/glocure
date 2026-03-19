# Non-Serviceable Area Handling - Visual Guide

## ✅ Already Implemented!

The feature you requested is already fully implemented in the code. Here's how it works:

## How It Works

### Scenario: Non-Serviceable Area

When `fm_serviceable` is `false` in the API response:

```json
{
  "success": true,
  "data": [{
    "fm_serviceable": false,
    "payment_type": "[]",
    "pincode": "123456"
  }]
}
```

### UI Behavior

The bottom sheet will show:

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  💳  Pre-paid                              🚫 │ │  ← FADED/GRAYED OUT
│  │      UPI / Online Payment                     │ │  ← NOT CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  💵  Cash on Delivery                      🚫 │ │  ← FADED/GRAYED OUT
│  │      Pay when you receive                     │ │  ← NOT CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  ⚠️  Delivery is unavailable at this pincode │ │  ← RED ERROR MESSAGE
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Visual States

### Disabled Payment Option (Non-Serviceable)

**Container:**
- Background: Light gray (`Colors.grey.shade100`)
- Border: Light gray (`Colors.grey.shade200`)
- No tap interaction (onTap is null)

**Icon:**
- Background: Gray (`Colors.grey.shade200`)
- Icon color: Gray (`Colors.grey.shade400`)
- Shows block icon (🚫) instead of arrow

**Text:**
- Title color: Gray (`Colors.grey.shade400`)
- Subtitle color: Gray (`Colors.grey.shade400`)
- Appears faded/muted

### Error Message Box

**Container:**
- Background: Light red (`Colors.red.shade50`)
- Border: Red (`Colors.red.shade200`)
- Rounded corners (8px)
- Padding: 12px

**Content:**
- Error icon (⚠️) in red
- Text: "Delivery is unavailable at this pincode"
- Text color: Dark red (`Colors.red.shade700`)
- Font weight: Medium (500)

## Code Implementation

### 1. Check Serviceability
```dart
final isServiceable = serviceability.isServiceable; // false for non-serviceable
final supportsPrepaid = serviceability.supportsPrepaid;
final supportsCOD = serviceability.supportsCOD;
```

### 2. Build Payment Options with Disabled State
```dart
_buildPaymentOption(
  context: context,
  icon: Icons.payment,
  title: 'Pre-paid',
  subtitle: 'UPI / Online Payment',
  enabled: isServiceable && supportsPrepaid, // false = disabled
  onTap: () => _handlePrepaidSelection(context),
),
```

### 3. Show Error Message
```dart
if (!isServiceable) ...[
  const SizedBox(height: 20),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.red.shade200,
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Delivery is unavailable at this pincode',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

## Comparison: Serviceable vs Non-Serviceable

### Serviceable Area (fm_serviceable: true)

```
┌─────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────┐ │
│  │  💳  Pre-paid                              →  │ │  ← BRIGHT/ENABLED
│  │      UPI / Online Payment                     │ │  ← CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  💵  Cash on Delivery                      →  │ │  ← BRIGHT/ENABLED
│  │      Pay when you receive                     │ │  ← CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  (No error message)                                │
└─────────────────────────────────────────────────────┘
```

### Non-Serviceable Area (fm_serviceable: false)

```
┌─────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────┐ │
│  │  💳  Pre-paid                              🚫 │ │  ← FADED/DISABLED
│  │      UPI / Online Payment                     │ │  ← NOT CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  💵  Cash on Delivery                      🚫 │ │  ← FADED/DISABLED
│  │      Pay when you receive                     │ │  ← NOT CLICKABLE
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  ⚠️  Delivery is unavailable at this pincode │ │  ← ERROR MESSAGE
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Testing

### Test Non-Serviceable Area

1. **Find a non-serviceable pincode** (or mock the API response)
2. **Navigate to Order Summary** with that pincode in address
3. **Click "Proceed to Pay"**
4. **Observe:**
   - ✅ Bottom sheet opens
   - ✅ Both payment options are shown
   - ✅ Both options are grayed out/faded
   - ✅ Both options are not clickable
   - ✅ Block icon (🚫) shown instead of arrow
   - ✅ Red error message at bottom
   - ✅ Message: "Delivery is unavailable at this pincode"

### Mock Non-Serviceable Response

To test, you can temporarily modify the API response in `delivery_service.dart`:

```dart
// For testing only - remove after testing
return ServiceabilityModel(
  fmServiceable: false,  // Set to false
  paymentTypes: [],      // Empty array
  pincode: pincode,
  city: 'Test City',
  state: 'Test State',
);
```

## Color Scheme

### Enabled State
- Background: White
- Border: Gray (#E0E0E0)
- Icon background: Pink with 10% opacity
- Icon color: Pink (#FF5C9A)
- Text: Black
- Arrow: Gray

### Disabled State
- Background: Light gray (#F5F5F5)
- Border: Light gray (#EEEEEE)
- Icon background: Gray (#E0E0E0)
- Icon color: Gray (#BDBDBD)
- Text: Gray (#BDBDBD)
- Block icon: Light gray

### Error Message
- Background: Light red (#FFEBEE)
- Border: Red (#FFCDD2)
- Icon: Red (#C62828)
- Text: Dark red (#C62828)

## User Experience Flow

1. **User clicks "Proceed to Pay"**
2. **Loading state** (checking delivery...)
3. **API returns non-serviceable**
4. **Bottom sheet shows:**
   - Both payment options visible but disabled
   - Clear visual indication (faded, grayed out)
   - Block icon instead of arrow
   - Red error message explaining why
5. **User understands:**
   - Delivery is not available
   - Cannot proceed with payment
   - Needs to change address or pincode

## Summary

✅ **Already Implemented** - No code changes needed!  
✅ **Shows both options** - Pre-paid and COD always visible  
✅ **Faded/Grayed out** - Disabled state clearly visible  
✅ **Not clickable** - onTap is null when disabled  
✅ **Error message** - Red box at bottom with clear message  
✅ **User-friendly** - Clear visual feedback  

The feature works exactly as you requested! Test it with a non-serviceable pincode to see it in action.
