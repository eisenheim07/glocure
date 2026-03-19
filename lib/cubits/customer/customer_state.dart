import '../../models/customer_model.dart';

/// Base state for Customer
abstract class CustomerState {}

/// Initial state
class CustomerInitial extends CustomerState {}

/// Loading state
class CustomerLoading extends CustomerState {}

/// Success state with customer data
class CustomerSuccess extends CustomerState {
  final Customer customer;

  CustomerSuccess(this.customer);
}

/// Error state
class CustomerError extends CustomerState {
  final String message;

  CustomerError(this.message);
}
