# Cart Implementation - Phase 1: Cart ID Generation

## Overview
Implemented the cart ID generation and storage system following Shopify's GraphQL API and project architecture.

## Implementation Details

### 1. Storage Layer (`lib/utils/auth_storage.dart`)
Added cart ID storage methods:
- `saveCartId(String cartId)` - Saves cart ID to SharedPreferences
- `getCartId()` - Retrieves cart ID from SharedPreferences
- `clearCartId()` - Clears cart ID from storage
- Updated `clearAllData()` to also clear cart ID on logout/token expiration

### 2. API Service Layer (`lib/services/api_service.dart`)
Added cart-related GraphQL mutations:

#### `cartCreate()`
- Creates a new Shopify cart using GraphQL mutation
- Returns the cart ID
- Handles user errors and validation
- Logs all operations for debugging

#### `getOrCreateCartId()`
- Smart method that checks if cart ID exists in preferences
- If exists: Returns existing cart ID (no API call)
- If not exists: Creates new cart and saves to preferences
- This is the main method to use throughout the app

### 3. Login Flow Integration (`lib/screens/login_screen.dart`)
Updated `_loginWithEmail()` method:
- After successful login and token storage
- Automatically calls `getOrCreateCartId()`
- Cart creation happens in background
- Login flow continues even if cart creation fails (non-blocking)

### 4. Splash Screen Cart Recovery (`lib/screens/splash_screen.dart`)
Added `_ensureCartIdExists()` method:
- Checks if user has valid token (currentDateTime < expiresAt)
- If token is valid but cart ID is missing, creates new cart ID
- Handles edge cases:
  - User cleared app data
  - App reinstalled
  - SharedPreferences corrupted
  - User switched devices
- Non-blocking: Navigation continues even if cart recovery fails

## Flow Diagram

```
User Login
    ↓
Save Token (accessToken + expiresAt)
    ↓
Check: Cart ID exists in preferences?
    ↓
YES → Use existing cart ID
    ↓
NO → Call cartCreate GraphQL mutation
    ↓
    Save new cart ID to preferences
    ↓
Continue to Home/Language Selection

---

App Launch (Splash Screen)
    ↓
Check: User logged in? (currentDateTime < expiresAt)
    ↓
YES → Check: Cart ID exists?
    ↓
    NO → Create new cart ID (Recovery)
    ↓
    YES → Continue with existing cart ID
    ↓
Navigate to Home
```

## Key Features

✅ Cart ID is generated only once per user session
✅ Cart ID persists in SharedPreferences
✅ Reuses existing cart ID on subsequent app launches
✅ Cart ID is cleared when user logs out or token expires
✅ **Auto-recovery: If cart ID is lost but token is valid, creates new cart ID**
✅ **Handles edge cases: app reinstall, data clear, device switch**
✅ Non-blocking: Login/navigation continues even if cart creation fails
✅ Follows project architecture (storage → service → screen)
✅ Clean, well-structured, and maintainable code
✅ Comprehensive logging for debugging

## GraphQL Mutation Used

```graphql
mutation {
  cartCreate {
    cart {
      id
    }
    userErrors {
      field
      message
    }
  }
}
```

## API Endpoint
- URL: `https://glocure.com/api/2025-01/graphql.json`
- Token: `91463a987d1491148e998368944925a2`

## Testing Checklist

- [ ] Login with valid credentials
- [ ] Verify cart ID is created and saved
- [ ] Close and reopen app
- [ ] Verify existing cart ID is reused (no new API call)
- [ ] **Clear app data while logged in**
- [ ] **Reopen app - verify cart ID is auto-recovered**
- [ ] Logout and login again
- [ ] Verify new cart ID is created
- [ ] Check logs for cart operations
- [ ] **Test token expiration - verify cart ID is cleared**

## Next Steps

Ready for Phase 2:
- Add items to cart
- Update cart quantities
- Remove items from cart
- Fetch cart contents
- Cart screen UI implementation

## Files Modified

1. `lib/utils/auth_storage.dart` - Added cart ID storage methods
2. `lib/services/api_service.dart` - Added cart creation mutations
3. `lib/screens/login_screen.dart` - Integrated cart ID creation in login flow
4. `lib/screens/splash_screen.dart` - Added cart ID recovery on app launch

All changes follow the project's architecture and coding standards.
