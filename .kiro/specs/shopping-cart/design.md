# Design Document: Shopping Cart Feature

## Overview

The shopping cart feature provides a complete cart management system for the Glocure Flutter e-commerce application. Building upon the existing cart infrastructure (Cart ID generation, Add to Cart, and Cart Screen UI), this design extends the functionality to include item removal, quantity updates, discount code application, cart persistence, error handling, and navigation integration.

The implementation follows the BLoC/Cubit pattern for state management and integrates with Shopify's Storefront GraphQL API. The cart system maintains consistency between local storage (SharedPreferences) and the Shopify backend, ensuring a seamless user experience across app sessions.

### Key Design Goals

1. Extend existing CartCubit with new operations (remove, update quantity, apply discount)
2. Maintain cart state consistency between local storage and Shopify API
3. Provide graceful error handling with user-friendly feedback
4. Implement cart badge counter for navigation visibility
5. Support cart validation and item availability checking
6. Enable smooth navigation to checkout flow

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐  │
│  │ CartScreen │  │ Navigation │  │ ProductDetailsScreen │  │
│  │            │  │  (Badge)   │  │                      │  │
│  └─────┬──────┘  └─────┬──────┘  └──────────┬───────────┘  │
│        │               │                     │               │
└────────┼───────────────┼─────────────────────┼───────────────┘
         │               │                     │
         └───────────────┼─────────────────────┘
                         │
┌────────────────────────┼─────────────────────────────────────┐
│                 State Management Layer                        │
│                  ┌─────▼──────┐                              │
│                  │ CartCubit  │                              │
│                  │            │                              │
│                  │ - fetchCart()                             │
│                  │ - removeItem()                            │
│                  │ - updateQuantity()                        │
│                  │ - applyDiscount()                         │
│                  │ - removeDiscount()                        │
│                  │ - clearCart()                             │
│                  │ - validateCart()                          │
│                  └─────┬──────┘                              │
│                        │                                      │
└────────────────────────┼──────────────────────────────────────┘
                         │
┌────────────────────────┼──────────────────────────────────────┐
│                   Service Layer                               │
│                  ┌─────▼──────┐                              │
│                  │ ApiService │                              │
│                  │            │                              │
│                  │ - getCart()                               │
│                  │ - cartLinesAdd()                          │
│                  │ - cartLinesRemove()                       │
│                  │ - cartLinesUpdate()                       │
│                  │ - cartDiscountCodesUpdate()               │
│                  │ - cartCreate()                            │
│                  └─────┬──────┘                              │
│                        │                                      │
└────────────────────────┼──────────────────────────────────────┘
                         │
┌────────────────────────┼──────────────────────────────────────┐
│                  Storage Layer                                │
│            ┌─────▼──────────┐  ┌──────────────┐             │
│            │ AuthStorage    │  │ Shopify API  │             │
│            │                │  │              │             │
│            │ - getCartId()  │  │ GraphQL      │             │
│            │ - saveCartId() │  │ Mutations    │             │
│            │ - clearCartId()│  │              │             │
│            └────────────────┘  └──────────────┘             │
└───────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Cart Loading**: CartScreen → CartCubit.fetchCart() → ApiService.getCart() → Shopify API
2. **Remove Item**: User taps delete → CartCubit.removeItem() → ApiService.cartLinesRemove() → Refresh cart
3. **Update Quantity**: User taps +/- → CartCubit.updateQuantity() → ApiService.cartLinesUpdate() → Refresh cart
4. **Apply Discount**: User enters code → CartCubit.applyDiscount() → ApiService.cartDiscountCodesUpdate() → Refresh cart
5. **Cart Persistence**: All operations → AuthStorage.saveCartId() → SharedPreferences

## Components and Interfaces

### 1. CartCubit (Extended)

The CartCubit will be extended with new methods to handle additional cart operations.

