import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/delivery_service.dart';
import '../../services/order_service.dart';
import '../../models/cart_model.dart' as cart_model;
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/serviceability_model.dart';
import '../../models/top_products_model.dart';
import '../../utils/app_logger.dart';
import 'payment_flow_state.dart';

/// Payment Flow Cubit
/// Common cubit for handling payment flow across different screens
/// Used by both Order Summary and Product Details screens
class PaymentFlowCubit extends Cubit<PaymentFlowState> {
  final DeliveryService _deliveryService;
  final OrderService _orderService;

  PaymentFlowCubit({
    DeliveryService? deliveryService,
    OrderService? orderService,
  })  : _deliveryService = deliveryService ?? DeliveryService(),
        _orderService = orderService ?? OrderService(),
        super(PaymentFlowInitial());

  /// Check delivery serviceability for a pincode
  Future<void> checkDeliveryServiceability(String pincode) async {
    if (pincode.isEmpty) {
      emit(PaymentFlowError('Pincode is required'));
      return;
    }

    emit(PaymentFlowCheckingDelivery());

    try {
      AppLogger.info('Checking delivery serviceability for pincode: $pincode');
      final serviceability = await _deliveryService.checkServiceability(pincode);
      emit(PaymentFlowDeliveryChecked(serviceability));
    } catch (e) {
      AppLogger.error('Delivery serviceability check failed: $e');
      emit(PaymentFlowError('Failed to check delivery availability: ${e.toString()}'));
    }
  }

  /// Create order with selected payment method
  Future<void> createOrder({
    required cart_model.Cart cart,
    required Customer customer,
    required String paymentMethod,
  }) async {
    emit(PaymentFlowCreatingOrder());

    try {
      AppLogger.info('Creating order with payment method: $paymentMethod');
      
      // Validate inputs
      if (cart.lines.isEmpty) {
        throw Exception('Cart is empty');
      }

      if (customer.defaultAddress == null) {
        throw Exception('Shipping address is required');
      }

      // Calculate total with shipping charges
      final subtotal = double.tryParse(cart.cost?.subtotalAmount.amount ?? '0') ?? 0;
      const shippingCharges = 99.0;
      final needsShipping = subtotal < 1000;
      final totalWithShipping = needsShipping ? subtotal + shippingCharges : subtotal;

      AppLogger.info('Order calculation: Subtotal: ₹$subtotal, Shipping: ${needsShipping ? '₹$shippingCharges' : 'FREE'}, Total: ₹$totalWithShipping');

      final order = await _orderService.createOrder(
        cart: cart,
        customer: customer,
        paymentMethod: paymentMethod,
      );

      AppLogger.success('Order created successfully: ${order.id}');
      
      // Pass the calculated total with shipping to the next state
      emit(PaymentFlowOrderCreated(order, paymentMethod, totalWithShipping));
    } catch (e) {
      AppLogger.error('Order creation failed: $e');
      emit(PaymentFlowError('Failed to create order: ${e.toString()}'));
    }
  }

  /// Create order for single product (Buy Now functionality)
  Future<void> createSingleProductOrder({
    required TopProduct product,
    required ProductVariant selectedVariant,
    required Customer customer,
    required String paymentMethod,
    int quantity = 1,
  }) async {
    emit(PaymentFlowCreatingOrder());

    try {
      AppLogger.info('Creating single product order for: ${product.title}');
      
      // Validate inputs
      if (customer.defaultAddress == null) {
        throw Exception('Shipping address is required');
      }

      // Calculate item price
      final itemPrice = double.parse(selectedVariant.priceV2.amount) * quantity;
      
      // Calculate shipping charges (₹99 for orders below ₹1000, FREE for ₹1000+)
      const shippingCharges = 99.0;
      final needsShipping = itemPrice < 1000;
      final totalPrice = needsShipping ? itemPrice + shippingCharges : itemPrice;

      AppLogger.info('Order calculation: Item price: ₹$itemPrice, Shipping: ${needsShipping ? '₹$shippingCharges' : 'FREE'}, Total: ₹$totalPrice');

      // Create a temporary cart-like structure for single product
      final tempCart = cart_model.Cart(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        discountCodes: [], // Empty discount codes
        lines: [
          cart_model.CartLine(
            id: 'temp-line-${DateTime.now().millisecondsSinceEpoch}',
            quantity: quantity,
            attributes: [], // Empty attributes
            merchandise: cart_model.CartMerchandise(
              id: selectedVariant.id,
              title: selectedVariant.title,
              availableForSale: selectedVariant.availableForSale,
              priceV2: cart_model.Money(
                amount: selectedVariant.priceV2.amount,
                currencyCode: selectedVariant.priceV2.currencyCode,
              ),
              compareAtPriceV2: selectedVariant.compareAtPriceV2 != null 
                ? cart_model.Money(
                    amount: selectedVariant.compareAtPriceV2!.amount,
                    currencyCode: selectedVariant.compareAtPriceV2!.currencyCode,
                  )
                : null,
              product: cart_model.CartProduct(
                id: product.id,
                title: product.title,
                handle: product.handle,
                imageUrl: product.images.isNotEmpty ? product.images.first.originalSrc : null,
              ),
            ),
          ),
        ],
        cost: cart_model.CartCost(
          subtotalAmount: cart_model.Money(
            amount: itemPrice.toString(),
            currencyCode: selectedVariant.priceV2.currencyCode,
          ),
          totalAmount: cart_model.Money(
            amount: totalPrice.toString(), // Include shipping charges in total
            currencyCode: selectedVariant.priceV2.currencyCode,
          ),
        ),
      );

      final order = await _orderService.createOrder(
        cart: tempCart,
        customer: customer,
        paymentMethod: paymentMethod,
      );

      AppLogger.success('Single product order created successfully: ${order.id}');
      
      // Pass the calculated total with shipping to the next state
      emit(PaymentFlowOrderCreated(order, paymentMethod, totalPrice));
    } catch (e) {
      AppLogger.error('Single product order creation failed: $e');
      emit(PaymentFlowError('Failed to create order: ${e.toString()}'));
    }
  }

  /// Update order status after payment
  Future<void> updateOrderStatus({
    required String orderId,
    required String financialStatus,
  }) async {
    try {
      AppLogger.info('Updating order status: $orderId -> $financialStatus');
      await _orderService.updateOrderStatus(
        orderId: orderId,
        financialStatus: financialStatus,
      );
      AppLogger.success('Order status updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update order status: $e');
      // Don't emit error state as this is not critical for user flow
    }
  }

  /// Reset to initial state
  void reset() {
    emit(PaymentFlowInitial());
  }

  /// Handle payment result from PayU
  void handlePaymentResult(String status, OrderModel order) {
    AppLogger.info('Payment result received: $status for order: ${order.id}');
    
    if (status.toLowerCase() == 'success') {
      // Update order status to paid
      updateOrderStatus(orderId: order.id!, financialStatus: 'paid');
    }
    
    emit(PaymentFlowPaymentCompleted(status, order));
  }
}