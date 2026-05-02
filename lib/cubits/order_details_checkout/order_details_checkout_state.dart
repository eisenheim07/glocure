import '../../models/customer_model.dart';
import '../../models/top_products_model.dart';

/// Order Details Checkout States
abstract class OrderDetailsCheckoutState {
  const OrderDetailsCheckoutState();
}

/// Initial state
class OrderDetailsCheckoutInitial extends OrderDetailsCheckoutState {}

/// Loading state
class OrderDetailsCheckoutLoading extends OrderDetailsCheckoutState {}

/// Loaded state with product and customer data
class OrderDetailsCheckoutLoaded extends OrderDetailsCheckoutState {
  final TopProduct product;
  final ProductVariant selectedVariant;
  final Customer customer;
  final int quantity;
  final int? maxQuantity;
  final double itemPrice;
  final double shippingCharges;
  final double totalPrice;
  final bool needsShipping;

  const OrderDetailsCheckoutLoaded({
    required this.product,
    required this.selectedVariant,
    required this.customer,
    required this.quantity,
    this.maxQuantity,
    required this.itemPrice,
    required this.shippingCharges,
    required this.totalPrice,
    required this.needsShipping,
  });
}

/// Payment loading state
class OrderDetailsCheckoutPaymentLoading extends OrderDetailsCheckoutState {}

/// Error state
class OrderDetailsCheckoutError extends OrderDetailsCheckoutState {
  final String message;

  const OrderDetailsCheckoutError(this.message);
}