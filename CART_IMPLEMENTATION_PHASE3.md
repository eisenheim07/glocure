# Cart Implementation - Phase 3: Cart Screen UI

## Overview
Implemented the complete cart screen with product listing, pricing, and checkout button following the exact UI design provided.

## Implementation Details

### 1. Cart Model (`lib/models/cart_model.dart`)
Created comprehensive data models to handle Shopify cart response:
- `CartResponse` - Root response wrapper
- `Cart` - Main cart object with lines, cost, and discount codes
- `CartLine` - Individual cart item with quantity and merchandise
- `CartMerchandise` - Product variant details with pricing
- `CartProduct` - Product information with images
- `CartCost` - Pricing breakdown (subtotal, total, tax, duty)
- `Money` - Currency amount representation
- `DiscountCode` - Applied discount codes

### 2. Cart State Management (`lib/cubits/cart/`)

#### Cart State (`cart_state.dart`)
- `CartInitial` - Initial state
- `CartLoading` - Loading cart data
- `CartSuccess` - Cart loaded with items
- `CartEmpty` - No items in cart
- `CartError` - Error loading cart

#### Cart Cubit (`cart_cubit.dart`)
- `fetchCart()` - Fetches cart from API using stored cart ID
- `refreshCart()` - Refreshes cart data
- Handles empty cart and error states
- Clean state management following BLoC pattern

### 3. API Service (`lib/services/api_service.dart`)

#### `getCart()` Method
- Fetches complete cart details using GraphQL query
- Includes:
  - Line items with product details
  - Product images
  - Pricing (current and compare-at prices)
  - Quantities and variants
  - Cost breakdown
  - Discount codes
- Returns parsed cart data

### 4. Cart Screen UI (`lib/screens/cart_screen.dart`)

#### Main Features
- **App Bar**: "My Cart" title with back button
- **Cart Items List**: Scrollable list of products
- **Bottom Section**: Total amount and "Add Address" button (fixed at bottom)
- **Empty State**: Shows when cart has no items
- **Error State**: Shows error message with retry button
- **Loading State**: Shimmer effect while loading

#### Cart Item Card
Matches the provided UI exactly:
- Product image (100x100)
- Product title (2 lines max)
- Current price (bold, large)
- Original price (strikethrough, if available)
- Discount badge (green, if applicable)
- Quantity selector with dropdown icon
- Variant info (size, shade, etc.)
- Delete button (trash icon)

#### Bottom Section
- Total label and amount (bold, 20px)
- "Add Address" button (pink, full width)
- Fixed at bottom with shadow
- SafeArea padding

### 5. Integration (`lib/main.dart`)
- Added `CartCubit` to MultiBlocProvider
- Available throughout the app

## UI Features

✅ Exact match to provided design
✅ No ratings (as requested)
✅ Product images with fallback
✅ Price formatting with currency
✅ Discount percentage badges
✅ Quantity display with dropdown indicator
✅ Variant information (size, shade, etc.)
✅ Delete button for each item
✅ Total amount at bottom
✅ "Add Address" button fixed at bottom
✅ Empty state with icon and message
✅ Error state with retry button
✅ Loading shimmer effect

## GraphQL Query

```graphql
query getCart($cartId: ID!) {
  cart(id: $cartId) {
    id
    lines(first: 20) {
      edges {
        node {
          id
          quantity
          attributes {
            key
            value
          }
          merchandise {
            ... on ProductVariant {
              id
              title
              sku
              availableForSale
              quantityAvailable
              priceV2 {
                amount
                currencyCode
              }
              compareAtPriceV2 {
                amount
                currencyCode
              }
              product {
                id
                title
                handle
                images(first: 1) {
                  edges {
                    node {
                      url
                      altText
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    cost {
      subtotalAmount {
        amount
        currencyCode
      }
      totalAmount {
        amount
        currencyCode
      }
      totalTaxAmount {
        amount
        currencyCode
      }
      totalDutyAmount {
        amount
        currencyCode
      }
    }
    discountCodes {
      code
      applicable
    }
  }
}
```

## User Flow

```
User navigates to Cart Screen
    ↓
CartCubit fetches cart using stored cart ID
    ↓
Loading state shows shimmer
    ↓
Success → Display cart items with total
    ↓
Empty → Show empty state message
    ↓
Error → Show error with retry button
```

## Files Created/Modified

1. `lib/models/cart_model.dart` - Cart data models
2. `lib/cubits/cart/cart_state.dart` - Cart states
3. `lib/cubits/cart/cart_cubit.dart` - Cart state management
4. `lib/services/api_service.dart` - Added `getCart()` method
5. `lib/screens/cart_screen.dart` - Complete cart UI
6. `lib/main.dart` - Added CartCubit to providers

## Testing Checklist

- [ ] Navigate to cart screen
- [ ] Verify cart items load correctly
- [ ] Check product images display
- [ ] Verify prices format correctly
- [ ] Check discount badges show when applicable
- [ ] Verify quantity displays correctly
- [ ] Check variant info shows (size, shade, etc.)
- [ ] Verify total amount calculates correctly
- [ ] Test empty cart state
- [ ] Test error state with retry
- [ ] Verify loading shimmer
- [ ] Check bottom section stays fixed
- [ ] Test on different screen sizes

## Next Steps

Ready for Phase 4:
- Update cart quantities
- Remove items from cart
- Apply discount codes
- Navigate to checkout/address screen
- Cart badge counter on app bar

All code is clean, well-structured, and follows the project architecture!
