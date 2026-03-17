import '../../models/order_model.dart';
import '../../models/serviceability_model.dart';

/// Payment Flow States
/// Common states for payment flow across different screens
abstract class PaymentFlowState {}

/// Initial state
class PaymentFlowInitial extends PaymentFlowState {}

/// Checking delivery serviceability
class PaymentFlowCheckingDelivery extends PaymentFlowState {}

/// Delivery serviceability checked successfully
class PaymentFlowDeliveryChecked extends PaymentFlowState {
  final ServiceabilityModel serviceability;

  PaymentFlowDeliveryChecked(this.serviceability);
}

/// Creating order
class PaymentFlowCreatingOrder extends PaymentFlowState {}

/// Order created successfully
class PaymentFlowOrderCreated extends PaymentFlowState {
  final OrderModel order;
  final String paymentMethod;
  final double totalAmountWithShipping;

  PaymentFlowOrderCreated(this.order, this.paymentMethod, this.totalAmountWithShipping);
}

/// Payment completed (success/failed/cancelled)
class PaymentFlowPaymentCompleted extends PaymentFlowState {
  final String status;
  final OrderModel order;

  PaymentFlowPaymentCompleted(this.status, this.order);
}

/// Error state
class PaymentFlowError extends PaymentFlowState {
  final String message;

  PaymentFlowError(this.message);
}