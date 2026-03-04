# Order Creation & PayU Payment Integration - Requirements

## Overview
Integrate Shopify order creation with PayU payment gateway. When user selects a payment method, create an order in Shopify and process payment through PayU (for Pre-paid) or mark as COD.

## User Stories

### US-1: Create Order for Pre-paid Payment
**As a** user selecting Pre-paid payment  
**I want to** create an order and pay through PayU  
**So that** I can complete my purchase securely

**Acceptance Criteria:**
- When user selects "Pre-paid" payment method
- System creates draft order in Shopify
- System initiates PayU payment gateway
- User completes payment on PayU
- On success: Order status updated to "Paid"
- On failure: Order remains as draft or cancelled

### US-2: Create Order for COD
**As a** user selecting Cash on Delivery  
**I want to** create an order without payment  
**So that** I can pay when I receive the product

**Acceptance Criteria:**
- When user selects "COD" payment method
- System creates order in Shopify with "Pending" payment status
- Order marked as "Cash on Delivery"
- User sees order confirmation
- No payment gateway involved

### US-3: Handle Payment Success
**As a** user who completed payment  
**I want to** see order confirmation  
**So that** I know my order is placed successfully

**Acceptance Criteria:**
- After successful PayU payment
- Update order status in Shopify
- Show order confirmation screen
- Display order number, items, amount
- Send confirmation email (Shopify handles this)

### US-4: Handle Payment Failure
**As a** user whose payment failed  
**I want to** retry or cancel  
**So that** I can complete my purchase or try later

**Acceptance Criteria:**
- If PayU payment fails
- Show error message
- Offer retry option
- Allow user to go back to cart
- Don't create duplicate orders

## Technical Requirements

### Shopify Order Creation

#### GraphQL Mutation: draftOrderCreate
```graphql
mutation draftOrderCreate($input: DraftOrderInput!) {
  draftOrderCreate(input: $input) {
    draftOrder {
      id
      name
      totalPrice
      lineItems(first: 10) {
        edges {
          node {
            id
            title
            quantity
            originalUnitPrice
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

#### Input Structure
```json
{
  "input": {
    "lineItems": [
      {
        "variantId": "gid://shopify/ProductVariant/123",
        "quantity": 2
      }
    ],
    "customer": {
      "id": "gid://shopify/Customer/456"
    },
    "shippingAddress": {
      "address1": "123 Street",
      "city": "Mumbai",
      "province": "Maharashtra",
      "country": "India",
      "zip": "400086",
      "phone": "9876543210"
    },
    "billingAddress": {
      // Same as shipping or different
    },
    "note": "Payment Method: Pre-paid/COD",
    "tags": ["mobile-app", "pre-paid" or "cod"]
  }
}
```

### PayU Payment Gateway Integration

#### PayU Parameters
- **Merchant Key**: From PayU dashboard
- **Merchant Salt**: From PayU dashboard
- **Transaction ID**: Unique ID (order_id + timestamp)
- **Amount**: Total order amount
- **Product Info**: Order items description
- **First Name**: Customer first name
- **Email**: Customer email
- **Phone**: Customer phone
- **Success URL**: Callback URL for success
- **Failure URL**: Callback URL for failure
- **Hash**: SHA512 hash for security

#### Hash Calculation
```
hash = sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt)
```

#### PayU Test Credentials (for development)
- Merchant Key: `gtKFFx`
- Merchant Salt: `eCwWELxi`
- Test URL: `https://test.payu.in/_payment`
- Production URL: `https://secure.payu.in/_payment`

### Order Flow

#### Pre-paid Flow
```
1. User selects "Pre-paid"
2. Create draft order in Shopify
3. Get order ID and total amount
4. Calculate PayU hash
5. Open PayU payment page (WebView)
6. User completes payment
7. PayU redirects to success/failure URL
8. Update order status in Shopify
9. Show confirmation screen
```

#### COD Flow
```
1. User selects "COD"
2. Create order in Shopify with "Pending" status
3. Add "COD" tag to order
4. Show order confirmation
5. No payment gateway involved
```

## Architecture

### New Files to Create

1. **`lib/services/order_service.dart`**
   - `createDraftOrder()` - Create draft order in Shopify
   - `completeOrder()` - Complete order after payment
   - `updateOrderStatus()` - Update order status

2. **`lib/services/payu_service.dart`**
   - `generateHash()` - Generate PayU hash
   - `initiatePayment()` - Start PayU payment
   - `verifyPayment()` - Verify payment response

3. **`lib/models/order_model.dart`**
   - Order data structure
   - Line items, customer, address

4. **`lib/screens/payment_webview_screen.dart`**
   - WebView for PayU payment page
   - Handle success/failure callbacks

