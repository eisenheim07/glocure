import '../../models/serviceability_model.dart';

/// Payment Selection States
abstract class PaymentSelectionState {}

/// Initial state
class PaymentSelectionInitial extends PaymentSelectionState {}

/// Loading state - checking serviceability
class PaymentSelectionLoading extends PaymentSelectionState {}

/// Success state - serviceability checked
class PaymentSelectionSuccess extends PaymentSelectionState {
  final ServiceabilityModel serviceability;

  PaymentSelectionSuccess(this.serviceability);
}

/// Error state - failed to check serviceability
class PaymentSelectionError extends PaymentSelectionState {
  final String message;

  PaymentSelectionError(this.message);
}