```dart
class CartCubit extends Cubit<CartState> {
  final ApiService _apiService = ApiService();

  CartCubit() : super(CartInitial());

  // Existing methods
  Future<void> fetchCart() async { /* existing implementation */ }
  Future<void> refreshCart() async { /* existing implementation */ }

  // NEW: Remove item from cart
  Future<void> removeItem(String lineId) async {
    try {
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        emit(CartError('Cart not found'));
        return;
      }

      // Call API to remove line
      await _apiService.cartLinesRemove(
        cartId: cartId,
        lineIds: [lineId],
      );

      // Refresh cart to get updated state
      await fetchCart();
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Update item quantity
  Future<void> updateQuantity(String lineId, int newQuantity) async {
    try {
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        emit(CartError('Cart not found'));
        return;
      }

      // If quantity is 0, remove the item
      if (newQuantity <= 0) {
        await removeItem(lineId);
        return;
      }

      // Call API to update quantity
      await _apiService.cartLinesUpdate(
        cartId: cartId,
        lines: [
          {'id': lineId, 'quantity': newQuantity}
        ],
      );

      // Refresh cart to get updated state
      await fetchCart();
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Apply discount code
  Future<void> applyDiscount(String discountCode) async {
    try {
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        emit(CartError('Cart not found'));
        return;
      }

      // Call API to apply discount
      await _apiService.cartDiscountCodesUpdate(
        cartId: cartId,
        discountCodes: [discountCode],
      );

      // Refresh cart to get updated state
      await fetchCart();
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Remove discount code
  Future<void> removeDiscount() async {
    try {
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        emit(CartError('Cart not found'));
        return;
      }

      // Call API with empty discount codes array
      await _apiService.cartDiscountCodesUpdate(
        cartId: cartId,
        discountCodes: [],
      );

      // Refresh cart to get updated state
      await fetchCart();
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Clear entire cart
  Future<void> clearCart() async {
    try {
      final currentState = state;
      if (currentState is! CartSuccess) {
        return;
      }

      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        emit(CartError('Cart not found'));
        return;
      }

      // Get all line IDs
      final lineIds = currentState.cart.lines.map((line) => line.id).toList();

      if (lineIds.isEmpty) {
        return;
      }

      // Remove all lines
      await _apiService.cartLinesRemove(
        cartId: cartId,
        lineIds: lineIds,
      );

      // Emit empty state
      emit(CartEmpty());
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Get cart item count for badge
  int getCartItemCount() {
    final currentState = state;
    if (currentState is CartSuccess) {
      return currentState.cart.lines.length;
    }
    return 0;
  }
}
```

### 2. ApiService (Extended)

The ApiService will be extended with new GraphQL mutations for cart operations.

```dart
class ApiService {
  // Existing methods...

  /// Remove lines from cart
  /// [cartId] - The cart ID
  /// [lineIds] - List of line IDs to remove
  Future<Map<String, dynamic>> cartLinesRemove({
    required String cartId,
    required List<String> lineIds,
  }) async {
    try {
      _log('🛒 Removing lines from cart...');
      _log('Cart ID: $cartId');
      _log('Line IDs: $lineIds');

      const query = r'''
        mutation cartLinesRemove($cartId: ID!, $lineIds: [ID!]!) {
          cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
            cart {
              id
              lines(first: 20) {
                edges {
                  node {
                    id
                    quantity
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
      ''';

      final variables = {
        'cartId': cartId,
        'lineIds': lineIds,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartLinesRemove = responseData['data']?['cartLinesRemove'];
      final userErrors = cartLinesRemove?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Remove from cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesRemove?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Remove from cart failed: No cart data received');
      }

      _log('✅ Successfully removed lines from cart');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to remove lines from cart: $e');
      rethrow;
    }
  }

  /// Update cart line quantities
  /// [cartId] - The cart ID
  /// [lines] - List of line updates with id and quantity
  Future<Map<String, dynamic>> cartLinesUpdate({
    required String cartId,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      _log('🛒 Updating cart line quantities...');
      _log('Cart ID: $cartId');
      _log('Lines: $lines');

      const query = r'''
        mutation cartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
          cartLinesUpdate(cartId: $cartId, lines: $lines) {
            cart {
              id
              lines(first: 20) {
                edges {
                  node {
                    id
                    quantity
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
      ''';

      final variables = {
        'cartId': cartId,
        'lines': lines,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartLinesUpdate = responseData['data']?['cartLinesUpdate'];
      final userErrors = cartLinesUpdate?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Update cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesUpdate?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Update cart failed: No cart data received');
      }

      _log('✅ Successfully updated cart lines');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to update cart lines: $e');
      rethrow;
    }
  }

  /// Update discount codes on cart
  /// [cartId] - The cart ID
  /// [discountCodes] - List of discount codes to apply (empty array removes all)
  Future<Map<String, dynamic>> cartDiscountCodesUpdate({
    required String cartId,
    required List<String> discountCodes,
  }) async {
    try {
      _log('🛒 Updating discount codes...');
      _log('Cart ID: $cartId');
      _log('Discount Codes: $discountCodes');

      const query = r'''
        mutation cartDiscountCodesUpdate($cartId: ID!, $discountCodes: [String!]!) {
          cartDiscountCodesUpdate(cartId: $cartId, discountCodes: $discountCodes) {
            cart {
              id
              discountCodes {
                code
                applicable
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
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'cartId': cartId,
        'discountCodes': discountCodes,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartDiscountCodesUpdate = responseData['data']?['cartDiscountCodesUpdate'];
      final userErrors = cartDiscountCodesUpdate?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Discount code update failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartDiscountCodesUpdate?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Discount code update failed: No cart data received');
      }

      _log('✅ Successfully updated discount codes');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to update discount codes: $e');
      rethrow;
    }
  }
}
```

