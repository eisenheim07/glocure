import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/delivery_service.dart';
import 'payment_selection_state.dart';

/// Payment Selection Cubit
/// Manages the state of payment selection and delivery serviceability check
class PaymentSelectionCubit extends Cubit<PaymentSelectionState> {
  final DeliveryService _deliveryService;

  PaymentSelectionCubit({DeliveryService? deliveryService})
      : _deliveryService = deliveryService ?? DeliveryService(),
        super(PaymentSelectionInitial());

  /// Check if delivery is serviceable for the given pincode
  Future<void> checkServiceability(String pincode) async {
    if (pincode.isEmpty) {
      emit(PaymentSelectionError('Pincode is required'));
      return;
    }

    emit(PaymentSelectionLoading());

    try {
      final serviceability = await _deliveryService.checkServiceability(pincode);
      emit(PaymentSelectionSuccess(serviceability));
    } catch (e) {
      emit(PaymentSelectionError(e.toString()));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(PaymentSelectionInitial());
  }
}
