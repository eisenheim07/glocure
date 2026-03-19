# Implementation Plan: Shopping Cart Feature

## Overview

This implementation plan extends the existing shopping cart functionality in the Glocure Flutter app. The cart infrastructure (Cart ID generation, Add to Cart, Cart Screen UI) is already in place. This plan focuses on implementing the remaining features: item removal, quantity updates, discount codes, cart validation, error handling, and navigation integration.

The implementation follows the BLoC/Cubit pattern and integrates with Shopify's Storefront GraphQL API. All tasks build incrementally on the existing cart implementation.

## Tasks

- [ ] 1. Extend ApiService with cart mutation methods
  - Add cartLinesRemove mutation for removing items from cart
  - Add cartLinesUpdate mutation for updating item quantities
  - Add cartDiscountCodesUpdate mutation for applying/removing discount codes
  - Include proper error handling and logging for all mutations
  - _Requirements: 2.1, 3.1, 3.2, 4.1, 4.5_

- [ ]* 1.1 Write property test for cart mutation methods
  - **Property 4: Remove Item API Call**
  - **Property 8: Quantity Increment API Call**
  - **Property 9: Quantity Decrement API Call**
  - **Property 11: Discount Code Application**
  - **Property 14: Discount Removal**
  - **Validates: Requirements 2.1, 3.1, 3.2, 4.1, 4.5**

- [ ] 2. Extend CartCubit with cart operation methods
  - [ ] 2.1 Implement removeItem() method
    - Call ApiService.cartLinesRemove with cart ID and line ID
    - Refresh cart state after successful removal
    - Handle errors and emit CartError state
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 2.2 Implement updateQuantity() method
    - Call ApiService.cartLinesUpdate with line ID and new quantity
    - Handle quantity zero by calling removeItem()
    - Refresh cart state after successful update
    - Handle errors and emit CartError state
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 2.3 Implement applyDiscount() method
    - Call ApiService.cartDiscountCodesUpdate with discount code
    - Refresh cart state after successful application
    - Handle invalid discount codes with specific error messages
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ] 2.4 Implement removeDiscount() method
    - Call ApiService.cartDiscountCodesUpdate with empty array
    - Refresh cart state after successful removal
    - _Requirements: 4.5_

  - [ ] 2.5 Implement clearCart() method
    - Get all line IDs from current cart state
    - Call ApiService.cartLinesRemove with all line IDs
    - Emit CartEmpty state after successful clearing
    - Show confirmation dialog before clearing
    - _Requirements: 8.1, 8.2, 8.3_

  - [ ] 2.6 Implement getCartItemCount() method
    - Return count of unique items (lines.length) not sum of quantities
    - Return 0 for non-success states
    - _Requirements: 7.5_

- [ ]* 2.7 Write property tests for CartCubit operations
  - **Property 5: State Consistency After Mutations**
  - **Property 6: Error State Preservation**
  - **Property 7: Cart Badge Consistency**
  - **Property 15: Cart ID Persistence**
  - **Property 16: Cart ID Recovery**
  - **Property 17: Cart Data Consistency**
  - **Property 21: Clear Cart Bulk Removal**
  - **Property 22: Empty State After Clear**
  - **Validates: Requirements 2.2, 2.3, 2.5, 3.4, 3.5, 5.1, 5.3, 5.5, 6.2, 8.2, 8.3**

- [ ]* 2.8 Write unit tests for CartCubit edge cases
  - Test removing last item transitions to CartEmpty
  - Test decrementing quantity from 1 removes item
  - Test operations with missing cart ID
  - Test error recovery for invalid cart ID
  - _Requirements: 2.4, 3.3, 5.3, 6.2_

