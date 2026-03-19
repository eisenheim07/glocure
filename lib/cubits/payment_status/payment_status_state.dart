abstract class PaymentStatusState {}

class PaymentStatusInitial extends PaymentStatusState {}

class PaymentStatusGeneratingCart extends PaymentStatusState {}

class PaymentStatusCartGenerated extends PaymentStatusState {}

class PaymentStatusError extends PaymentStatusState {
  final String message;

  PaymentStatusError(this.message);
}