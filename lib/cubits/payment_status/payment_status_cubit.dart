import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import 'payment_status_state.dart';

class PaymentStatusCubit extends Cubit<PaymentStatusState> {
  PaymentStatusCubit() : super(PaymentStatusInitial());

  /// Generate new cart ID for successful payments
  /// Uses the new createNewCartId method to force create a new cart
  Future<void> generateNewCartId() async {
    emit(PaymentStatusGeneratingCart());

    try {
      AppLogger.info('🛒 Payment successful - generating new cart ID...');
      
      // Force create a new cart ID (replace existing one)
      await ApiService().createNewCartId();
      
      AppLogger.success('✅ New cart ID generated successfully');
      emit(PaymentStatusCartGenerated());
    } catch (e) {
      AppLogger.error('⚠️ Failed to generate new cart ID: $e');
      // Don't block UI if cart creation fails - emit success anyway
      emit(PaymentStatusCartGenerated());
    }
  }
}