import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/order_service.dart';
import '../../models/cart_model.dart';
import '../../models/customer_model.dart';
import 'order_state.dart';

/// Order Cubit
/// Manages order creation and state
class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService;

  OrderCubit({OrderService? orderService})
      : _orderService = orderService ?? OrderService(),
        super(OrderInitial());

  /// Create order in Shopify
  Future<void> createOrder({
    required Cart cart,
    required Customer customer,
    required String paymentMethod,
  }) async {
    emit(OrderCreating());

    try {
      final order = await _orderService.createOrder(
        cart: cart,
        customer: customer,
        paymentMethod: paymentMethod,
      );

      emit(OrderCreated(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(OrderInitial());
  }
}
