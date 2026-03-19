# Payment & Delivery Integration - Design

## Architecture Overview

This feature follows the project's BLoC/Cubit architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Order Summary Screen                      │
│  - Validates customer & address                              │
│  - Triggers payment flow on "Proceed to Pay"                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Payment Selection Bottom Sheet                  │
│  - Shows loading state during API call                       │
│  - Displays payment options based on serviceability          │
│  - Handles UPI app detection and selection                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Payment Selection Cubit                         │
│  - Manages state (Initial, Loading, Success, Error)         │
│  - Calls Delivery Service                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Delivery Service                            │
│  - Makes HTTP GET request to Delhivery API                   │
│  - Handles timeout and errors                                │
│  - Returns ServiceabilityModel                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│               Serviceability Model                           │
│  - Parses API response                                       │
│  - Provides helper methods (isServiceable, supportsPrepaid)  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. API Configuration (`lib/config/api_config.dart`)
- Stores Delhivery API constants
- Base URL: `https://track.delhivery.com/api/dc/fetch`
- API Token: `9b0c726bc350e5f6a8d4fa8fe278666b3d6fd853`
- Product Type: `Heavy`

### 2. Serviceability Model (`lib/models/serviceability_model.dart`)
**Purpose**: Represents delivery serviceability data

**Properties**:
- `fmServiceable`: Boolean indicating if delivery is available
- `paymentTypes`: List of available payment methods
- `pincode`, `city`, `state`: Location details

**Methods**:
- `fromJson()`: Parses API response (handles JSON string array for payment_type)
- `isServiceable`: Getter for serviceability status
- `supportsPrepaid`: Checks if Pre-paid is available
- `supportsCOD`: Checks if COD is available

### 3. Delivery Service (`lib/services/delivery_service.dart`)
**Purpose**: Handles Delhivery API communication

**Method**: `checkServiceability(String pincode)`
- Constructs API URL with query parameters
- Sets required headers (Accept, Authorization)
- 30-second timeout
- Parses response (handles pincode-keyed object structure)
- Returns `ServiceabilityModel`
- Handles errors: timeout, 404 (non-serviceable), other errors

### 4. Payment Selection State (`lib/cubits/payment_selection/payment_selection_state.dart`)
**States**:
- `PaymentSelectionInitial`: Default state
- `PaymentSelectionLoading`: Checking serviceability
- `PaymentSelectionSuccess`: Contains ServiceabilityModel
- `PaymentSelectionError`: Contains error message

### 5. Payment Selection Cubit (`lib/cubits/payment_selection/payment_selection_cubit.dart`)
**Purpose**: Manages payment selection state

**Methods**:
- `checkServiceability(String pincode)`: Validates pincode, calls service, emits states
- `reset()`: Returns to initial state

### 6. Payment Selection Bottom Sheet (`lib/widgets/payment_selection_bottom_sheet.dart`)
**Purpose**: UI for payment method selection

**Features**:
- Static `show()` method for easy invocation
- BlocProvider creates cubit locally
- Rounded top corners (24px radius)
- Handle bar for visual feedback

**UI States**:
- **Loading**: Circular progress indicator with message
- **Success**: Payment options with enable/disable logic
- **Error**: Error message with retry button

**Payment Options**:
- **Pre-paid**: 
  - Icon: `Icons.payment`
  - Checks for installed UPI apps
  - Shows UPI app selection if available
  - Shows "No UPI apps" dialog if none found
- **COD**:
  - Icon: `Icons.money`
  - Directly selects COD method

**UPI App Detection**:
- Checks common UPI apps: Google Pay, PhonePe, Paytm, Amazon Pay, BHIM
- Uses `url_launcher` to check if app schemes can be launched
- Shows secondary bottom sheet for UPI app selection

**Error Handling**:
- Non-serviceable: Shows disabled options with red error message
- API error: Shows error state with retry button

### 7. Order Summary Screen Updates (`lib/screens/order_summary_screen.dart`)
**New Method**: `_handleProceedToPay(BuildContext context, Cart cart)`

**Validations**:
1. Customer must be logged in
2. Default address must exist with valid pincode
3. Cart must not be empty

