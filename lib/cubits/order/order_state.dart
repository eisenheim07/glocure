import '../../models/order_model.dart';

/// Order States
abstract class OrderState {}

/// Initial state
class OrderInitial extends OrderState {}

/// Creating order
class OrderCreating extends OrderState {}

/// Order created successfully
class OrderCreated extends OrderState {
  final OrderModel order;

  OrderCreated(this.order);
}

/// Order creation failed
class OrderError extends OrderState {
  final String message;

  OrderError(this.message);
}