- [ ] 3. Create reusable cart UI widgets
  - [ ] 3.1 Create QuantitySelector widget
    - Display current quantity with increment/decrement buttons
    - Disable buttons when isLoading is true
    - Call onQuantityChanged callback with new quantity
    - Style according to app design system
    - _Requirements: 3.1, 3.2, 3.6_

  - [ ] 3.2 Create DiscountCodeInput widget
    - Show text field and apply button when no discount applied
    - Show applied discount code with remove button when discount active
    - Handle loading state during apply/remove operations
    - Display error messages for invalid codes
    - _Requirements: 4.1, 4.3, 4.4, 4.5_

  - [ ] 3.3 Create CartSummary widget
    - Display subtotal amount
    - Display discount amount if applicable
    - Display total amount
    - Show both original and discounted totals when discount applied
    - Format currency according to locale
    - _Requirements: 1.5, 4.2, 4.6_

  - [ ] 3.4 Create OutOfStockIndicator widget
    - Display prominent out-of-stock badge
    - Show notification message
    - Provide remove button for unavailable items
    - _Requirements: 6.3, 9.2, 9.4_

- [ ]* 3.5 Write property tests for UI widgets
  - **Property 1: Cart Display Completeness**
  - **Property 2: Discount Badge Display**
  - **Property 3: Variant Information Display**
  - **Property 10: Quantity Controls Disabled During Operations**
  - **Property 12: Valid Discount Display**
  - **Property 18: Out of Stock Indicator**
  - **Validates: Requirements 1.1, 1.2, 1.6, 3.6, 4.2, 4.4, 4.6, 6.3, 9.2**

- [ ] 4. Enhance CartScreen with interactive features
  - [ ] 4.1 Integrate QuantitySelector into cart item cards
    - Replace static quantity display with QuantitySelector widget
    - Connect to CartCubit.updateQuantity() method
    - Show loading state on specific item being updated
    - _Requirements: 3.1, 3.2, 3.6_

  - [ ] 4.2 Implement delete button functionality
    - Connect delete button to CartCubit.removeItem() method
    - Show loading indicator on item being removed
    - Display success SnackBar after removal
    - _Requirements: 2.1, 2.2_

  - [ ] 4.3 Add DiscountCodeInput to cart screen
    - Place above cart summary section
    - Connect to CartCubit.applyDiscount() and removeDiscount() methods
    - Show loading state during operations
    - Display error messages for invalid codes
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ] 4.4 Integrate CartSummary widget
    - Replace existing total display with CartSummary widget
    - Show discount breakdown when applicable
    - Update in real-time as cart changes
    - _Requirements: 1.5, 4.2, 4.6_

  - [ ] 4.5 Add clear cart button
    - Place in app bar or as floating action
    - Show confirmation dialog before clearing
    - Connect to CartCubit.clearCart() method
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ] 4.6 Implement cart validation UI
    - Display OutOfStockIndicator for unavailable items
    - Disable quantity controls for out-of-stock items
    - Show price change notifications
    - Disable checkout button when items unavailable
    - _Requirements: 6.3, 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ]* 4.7 Write unit tests for CartScreen interactions
  - Test quantity selector updates cart
  - Test delete button removes item
  - Test discount code input applies discount
  - Test clear cart shows confirmation dialog
  - Test checkout validation blocks unavailable items
  - _Requirements: 2.1, 3.1, 4.1, 8.1, 9.5_

- [ ] 5. Checkpoint - Ensure cart operations work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement cart badge in navigation
  - [ ] 6.1 Add cart badge to navigation bar
    - Use BlocBuilder to listen to CartCubit state
    - Display badge with item count from getCartItemCount()
    - Hide badge when count is zero
    - Update badge in real-time as cart changes
    - _Requirements: 7.1, 7.2, 7.3, 7.5_

  - [ ] 6.2 Implement cart icon navigation
    - Navigate to cart screen when cart icon tapped
    - Pass cart ID if needed for deep linking
    - _Requirements: 7.4_

- [ ]* 6.3 Write property tests for cart badge
  - **Property 7: Cart Badge Consistency**
  - **Property 20: Badge Count Calculation**
  - **Validates: Requirements 2.5, 7.1, 7.2, 7.5, 8.5**

- [ ]* 6.4 Write unit tests for navigation
  - Test badge displays correct count
  - Test badge hides when cart empty
  - Test tapping cart icon navigates to cart screen
  - _Requirements: 7.3, 7.4_

