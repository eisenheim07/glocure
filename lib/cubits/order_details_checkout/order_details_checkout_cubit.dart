import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/customer_model.dart';
import '../../models/top_products_model.dart';
import '../../utils/app_logger.dart';
import 'order_details_checkout_state.dart';

/// Order Details Checkout Cubit
/// Manages the state for the order details checkout screen
class OrderDetailsCheckoutCubit extends Cubit<OrderDetailsCheckoutState> {
  OrderDetailsCheckoutCubit() : super(OrderDetailsCheckoutInitial());

  /// Initialize the order details with product and customer data
  void initializeOrderDetails({
    required TopProduct product,
    required ProductVariant selectedVariant,
    required Customer customer,
    int quantity = 1,
    int? maxQuantity,
  }) {
    try {
      emit(OrderDetailsCheckoutLoading());

      // Calculate pricing
      final itemPrice = double.parse(selectedVariant.priceV2.amount) * quantity;
      const shippingCharges = 99.0;
      final needsShipping = itemPrice < 1000;
      final totalPrice = needsShipping ? itemPrice + shippingCharges : itemPrice;

      AppLogger.info('Order Details Initialized:');
      AppLogger.info('Product: ${product.title}');
      AppLogger.info('Variant: ${selectedVariant.title}');
      AppLogger.info('Quantity: $quantity');
      AppLogger.info('Max Quantity: ${maxQuantity ?? 'unlimited'}');
      AppLogger.info('Item Price: ₹$itemPrice');
      AppLogger.info('Shipping: ${needsShipping ? '₹$shippingCharges' : 'FREE'}');
      AppLogger.info('Total: ₹$totalPrice');

      emit(OrderDetailsCheckoutLoaded(
        product: product,
        selectedVariant: selectedVariant,
        customer: customer,
        quantity: quantity,
        maxQuantity: maxQuantity,
        itemPrice: itemPrice,
        shippingCharges: shippingCharges,
        totalPrice: totalPrice,
        needsShipping: needsShipping,
      ));
    } catch (e) {
      AppLogger.error('Error initializing order details: $e');
      emit(OrderDetailsCheckoutError('Failed to load order details: $e'));
    }
  }

  /// Update quantity
  void updateQuantity(int newQuantity) {
    final currentState = state;
    if (currentState is OrderDetailsCheckoutLoaded && newQuantity > 0) {
      final itemPrice = double.parse(currentState.selectedVariant.priceV2.amount) * newQuantity;
      const shippingCharges = 99.0;
      final needsShipping = itemPrice < 1000;
      final totalPrice = needsShipping ? itemPrice + shippingCharges : itemPrice;

      AppLogger.info('Quantity updated to: $newQuantity');
      AppLogger.info('New Item Price: ₹$itemPrice');
      AppLogger.info('New Total: ₹$totalPrice');

      emit(OrderDetailsCheckoutLoaded(
        product: currentState.product,
        selectedVariant: currentState.selectedVariant,
        customer: currentState.customer,
        quantity: newQuantity,
        maxQuantity: currentState.maxQuantity,
        itemPrice: itemPrice,
        shippingCharges: shippingCharges,
        totalPrice: totalPrice,
        needsShipping: needsShipping,
      ));
    }
  }

  /// Set payment loading state
  void setPaymentLoading(bool isLoading) {
    if (isLoading) {
      emit(OrderDetailsCheckoutPaymentLoading());
    } else {
      // Return to loaded state if we have the data
      final currentState = state;
      if (currentState is OrderDetailsCheckoutLoaded) {
        emit(currentState);
      }
    }
  }

  /// Reset to initial state
  void reset() {
    emit(OrderDetailsCheckoutInitial());
  }
}