### 3. CartScreen (Extended UI)

The CartScreen will be extended with interactive controls for quantity adjustment, item removal, and discount code application.

```dart
// Key UI Components to Add:

// 1. Quantity Selector Widget
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onQuantityChanged;
  final bool isLoading;

  // Displays: [-] [quantity] [+]
  // Disables controls when isLoading is true
}

// 2. Discount Code Input Widget
class DiscountCodeInput extends StatefulWidget {
  final Function(String) onApply;
  final Function() onRemove;
  final DiscountCode? appliedDiscount;
  final bool isLoading;

  // Shows text field + apply button when no discount
  // Shows applied code + remove button when discount active
}

// 3. Cart Item Card (Enhanced)
class CartItemCard extends StatelessWidget {
  final CartLine line;
  final Function() onDelete;
  final Function(int) onQuantityChanged;
  final bool isLoading;

  // Includes:
  // - Product image, title, variant
  // - Price with discount badge if applicable
  // - QuantitySelector
  // - Delete button
  // - Out of stock indicator if !availableForSale
}

// 4. Cart Summary Widget
class CartSummary extends StatelessWidget {
  final CartCost cost;
  final DiscountCode? discount;

  // Displays:
  // - Subtotal
  // - Discount amount (if applicable)
  // - Total
}

// 5. Clear Cart Button
// Shows confirmation dialog before clearing
```

### 4. Navigation Integration

Cart badge counter will be integrated into the app's navigation bar.

```dart
// In main navigation widget (e.g., BottomNavigationBar or AppBar)

BlocBuilder<CartCubit, CartState>(
  builder: (context, state) {
    final itemCount = context.read<CartCubit>().getCartItemCount();
    
    return Badge(
      label: Text('$itemCount'),
      isLabelVisible: itemCount > 0,
      child: IconButton(
        icon: Icon(Icons.shopping_cart),
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
      ),
    );
  },
)
```

## Data Models

The existing cart models in `lib/models/cart_model.dart` are comprehensive and require no modifications. They already include:

- `CartResponse`: Top-level response wrapper
- `Cart`: Main cart object with lines, cost, and discount codes
- `CartLine`: Individual cart item with quantity and merchandise
- `CartMerchandise`: Product variant details with pricing and availability
- `CartProduct`: Product information with images
- `Money`: Price representation with amount and currency
- `CartCost`: Cart totals (subtotal, total, tax, duty)
- `DiscountCode`: Discount code with applicability status
- `CartAttribute`: Custom attributes for cart lines

### Key Model Properties for New Features

**CartMerchandise.availableForSale**: Used for cart validation
**CartMerchandise.quantityAvailable**: Used to check stock limits
**CartLine.id**: Required for remove and update operations
**DiscountCode.applicable**: Indicates if discount code is valid
**CartCost**: Provides all pricing information including discounts


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Cart Display Completeness

*For any* cart state containing items, the rendered cart screen should display all required information for each cart line: product image, title, price, and quantity.

**Validates: Requirements 1.1**

### Property 2: Discount Badge Display

*For any* cart line where compareAtPriceV2 is not null, the UI should display both the original price (with strikethrough) and the current price, along with a discount indicator.

**Validates: Requirements 1.2**

