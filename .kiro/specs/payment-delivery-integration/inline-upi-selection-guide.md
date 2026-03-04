# Inline UPI App Selection - Implementation Guide

## ✅ Feature Implemented!

UPI apps now expand inline below the Pre-paid option instead of showing a separate bottom sheet.

## Visual Flow

### Step 1: Initial State (Serviceable Area)

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💳  Pre-paid                              ▼  ┃ │  ← CLICKABLE
│  ┃      UPI / Online Payment                     ┃ │  ← Down arrow
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💵  Cash on Delivery                      →  ┃ │  ← CLICKABLE
│  ┃      Pay when you receive                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 2: User Clicks Pre-paid (Loading UPI Apps)

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💳  Pre-paid                              ▲  ┃ │  ← EXPANDED (Pink border)
│  ┃      UPI / Online Payment                     ┃ │  ← Up arrow
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │                                               │ │
│  │              ⏳ Loading...                    │ │  ← LOADING STATE
│  │                                               │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💵  Cash on Delivery                      →  ┃ │
│  ┃      Pay when you receive                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 3: UPI Apps Loaded and Displayed

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💳  Pre-paid                              ▲  ┃ │  ← EXPANDED (Pink border)
│  ┃      UPI / Online Payment                     ┃ │  ← Up arrow
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Select UPI App                               │ │  ← LIGHT PINK BOX
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │  💰  Google Pay                      →  │ │ │  ← UPI APP 1
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │  💰  PhonePe                         →  │ │ │  ← UPI APP 2
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │  💰  Paytm                           →  │ │ │  ← UPI APP 3
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💵  Cash on Delivery                      →  ┃ │
│  ┃      Pay when you receive                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 4: No UPI Apps Found

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💳  Pre-paid                              ▲  ┃ │  ← EXPANDED
│  ┃      UPI / Online Payment                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  ℹ️  No UPI apps found. Please install a    │ │  ← ORANGE WARNING BOX
│  │     UPI app like Google Pay, PhonePe, or     │ │
│  │     Paytm.                                    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💵  Cash on Delivery                      →  ┃ │
│  ┃      Pay when you receive                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 5: User Clicks Pre-paid Again (Collapse)

