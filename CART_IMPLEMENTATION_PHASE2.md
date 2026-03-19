# Cart Implementation - Phase 2: Add to Cart

## Overview
Implemented the "Add to Cart" functionality on the product details screen using Shopify's GraphQL API.

## Implementation Details

### 1. API Service Layer (`lib/services/api_service.dart`)

#### `cartLinesAdd()` Method
- Adds products to the cart using GraphQL mutation
- Parameters:
  - `cartId` (required) - The cart ID to add items to
  - `merchandiseId` (required) - The variant ID of the product
  - `quantity` (optional, default: 1) - Quantity to add
- Returns cart data with updated line items
- Handles user errors and validation
- Comprehensive logging for debugging

### 2. Product Details Screen (`lib/screens/product_details_screen.dart`)

#### `_addToCart()` Method
- Validates cart ID exists in preferences
- Gets the selected variant ID from the product
- Shows loading indicator while adding to cart
- Calls `ApiService().cartLinesAdd()` with cart ID and variant ID
- Shows success/error feedback to user
- Non-blocking: Handles errors gracefully

#### UI Integration
- Cart button in bottom bar now functional
- Tapping cart icon adds product to cart
- Visual feedback with SnackBar notifications:
  - Loading: "Adding to cart..." with spinner
  - Success: Green SnackBar with checkmark
  - Error: Red SnackBar with error message

## GraphQL Mutation Used

```graphql
mutation cartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart {
      id
      lines(first: 10) {
        edges {
          node {
            id
            quantity
            merchandise {
              ... on ProductVariant {
                id
                title
              }
            }
          }
        }
      }
    }
    userErrors {
      field
      message
    }
  }
}
```

## Variables Structure

```json
{
  "cartId": "gid://shopify/Cart/...",
  "lines": [
    {
      "quantity": 1,
      "merchandiseId": "gid://shopify/ProductVariant/..."
    }
  ]
}
```

## User Flow

```
User taps cart icon on product details
    ↓
Validate cart ID exists
    ↓
Get selected variant ID (first variant)
    ↓
Show loading indicator
    ↓
Call cartLinesAdd API
    ↓
Success → Show green SnackBar
    ↓
Error → Show red SnackBar with message
```

## Key Features

✅ Uses selected variant from product (always first variant as per requirement)
✅ Validates cart ID before adding
✅ Shows loading state during API call
✅ Success feedback with product name
✅ Error handling with user-friendly messages
✅ Non-blocking: Errors don't crash the app
✅ Clean, maintainable code following project architecture
✅ Comprehensive logging for debugging

## Error Handling

1. **Cart ID Missing**: Shows "Cart not initialized" message
2. **No Variants**: Shows "Product variant not available" message
3. **API Error**: Shows specific error message from API
4. **Network Error**: Shows connection error message

## User Feedback

### Loading State
- SnackBar with spinner: "Adding to cart..."
- Duration: 30 seconds (auto-dismissed on success/error)

### Success State
- Green SnackBar with checkmark icon
- Message: "[Product Name] added to cart!"
- Duration: 2 seconds
- Floating behavior for better UX

### Error State
- Red SnackBar with error message
- Message: "Failed to add to cart: [error details]"
- Duration: 3 seconds

## Testing Checklist

- [ ] Open product details screen
- [ ] Tap cart icon
- [ ] Verify loading indicator appears
- [ ] Verify success message shows
- [ ] Check logs for API call details
- [ ] Test with different products
- [ ] Test error scenarios:
  - [ ] No cart ID (clear preferences)
  - [ ] Invalid variant ID
  - [ ] Network error
- [ ] Verify cart icon remains functional after success
- [ ] Test multiple additions of same product

## Files Modified

1. `lib/services/api_service.dart` - Added `cartLinesAdd()` method
2. `lib/screens/product_details_screen.dart` - Added `_addToCart()` method and updated cart button

## Next Steps

Ready for Phase 3:
- Fetch cart contents
- Display cart items on cart screen
- Update quantities
- Remove items from cart
- Calculate totals
- Checkout flow

All changes follow the project's architecture and coding standards.