### Property 3: Variant Information Display

*For any* cart line with variant information (where merchandise.title is not "Default Title"), the variant details should be displayed below the product title.

**Validates: Requirements 1.6**

### Property 4: Remove Item API Call

*For any* cart line, when the delete button is tapped, the system should invoke cartLinesRemove mutation with the correct cart ID and line ID.

**Validates: Requirements 2.1**

### Property 5: State Consistency After Mutations

*For any* successful cart mutation (add, remove, update quantity, apply discount), the cart state should be refreshed and reflect the changes from the Shopify API.

**Validates: Requirements 2.2, 3.4, 3.7**

### Property 6: Error State Preservation

*For any* failed cart operation, the cart state should remain unchanged from before the operation, and an error message should be displayed to the user.

**Validates: Requirements 2.3, 3.5, 6.1, 6.4**

### Property 7: Cart Badge Consistency

*For any* cart operation that changes the number of items (add, remove, update to zero, clear), the cart badge count should be updated to reflect the current number of unique items in the cart.

**Validates: Requirements 2.5, 7.1, 7.2, 8.5**

### Property 8: Quantity Increment API Call

*For any* cart line with quantity N, when the increment button is tapped, the system should invoke cartLinesUpdate mutation with quantity N+1.

**Validates: Requirements 3.1**

### Property 9: Quantity Decrement API Call

*For any* cart line with quantity N > 1, when the decrement button is tapped, the system should invoke cartLinesUpdate mutation with quantity N-1.

**Validates: Requirements 3.2**

### Property 10: Quantity Controls Disabled During Operations

*For any* cart line, while a quantity update operation is in progress, the increment and decrement buttons should be disabled.

**Validates: Requirements 3.6**

### Property 11: Discount Code Application

*For any* discount code string entered by the user, when the apply button is tapped, the system should invoke cartDiscountCodesUpdate mutation with that code.

**Validates: Requirements 4.1**

### Property 12: Valid Discount Display

*For any* cart with an applied discount where applicable is true, the UI should display the discount code, the discount amount, and both the original and discounted totals.

**Validates: Requirements 4.2, 4.4, 4.6**

### Property 13: Invalid Discount Error

*For any* discount code that returns applicable as false or causes a userError, the system should display an error message indicating the code is invalid.

**Validates: Requirements 4.3**

### Property 14: Discount Removal

*For any* cart with an applied discount, when the remove discount action is triggered, the system should invoke cartDiscountCodesUpdate mutation with an empty discount codes array.

**Validates: Requirements 4.5**

### Property 15: Cart ID Persistence

*For any* cart operation (add, remove, update, apply discount), the cart ID should be stored in SharedPreferences after the operation completes.

**Validates: Requirements 5.1**

### Property 16: Cart ID Recovery

*For any* stored cart ID that returns an error when fetching cart data, the system should create a new cart via cartCreate mutation and store the new cart ID.

**Validates: Requirements 5.3, 6.2**

### Property 17: Cart Data Consistency

*For any* cart state, the data displayed in the UI should match the most recent response from the Shopify API getCart query.

**Validates: Requirements 5.5**

### Property 18: Out of Stock Indicator

*For any* cart line where merchandise.availableForSale is false, the UI should display an out-of-stock indicator and disable the quantity controls.

**Validates: Requirements 6.3, 9.2**

### Property 19: Timeout Error Handling

*For any* cart operation that times out, the system should display a timeout-specific error message.

**Validates: Requirements 6.5**

### Property 20: Badge Count Calculation

*For any* cart state, the badge count should equal the number of unique cart lines (cart.lines.length), not the sum of quantities.

**Validates: Requirements 7.5**

### Property 21: Clear Cart Bulk Removal

*For any* cart with N items, when the user confirms the clear cart action, the system should invoke cartLinesRemove mutation with all N line IDs.

**Validates: Requirements 8.2**

### Property 22: Empty State After Clear

*For any* cart that is successfully cleared, the cart state should transition to CartEmpty.

**Validates: Requirements 8.3**

### Property 23: Cart Validation on Load

*For any* cart loaded from the API, each cart line should be validated against its merchandise.availableForSale property.

**Validates: Requirements 9.1**

### Property 24: Price Update Display

*For any* cart line where the current priceV2 differs from a previously cached price, the UI should display the updated price.