- [ ] 7. Implement error handling and recovery
  - [ ] 7.1 Add error handling for network failures
    - Catch TimeoutException and SocketException
    - Display user-friendly error messages
    - Provide retry button in error state
    - _Requirements: 6.1, 6.5_

  - [ ] 7.2 Implement invalid cart ID recovery
    - Detect invalid/expired cart ID errors
    - Create new cart via cartCreate mutation
    - Save new cart ID to SharedPreferences
    - Notify user that cart was reset
    - _Requirements: 5.3, 6.2_

  - [ ] 7.3 Add error logging
    - Log all cart errors with context
    - Include cart ID, operation type, and error details
    - Use existing logger from dependencies
    - _Requirements: 6.6_

- [ ]* 7.4 Write property tests for error handling
  - **Property 6: Error State Preservation**
  - **Property 13: Invalid Discount Error**
  - **Property 16: Cart ID Recovery**
  - **Property 19: Timeout Error Handling**
  - **Validates: Requirements 2.3, 3.5, 4.3, 5.3, 6.1, 6.2, 6.4, 6.5**

- [ ]* 7.5 Write unit tests for error scenarios
  - Test network error displays retry option
  - Test invalid cart ID triggers recovery
  - Test API errors are parsed and displayed
  - Test timeout errors show specific message
  - _Requirements: 6.1, 6.2, 6.4, 6.5_

- [ ] 8. Implement checkout navigation and validation
  - [ ] 8.1 Enhance "Add Address" button with validation
    - Check cart is not empty before navigation
    - Validate all items are available (availableForSale = true)
    - Display error message if validation fails
    - Pass cart ID to checkout screen
    - _Requirements: 9.5, 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 8.2 Add cart validation on load
    - Check each cart line's availableForSale property
    - Display indicators for unavailable items
    - Update UI to reflect item availability
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ]* 8.3 Write property tests for checkout validation
  - **Property 23: Cart Validation on Load**
  - **Property 24: Price Update Display**
  - **Property 25: Unavailable Item Notification**
  - **Property 26: Checkout Validation**
  - **Property 27: Checkout Navigation with Cart ID**
  - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 10.2, 10.4, 10.5**

- [ ]* 8.4 Write unit tests for checkout flow
  - Test empty cart blocks checkout
  - Test unavailable items block checkout
  - Test valid cart allows navigation
  - Test cart ID is passed to checkout screen
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 9. Implement cart persistence and synchronization
  - [ ] 9.1 Ensure cart ID persistence after operations
    - Verify cart ID is saved after add, remove, update, discount operations
    - Use existing AuthStorage.saveCartId() method
    - _Requirements: 5.1_

  - [ ] 9.2 Implement cart loading on app start
    - Retrieve cart ID from SharedPreferences on splash screen
    - Fetch cart data from Shopify API if cart ID exists
    - Handle invalid cart ID by creating new cart
    - _Requirements: 5.2, 5.3_

  - [ ] 9.3 Add cart state consistency checks
    - Verify local cart state matches API response after operations
    - Refresh cart if inconsistencies detected
    - _Requirements: 5.5_

- [ ]* 9.4 Write property tests for persistence
  - **Property 15: Cart ID Persistence**
  - **Property 17: Cart Data Consistency**
  - **Validates: Requirements 5.1, 5.5**

- [ ]* 9.5 Write unit tests for app lifecycle
  - Test cart loads on app start with valid cart ID
  - Test new cart created when cart ID missing
  - Test cart ID recovery when invalid
  - _Requirements: 5.2, 5.3_

- [ ] 10. Final checkpoint and integration testing
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Polish and optimization
  - [ ] 11.1 Add loading states and animations
    - Show shimmer during cart operations
    - Add smooth transitions for item removal
    - Display progress indicators for async operations
    - _Requirements: 1.4_

  - [ ] 11.2 Implement optimistic UI updates (optional)
    - Update UI immediately before API confirmation
    - Rollback on error
    - Improve perceived performance

  - [ ] 11.3 Add accessibility features
    - Ensure screen reader support for all cart operations
    - Add semantic labels to buttons and controls
    - Manage focus after cart operations

  - [ ] 11.4 Implement localization
    - Localize all error messages
    - Format currency according to locale
    - Format numbers according to locale

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- All cart operations build on existing infrastructure (Cart ID, Add to Cart, Cart Screen)
- The implementation follows the BLoC/Cubit pattern consistently
- Error handling is comprehensive with recovery mechanisms
- Cart persistence ensures seamless user experience across sessions