**Flow**:
- Validates prerequisites
- Calls `PaymentSelectionBottomSheet.show()`
- Passes pincode from customer's default address
- Provides callback for payment method selection

## Data Flow

### Happy Path (Serviceable Area with Pre-paid)
```
1. User clicks "Proceed to Pay"
2. Screen validates customer, address, cart
3. Bottom sheet opens
4. Cubit calls Delivery Service with pincode
5. Service makes API request to Delhivery
6. API returns: {"400086": {"fm_serviceable": true, "payment_type": "[\"Pre-paid\", \"COD\"]"}}
7. Service parses response into ServiceabilityModel
8. Cubit emits PaymentSelectionSuccess
9. Bottom sheet shows enabled Pre-paid and COD options
10. User taps Pre-paid
11. System checks for UPI apps
12. UPI apps found: Google Pay, PhonePe
13. Secondary bottom sheet shows UPI app list
14. User selects Google Pay
15. Callback fires with "UPI_Google Pay"
16. Both bottom sheets close
17. Success snackbar shown
```

### Error Path (Non-serviceable Area)
```
1. User clicks "Proceed to Pay"
2. Screen validates customer, address, cart
3. Bottom sheet opens
4. Cubit calls Delivery Service with pincode
5. Service makes API request to Delhivery
6. API returns: {"110001": {"fm_serviceable": false, "payment_type": "[]"}}
7. Service parses response into ServiceabilityModel
8. Cubit emits PaymentSelectionSuccess (with fmServiceable=false)
9. Bottom sheet shows disabled Pre-paid and COD options
10. Red error message displayed: "Delivery is unavailable at this pincode"
11. User cannot proceed with payment
```

## UI/UX Design

### Bottom Sheet Design
- **Background**: White
- **Border Radius**: 24px (top corners only)
- **Handle Bar**: 40x4px, gray, centered at top
- **Header**: 20px font, bold, with close button
- **Divider**: 1px gray line below header

### Payment Option Cards
- **Enabled State**:
  - Background: White
  - Border: 1.5px gray
  - Icon background: Pink (10% opacity)
  - Icon color: Pink (#FF5C9A)
  - Text: Black
  - Tap: Shows ripple effect

- **Disabled State**:
  - Background: Light gray
  - Border: 1px light gray
  - Icon background: Gray
  - Icon color: Gray
  - Text: Gray
  - No tap interaction

### Error Message
- **Background**: Red (5% opacity)
- **Border**: 1px red
- **Icon**: Error outline, red
- **Text**: Red, medium weight
- **Message**: "Delivery is unavailable at this pincode"

### Loading State
- **Indicator**: Circular progress, pink color
- **Text**: "Checking delivery availability..."
- **Padding**: 40px all sides

## Error Handling

### Network Errors
- Timeout (30s): "Request timeout. Please check your internet connection."
- No internet: "Unable to check delivery availability"
- API error: Shows status code in error message

### Validation Errors
- No customer: "Please login to continue"
- No address: "Please add a delivery address with pincode"
- Empty cart: "Your cart is empty"

### UPI App Errors
- No UPI apps: Shows dialog with installation suggestion
- Can't launch UPI app: Gracefully handles error

## Security Considerations

1. **API Token**: Stored in `api_config.dart` (should be in .gitignore)
2. **HTTPS Only**: All API calls use HTTPS
3. **Timeout**: 30-second timeout prevents hanging requests
4. **Input Validation**: Pincode validated before API call
5. **Error Messages**: Generic messages, no sensitive data exposed

## Performance Considerations

1. **Lazy Loading**: Cubit created only when bottom sheet opens
2. **Timeout**: 30-second timeout prevents long waits
3. **Efficient Parsing**: Direct JSON parsing without heavy libraries
4. **UPI Detection**: Checks only common apps, not exhaustive search
5. **State Management**: Minimal state, disposed when bottom sheet closes

## Future Enhancements

1. **Caching**: Cache serviceability results by pincode
2. **Retry Logic**: Automatic retry on network failure
3. **Analytics**: Track payment method selection
4. **More Payment Options**: Credit/Debit cards, Wallets
5. **Delivery Date**: Show estimated delivery date
6. **Pincode Edit**: Allow user to change pincode inline