**Validates: Requirements 9.3**

### Property 25: Unavailable Item Notification

*For any* cart line where merchandise.availableForSale is false, the UI should display a notification and provide a remove button.

**Validates: Requirements 9.4**

### Property 26: Checkout Validation

*For any* cart where at least one cart line has merchandise.availableForSale as false, the system should prevent navigation to the checkout screen and display an error message.

**Validates: Requirements 9.5, 10.4**

### Property 27: Checkout Navigation with Cart ID

*For any* valid cart (non-empty with all items available), when navigating to the checkout screen, the cart ID should be passed as a parameter.

**Validates: Requirements 10.2, 10.5**

## Error Handling

### Error Categories

1. **Network Errors**: Connection failures, timeouts, DNS resolution failures
2. **API Errors**: GraphQL userErrors, invalid cart ID, expired cart
3. **Validation Errors**: Empty cart, out of stock items, invalid discount codes
4. **State Errors**: Missing cart ID, inconsistent state

### Error Handling Strategy

```dart
// Error handling pattern in CartCubit
try {
  // Perform operation
  await _apiService.someCartOperation();
  
  // Refresh cart on success
  await fetchCart();
  
} on TimeoutException {
  emit(CartError('Request timed out. Please try again.'));
  
} on SocketException {
  emit(CartError('No internet connection. Please check your network.'));
  
} catch (e) {
  // Parse API errors
  final errorMessage = e.toString().replaceAll('Exception: ', '');
  
  // Handle specific error cases
  if (errorMessage.contains('Cart not found') || 
      errorMessage.contains('invalid') ||
      errorMessage.contains('expired')) {
    // Attempt to recover by creating new cart
    await _recoverFromInvalidCart();
  } else {
    emit(CartError(errorMessage));
  }
}
```

### Error Recovery

**Invalid Cart ID Recovery:**
1. Detect invalid/expired cart ID error
2. Create new cart via cartCreate mutation
3. Save new cart ID to SharedPreferences
4. Notify user that cart was reset
5. Emit CartEmpty state

**Network Error Recovery:**
1. Display error message with retry button
2. Maintain current cart state
3. Allow user to retry operation
4. Log error for debugging

**Out of Stock Handling:**
1. Display indicator on affected cart lines
2. Disable quantity controls for unavailable items
3. Block checkout navigation
4. Provide option to remove unavailable items

## Testing Strategy

### Dual Testing Approach

The shopping cart feature will be tested using both unit tests and property-based tests to ensure comprehensive coverage.

**Unit Tests** focus on:
- Specific examples of cart operations (add, remove, update)
- Edge cases (empty cart, last item removal, quantity zero)
- Error conditions (network failures, invalid cart ID)
- UI state transitions (loading, success, error, empty)
- Integration between CartCubit and ApiService

**Property-Based Tests** focus on:
- Universal properties that hold for all cart states
- State consistency after operations
- Badge count calculations across all scenarios
- Error handling across all failure modes
- UI rendering completeness for all cart configurations

### Property-Based Testing Configuration

**Framework**: Use the `test` package with custom property test helpers, or integrate a Dart property testing library if available.

**Configuration**:
- Minimum 100 iterations per property test
- Generate random cart states with varying numbers of items
- Generate random quantities, prices, and discount scenarios
- Test with both available and unavailable merchandise

**Test Tagging**:
Each property test must include a comment tag referencing the design property:

```dart
// Feature: shopping-cart, Property 5: State Consistency After Mutations
test('cart state reflects API response after any mutation', () async {
  // Property test implementation
  for (int i = 0; i < 100; i++) {
    // Generate random cart state
    // Perform random mutation
    // Verify state consistency
  }
});
```

### Test Coverage Goals

- 90%+ code coverage for CartCubit
- 100% coverage of all cart operations (add, remove, update, discount)
- All error paths tested
- All state transitions tested
- All 27 correctness properties validated

### Integration Testing

**Cart Flow Tests**:
1. Create cart → Add items → View cart → Remove item → Verify state
2. Create cart → Add items → Update quantities → Verify totals
3. Create cart → Add items → Apply discount → Verify pricing
4. Create cart → Add items → Clear cart → Verify empty state
5. Invalid cart ID → Recovery → New cart created