```
┌─────────────────────────────────────────────────────┐
│  Select Payment Method                          ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💳  Pre-paid                              ▼  ┃ │  ← COLLAPSED
│  ┃      UPI / Online Payment                     ┃ │  ← Down arrow
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│  ┃  💵  Cash on Delivery                      →  ┃ │
│  ┃      Pay when you receive                     ┃ │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Key Features

### 1. Inline Expansion
- ✅ UPI apps show directly below Pre-paid option
- ✅ No separate bottom sheet
- ✅ Smooth expand/collapse animation
- ✅ Toggle behavior (click to expand, click again to collapse)

### 2. Visual Indicators
- ✅ **Collapsed**: Down arrow (▼)
- ✅ **Expanded**: Up arrow (▲)
- ✅ **Expanded**: Pink border (2px) around Pre-paid option
- ✅ **Collapsed**: Gray border (1.5px)

### 3. UPI Apps Container
- ✅ Light pink background (5% opacity)
- ✅ Pink border (20% opacity)
- ✅ "Select UPI App" label
- ✅ List of installed UPI apps

### 4. UPI App Items
- ✅ White background
- ✅ Gray border
- ✅ Wallet icon with pink background
- ✅ App name
- ✅ Arrow icon
- ✅ Clickable with ripple effect

### 5. Loading State
- ✅ Shows circular progress indicator
- ✅ Displayed while checking for UPI apps
- ✅ Pink color matching theme

### 6. No UPI Apps State
- ✅ Orange warning box
- ✅ Info icon
- ✅ Helpful message suggesting app installation
- ✅ Lists example apps (Google Pay, PhonePe, Paytm)

## Implementation Details

### State Management

```dart
class _PaymentSelectionBottomSheetState extends State<PaymentSelectionBottomSheet> {
  bool _showUpiApps = false;              // Controls expansion
  List<Map<String, String>> _availableUpiApps = [];  // Stores UPI apps
  bool _isLoadingUpiApps = false;         // Loading state
}
```

### Expand/Collapse Logic

```dart
Future<void> _handlePrepaidSelection(BuildContext context, bool enabled) async {
  if (!enabled) return;

  // Toggle: If already expanded, collapse
  if (_showUpiApps) {
    setState(() {
      _showUpiApps = false;
    });
    return;
  }

  // Expand and load UPI apps
  setState(() {
    _showUpiApps = true;
    _isLoadingUpiApps = true;
  });

  final upiApps = await _getAvailableUpiApps();

  if (mounted) {
    setState(() {
      _availableUpiApps = upiApps;
      _isLoadingUpiApps = false;
    });
  }
}
```

### UPI App Detection

```dart
Future<List<Map<String, String>>> _getAvailableUpiApps() async {
  final upiApps = [
    {'name': 'Google Pay', 'scheme': 'gpay://'},
    {'name': 'PhonePe', 'scheme': 'phonepe://'},
    {'name': 'Paytm', 'scheme': 'paytm://'},
    {'name': 'Amazon Pay', 'scheme': 'amazonpay://'},
    {'name': 'BHIM', 'scheme': 'bhim://'},
  ];

  final availableApps = <Map<String, String>>[];
  for (final app in upiApps) {
    final uri = Uri.parse(app['scheme']!);
    if (await canLaunchUrl(uri)) {
      availableApps.add(app);
    }
  }

  return availableApps;
}
```

## User Experience Flow

1. **User clicks "Proceed to Pay"**
2. **Bottom sheet opens** with payment options
3. **User clicks "Pre-paid"**
4. **Pre-paid option expands** (border turns pink, arrow flips up)
5. **Loading indicator** appears briefly
6. **UPI apps list** appears below Pre-paid option
7. **User sees only installed apps** (Google Pay, PhonePe, etc.)
8. **User selects a UPI app**
9. **Bottom sheet closes**
10. **Success message** shown

## Color Scheme

### Pre-paid Option (Expanded)
- Border: Pink (#FF5C9A) - 2px
- Background: White
- Icon: Pink with light pink background

### Pre-paid Option (Collapsed)
- Border: Gray - 1.5px
- Background: White
- Icon: Pink with light pink background

### UPI Apps Container
- Background: Pink (#FF5C9A) with 5% opacity
- Border: Pink (#FF5C9A) with 20% opacity
- Padding: 12px
- Border radius: 8px

### UPI App Item
- Background: White
- Border: Gray (#E0E0E0) - 1px
- Icon background: Pink with 10% opacity
- Icon: Pink (#FF5C9A)
- Text: Black
- Arrow: Gray

### No UPI Apps Warning
- Background: Orange (#FFF3E0)
- Border: Orange (#FFE0B2) - 1px
- Icon: Orange (#F57C00)
- Text: Orange (#F57C00)

## Testing Checklist

### Test Scenario 1: With UPI Apps Installed
- [ ] Click "Proceed to Pay"
- [ ] Click "Pre-paid" option
- [ ] Verify Pre-paid expands with pink border
- [ ] Verify arrow changes from ▼ to ▲
- [ ] Verify loading indicator appears briefly
- [ ] Verify UPI apps list appears below
- [ ] Verify only installed apps are shown
- [ ] Click a UPI app
- [ ] Verify bottom sheet closes
- [ ] Verify success message appears

### Test Scenario 2: Without UPI Apps
- [ ] Uninstall all UPI apps (or test on emulator)
- [ ] Click "Proceed to Pay"
- [ ] Click "Pre-paid" option
- [ ] Verify Pre-paid expands
- [ ] Verify orange warning box appears
- [ ] Verify message suggests installing UPI apps
- [ ] Verify no app list is shown

### Test Scenario 3: Expand and Collapse
- [ ] Click "Pre-paid" to expand
- [ ] Verify UPI apps list appears
- [ ] Click "Pre-paid" again
- [ ] Verify UPI apps list collapses
- [ ] Verify arrow changes back to ▼
- [ ] Verify border returns to gray

### Test Scenario 4: Non-Serviceable Area
- [ ] Use non-serviceable pincode
- [ ] Click "Proceed to Pay"
- [ ] Verify Pre-paid is disabled (grayed out)
- [ ] Click Pre-paid (should not expand)
- [ ] Verify no UPI apps list appears
- [ ] Verify error message at bottom

## Advantages of Inline Expansion

✅ **Better UX**: No context switch with separate bottom sheet  
✅ **Clearer Flow**: User sees payment method and UPI apps in same view  
✅ **Less Confusing**: No multiple layers of bottom sheets  
✅ **Faster**: No animation delay for new bottom sheet  
✅ **More Intuitive**: Expand/collapse pattern is familiar  
✅ **Space Efficient**: Uses available space effectively  

## Summary

The UPI app selection now works inline:
- Click Pre-paid → Expands below
- Shows only installed UPI apps
- Click UPI app → Selects and closes
- Click Pre-paid again → Collapses

This provides a smoother, more intuitive user experience compared to the previous separate bottom sheet approach!