5. **`lib/screens/order_confirmation_screen.dart`**
   - Show order details after successful payment
   - Order number, items, amount, delivery info

6. **`lib/cubits/order/order_cubit.dart`**
   - Manage order creation state
   - Handle payment flow

### Dependencies Required

```yaml
dependencies:
  crypto: ^3.0.3  # For SHA512 hash
  webview_flutter: ^4.4.2  # For PayU payment page
```

## Data Flow

### Order Creation Data
```dart
{
  'cartId': 'gid://shopify/Cart/xxx',
  'customerId': 'gid://shopify/Customer/xxx',
  'lineItems': [
    {
      'variantId': 'gid://shopify/ProductVariant/xxx',
      'quantity': 2,
      'price': '999.00'
    }
  ],
  'shippingAddress': {
    'firstName': 'John',
    'lastName': 'Doe',
    'address1': '123 Street',
    'city': 'Mumbai',
    'province': 'Maharashtra',
    'country': 'India',
    'zip': '400086',
    'phone': '9876543210'
  },
  'totalAmount': '1998.00',
  'paymentMethod': 'Pre-paid' or 'COD'
}
```

### PayU Payment Data
```dart
{
  'key': 'merchant_key',
  'txnid': 'ORDER_123_1234567890',
  'amount': '1998.00',
  'productinfo': 'Skincare Products',
  'firstname': 'John',
  'email': 'john@example.com',
  'phone': '9876543210',
  'surl': 'https://yourapp.com/payment/success',
  'furl': 'https://yourapp.com/payment/failure',
  'hash': 'calculated_hash'
}
```

## UI/UX Flow

### After Payment Method Selection

**Pre-paid Selected:**
1. Show loading: "Creating order..."
2. Create draft order in Shopify
3. Show loading: "Redirecting to payment..."
4. Open PayU WebView
5. User completes payment
6. Show loading: "Verifying payment..."
7. Update order status
8. Show order confirmation

**COD Selected:**
1. Show loading: "Creating order..."
2. Create order in Shopify
3. Show order confirmation immediately

### Order Confirmation Screen

```
┌─────────────────────────────────────────────────────┐
│  ✓ Order Placed Successfully!                       │
│                                                     │
│  Order #1234                                        │
│  Estimated Delivery: 5-7 days                       │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Items (3)                                    │ │
│  │  • Product 1 x 2                              │ │
│  │  • Product 2 x 1                              │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Delivery Address                             │ │
│  │  123 Street, Mumbai, Maharashtra              │ │
│  │  400086                                       │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Payment                                      │ │
│  │  Method: Pre-paid / COD                       │ │
│  │  Amount: ₹1,998.00                            │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  [Track Order]  [Continue Shopping]                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Error Handling

### Order Creation Errors
- Network error: Show retry option
- Invalid cart: Show error message
- Out of stock: Show which items are unavailable
- Address validation: Show address errors

### Payment Errors
- Payment cancelled: Return to order summary
- Payment failed: Show error, offer retry
- Network error during payment: Show retry
- Invalid payment details: Show PayU error message

## Security Considerations

1. **Hash Validation**: Always validate PayU hash
2. **HTTPS Only**: All API calls over HTTPS
3. **Secure Storage**: Store merchant credentials securely
4. **Order Verification**: Verify order status after payment
5. **Duplicate Prevention**: Check for duplicate orders

## Testing Checklist

### Pre-paid Payment
- [ ] Create order successfully
- [ ] PayU page opens correctly
- [ ] Test payment with test card
- [ ] Success callback works
- [ ] Order status updated
- [ ] Confirmation screen shows

### COD Payment
- [ ] Create order successfully
- [ ] Order marked as COD
- [ ] Confirmation screen shows
- [ ] No payment gateway involved

### Error Scenarios
- [ ] Network error during order creation
- [ ] Payment cancellation
- [ ] Payment failure
- [ ] Invalid payment details
- [ ] Duplicate order prevention

## Out of Scope (Future Enhancements)

- Order tracking
- Order history
- Order cancellation
- Refund processing
- Multiple payment methods (cards, wallets)
- Saved payment methods

## Questions to Clarify

1. PayU merchant credentials (Key and Salt)?
2. Test or Production environment?
3. Create order before or after payment?
4. Shipping charges calculation?
5. Discount codes support?
6. Order confirmation email (Shopify handles or custom)?

## Next Steps

1. Get PayU credentials
2. Create order service
3. Create PayU service
4. Implement WebView for payment
5. Create order confirmation screen
6. Test end-to-end flow

Ready to implement once we have the PayU credentials and clarify the flow! 🚀