**Navigation Tests**:
1. Navigate to cart → Verify cart screen displayed
2. Cart badge → Tap → Navigate to cart screen
3. Cart with valid items → Navigate to checkout
4. Cart with unavailable items → Checkout blocked

### Mock Strategy

**ApiService Mocking**:
- Mock all GraphQL mutations (cartLinesAdd, cartLinesRemove, cartLinesUpdate, cartDiscountCodesUpdate)
- Mock getCart query with various cart states
- Simulate network errors, timeouts, and API errors
- Simulate invalid cart ID scenarios

**SharedPreferences Mocking**:
- Mock cart ID storage and retrieval
- Test persistence across app restarts

### Example Unit Tests

```dart
group('CartCubit - Remove Item', () {
  test('should remove item and refresh cart', () async {
    // Arrange
    final mockApiService = MockApiService();
    final cubit = CartCubit(apiService: mockApiService);
    
    // Act
    await cubit.removeItem('line-id-123');
    
    // Assert
    verify(mockApiService.cartLinesRemove(
      cartId: any,
      lineIds: ['line-id-123'],
    )).called(1);
    verify(mockApiService.getCart(any)).called(1);
  });
  
  test('should emit error when removal fails', () async {
    // Arrange
    final mockApiService = MockApiService();
    when(mockApiService.cartLinesRemove(any, any))
        .thenThrow(Exception('Network error'));
    final cubit = CartCubit(apiService: mockApiService);
    
    // Act
    await cubit.removeItem('line-id-123');
    
    // Assert
    expect(cubit.state, isA<CartError>());
  });
});
```

### Example Property Test

```dart
// Feature: shopping-cart, Property 7: Cart Badge Consistency
test('badge count equals number of unique items after any operation', () async {
  for (int i = 0; i < 100; i++) {
    // Generate random cart with N items
    final cart = generateRandomCart(itemCount: Random().nextInt(10) + 1);
    final cubit = CartCubit();
    
    // Emit cart state
    cubit.emit(CartSuccess(cart));
    
    // Verify badge count
    expect(cubit.getCartItemCount(), equals(cart.lines.length));
    
    // Perform random operation (add, remove, update)
    final operation = Random().nextInt(3);
    switch (operation) {
      case 0: // Add
        await cubit.addItem(generateRandomMerchandiseId());
        break;
      case 1: // Remove
        if (cart.lines.isNotEmpty) {
          await cubit.removeItem(cart.lines.first.id);
        }
        break;
      case 2: // Update
        if (cart.lines.isNotEmpty) {
          await cubit.updateQuantity(
            cart.lines.first.id,
            Random().nextInt(5) + 1,
          );
        }
        break;
    }
    
    // Verify badge count still matches unique items
    final newState = cubit.state;
    if (newState is CartSuccess) {
      expect(cubit.getCartItemCount(), equals(newState.cart.lines.length));
    } else if (newState is CartEmpty) {
      expect(cubit.getCartItemCount(), equals(0));
    }
  }
});
```

## Implementation Notes

### State Management Considerations

1. **Optimistic Updates**: Consider implementing optimistic UI updates for better perceived performance, with rollback on error
2. **Loading States**: Use granular loading states (e.g., `removingLineId`, `updatingLineId`) to disable only the affected UI elements
3. **Debouncing**: Debounce quantity updates to avoid excessive API calls when user rapidly taps increment/decrement

### Performance Optimizations

1. **Cart Caching**: Cache cart data locally and only refresh when necessary
2. **Partial Updates**: When possible, update local state optimistically before API confirmation
3. **Image Caching**: Leverage Flutter's image caching for product images in cart

### Accessibility

1. **Screen Reader Support**: Ensure all cart operations are announced to screen readers
2. **Semantic Labels**: Provide clear labels for quantity controls, delete buttons, and discount inputs
3. **Focus Management**: Manage focus appropriately after cart operations (e.g., focus on next item after deletion)

### Localization

1. **Error Messages**: All error messages should be localized
2. **Currency Formatting**: Use proper currency formatting based on user locale
3. **Number Formatting**: Format quantities and counts according to locale

### Security Considerations

1. **Cart ID Protection**: Cart IDs should not be exposed in logs or error messages
2. **Input Validation**: Validate discount codes and quantities on client side before API calls
3. **Token Validation**: Ensure authentication token is valid before cart operations
