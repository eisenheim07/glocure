# Payment & Delivery Integration - Requirements

## Overview
Integrate Delhivery delivery serviceability check and payment gateway selection on the Order Summary screen. Users can proceed to payment only if delivery is available at their pincode.

## User Stories

### US-1: Check Delivery Serviceability
**As a** user  
**I want to** check if delivery is available at my pincode  
**So that** I can proceed with payment only if delivery is possible

**Acceptance Criteria:**
- When user clicks "Proceed to Pay" button on Order Summary screen
- System calls Delhivery API to check serviceability for user's pincode
- API endpoint: `https://track.delhivery.com/api/dc/fetch/serviceability/pincode`
- Parameters: `product_type=Heavy&pincode={user_pincode}`
- Authorization: `Token 9b0c726bc350e5f6a8d4fa8fe278666b3d6fd853`
- Show loading indicator during API call

### US-2: Display Payment Options (Serviceable Area)
**As a** user in a serviceable area  
**I want to** see available payment options  
**So that** I can choose my preferred payment method

**Acceptance Criteria:**
- If API returns `"fm_serviceable": true`
- Parse `payment_type` array from response
- Show bottom sheet with payment options
- Display only 2 options:
  - **Pre-paid**: UPI/Online payment
  - **COD**: Cash on Delivery
- Enable options only if they exist in `payment_type` array
- Pre-paid enabled if array contains "Pre-paid"
- COD enabled if array contains "COD"

### US-3: UPI App Selection (Pre-paid)
**As a** user selecting pre-paid payment  
**I want to** choose from available UPI apps on my phone  
**So that** I can complete payment using my preferred UPI app

**Acceptance Criteria:**
- When user clicks "Pre-paid" option
- Detect installed UPI apps on device (Google Pay, PhonePe, Paytm, etc.)
- Show list of available UPI apps
- If no UPI apps installed, disable pre-paid option
- Show message: "No UPI apps found. Please install a UPI app."

### US-4: Handle Non-Serviceable Area
**As a** user in a non-serviceable area  
**I want to** see why I cannot proceed with payment  
**So that** I understand delivery is not available

**Acceptance Criteria:**
- If API returns `"fm_serviceable": false`
- Show bottom sheet with both payment options disabled
- Display error message at bottom of sheet in red color
- Error message: "Delivery is unavailable at this pincode"
- User cannot proceed with payment

### US-5: Handle API Errors
**As a** user  
**I want to** see clear error messages if serviceability check fails  
**So that** I know what went wrong

**Acceptance Criteria:**
- Handle network errors gracefully
- Handle API timeout (30 seconds)
- Show error message: "Unable to check delivery availability. Please try again."
- Allow user to retry

## Technical Requirements

### API Integration
- **Endpoint**: `https://track.delhivery.com/api/dc/fetch/serviceability/pincode`
- **Method**: GET
- **Headers**:
  - `Accept: application/json`
  - `Authorization: Token 9b0c726bc350e5f6a8d4fa8fe278666b3d6fd853`
- **Query Parameters**:
  - `product_type`: "Heavy"
  - `pincode`: User's pincode from cart/profile

### Response Structure
```json
{
  "fm_serviceable": true,
  "payment_type": "[\"Pre-paid\", \"COD\", \"Pickup\", \"Cash\", \"REPL\"]",
  // other fields...
}
```

### Architecture Requirements
- Create `DeliveryService` in `lib/services/`
- Create `ServiceabilityModel` in `lib/models/`
- Create `PaymentSelectionCubit` in `lib/cubits/payment_selection/`
- Create `PaymentSelectionBottomSheet` widget in `lib/widgets/`
- Store constants in `lib/utils/api_config.dart`
- Follow existing project structure and patterns

### UI/UX Requirements
- Bottom sheet with rounded top corners
- Payment options as radio buttons or cards
- Disabled state clearly visible (grayed out)
- Error message in red (#FF0000 or theme error color)
- Loading indicator during API call
- Smooth animations for bottom sheet

## Dependencies
- `http` package (already in project)
- `url_launcher` or `android_intent_plus` for UPI app detection
- `flutter_bloc` for state management (already in project)

## Out of Scope
- Actual payment gateway integration (Razorpay/Paytm)
- Order creation after payment
- Payment success/failure handling
- Delivery tracking

## Notes
- All constants must be stored in `api_config.dart`
- Code must be clean, well-structured, and follow project architecture
- Use existing patterns from the project (BLoC/Cubit, service layer, models)
- Handle all edge cases (no internet, API errors, no UPI apps)
