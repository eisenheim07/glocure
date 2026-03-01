# Requirements Document

## Introduction

This document specifies the requirements for the shopping cart feature in the Glocure Flutter e-commerce application. The cart feature enables users to manage their shopping selections, including viewing items, updating quantities, removing items, applying discounts, and proceeding to checkout. The implementation integrates with Shopify's Storefront GraphQL API and uses the BLoC/Cubit pattern for state management.

The cart functionality builds upon three completed phases: Cart ID generation and persistence, Add to Cart functionality, and Cart Screen UI. This specification covers the remaining features needed for a complete shopping cart experience.

## Glossary

- **Cart_System**: The shopping cart management system within the Glocure application
- **Shopify_API**: The Shopify Storefront GraphQL API backend service
- **Cart_ID**: A unique identifier for a user's shopping cart, persisted across sessions
- **Cart_Line**: An individual product item in the cart with quantity and variant information
- **Merchandise_ID**: The Shopify variant ID for a specific product variant
- **Discount_Code**: A promotional code that applies price reductions to cart items
- **Cart_Badge**: A visual indicator showing the number of items in the cart
- **Cart_Cubit**: The BLoC/Cubit state management component for cart operations
- **Shared_Preferences**: Local storage mechanism for persisting cart data

## Requirements

### Requirement 1: View Cart Contents

**User Story:** As a user, I want to view all items in my shopping cart, so that I can review my selections before checkout.

#### Acceptance Criteria

1. WHEN a user navigates to the cart screen, THE Cart_System SHALL display all cart lines with product images, titles, prices, and quantities
2. WHEN the cart contains discounted items, THE Cart_System SHALL display discount badges and original prices with strikethrough
3. WHEN the cart is empty, THE Cart_System SHALL display an empty state message
4. WHEN cart data is loading, THE Cart_System SHALL display loading shimmer animations
5. THE Cart_System SHALL display the total cart amount at the bottom of the screen
6. WHEN a cart line includes variant information, THE Cart_System SHALL display the variant details below the product title

### Requirement 2: Remove Items from Cart

**User Story:** As a user, I want to remove items from my cart, so that I can eliminate products I no longer wish to purchase.

#### Acceptance Criteria

1. WHEN a user taps the delete button on a cart line, THE Cart_System SHALL send a cartLinesRemove mutation to Shopify_API with the cart ID and line ID
2. WHEN the removal is successful, THE Cart_System SHALL refresh the cart display and show a success message
3. WHEN the removal fails, THE Cart_System SHALL display an error message and maintain the current cart state
4. WHEN the last item is removed from the cart, THE Cart_System SHALL display the empty cart state
5. THE Cart_System SHALL update the cart badge count after successful removal

### Requirement 3: Update Item Quantities

**User Story:** As a user, I want to change the quantity of items in my cart, so that I can purchase the desired amount of each product.

#### Acceptance Criteria

1. WHEN a user increases quantity using the increment button, THE Cart_System SHALL send a cartLinesUpdate mutation to Shopify_API with the new quantity
2. WHEN a user decreases quantity using the decrement button, THE Cart_System SHALL send a cartLinesUpdate mutation to Shopify_API with the new quantity
3. WHEN quantity reaches zero via decrement, THE Cart_System SHALL remove the item from the cart
4. WHEN the quantity update is successful, THE Cart_System SHALL refresh the cart display with updated totals
5. WHEN the quantity update fails, THE Cart_System SHALL display an error message and revert to the previous quantity
6. THE Cart_System SHALL disable quantity controls while an update operation is in progress
7. THE Cart_System SHALL update the total cart amount immediately after successful quantity changes

### Requirement 4: Apply Discount Codes

**User Story:** As a user, I want to apply discount codes to my cart, so that I can receive promotional price reductions.

#### Acceptance Criteria

1. WHEN a user enters a discount code and taps apply, THE Cart_System SHALL send a cartDiscountCodesUpdate mutation to Shopify_API
2. WHEN the discount code is valid, THE Cart_System SHALL display the discount amount and update the total price
3. WHEN the discount code is invalid, THE Cart_System SHALL display an error message indicating the code is not valid
4. WHEN a discount is already applied, THE Cart_System SHALL display the active discount code with an option to remove it
5. WHEN a user removes an applied discount, THE Cart_System SHALL send a cartDiscountCodesUpdate mutation with an empty discount codes array
6. THE Cart_System SHALL display the discounted total separately from the original total

### Requirement 5: Cart Persistence and Synchronization

**User Story:** As a user, I want my cart to persist across app sessions, so that I don't lose my selections when I close the app.

#### Acceptance Criteria

1. WHEN a user adds or modifies cart items, THE Cart_System SHALL store the cart ID in Shared_Preferences
2. WHEN the app is reopened, THE Cart_System SHALL retrieve the cart ID from Shared_Preferences and fetch current cart data from Shopify_API
3. WHEN the stored cart ID is invalid or expired, THE Cart_System SHALL create a new cart via cartCreate mutation
4. WHEN network connectivity is restored after being offline, THE Cart_System SHALL synchronize cart data with Shopify_API
5. THE Cart_System SHALL maintain cart data consistency between local storage and Shopify_API

### Requirement 6: Handle Cart Errors

**User Story:** As a system, I want to handle cart errors gracefully, so that users receive clear feedback when operations fail.

#### Acceptance Criteria

1. WHEN a cart operation fails due to network error, THE Cart_System SHALL display a user-friendly error message with retry option
2. WHEN a cart ID is expired or invalid, THE Cart_System SHALL create a new cart and notify the user
3. WHEN an item is out of stock, THE Cart_System SHALL display an out-of-stock indicator on the cart line
4. WHEN the Shopify_API returns an error response, THE Cart_System SHALL parse the error message and display it to the user
5. IF a cart operation times out, THEN THE Cart_System SHALL display a timeout error message
6. THE Cart_System SHALL log all cart errors for debugging purposes

### Requirement 7: Cart Badge and Navigation

**User Story:** As a user, I want to see how many items are in my cart from anywhere in the app, so that I can quickly access my cart.

#### Acceptance Criteria

1. WHEN items are added to the cart, THE Cart_System SHALL update the cart badge count on the navigation bar
2. WHEN items are removed from the cart, THE Cart_System SHALL update the cart badge count on the navigation bar
3. WHEN the cart is empty, THE Cart_System SHALL hide the cart badge or display zero
4. WHEN a user taps the cart icon, THE Cart_System SHALL navigate to the cart screen
5. THE Cart_System SHALL display the total number of unique items in the cart badge, not the sum of quantities

### Requirement 8: Clear Entire Cart

**User Story:** As a user, I want to clear all items from my cart at once, so that I can start fresh with new selections.

#### Acceptance Criteria

1. WHEN a user taps the clear cart button, THE Cart_System SHALL display a confirmation dialog
2. WHEN the user confirms clearing the cart, THE Cart_System SHALL remove all cart lines via cartLinesRemove mutation
3. WHEN the cart is successfully cleared, THE Cart_System SHALL display the empty cart state
4. WHEN the user cancels the clear operation, THE Cart_System SHALL maintain the current cart state
5. THE Cart_System SHALL update the cart badge to zero after successful clearing

### Requirement 9: Cart Item Validation

**User Story:** As a user, I want to be notified if cart items are no longer available, so that I can adjust my purchase accordingly.

#### Acceptance Criteria

1. WHEN the cart is loaded, THE Cart_System SHALL validate each cart line against current product availability from Shopify_API
2. WHEN a cart item is out of stock, THE Cart_System SHALL display an out-of-stock indicator and disable quantity controls
3. WHEN a cart item price has changed, THE Cart_System SHALL display the updated price
4. WHEN a cart item is no longer available, THE Cart_System SHALL display a notification and provide an option to remove it
5. THE Cart_System SHALL prevent checkout if any cart items are unavailable

### Requirement 10: Navigate to Checkout

**User Story:** As a user, I want to proceed to checkout from my cart, so that I can complete my purchase.

#### Acceptance Criteria

1. WHEN a user taps the "Add Address" button, THE Cart_System SHALL validate that the cart is not empty
2. WHEN the cart contains valid items, THE Cart_System SHALL navigate to the address/checkout screen
3. WHEN the cart is empty, THE Cart_System SHALL display a message indicating checkout is not available
4. WHEN cart items are unavailable, THE Cart_System SHALL prevent navigation to checkout and display an error message
5. THE Cart_System SHALL pass the cart ID to the checkout screen for order processing
