import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../cart_indicator/cart_indicator_cubit.dart';
import 'payment_status_state.dart';

class PaymentStatusCubit extends Cubit<PaymentStatusState> {
  PaymentStatusCubit() : super(PaymentStatusInitial());

  /// Generate new cart ID for successful payments
  /// Uses the new createNewCartId method to force create a new cart
  /// [skipCartGeneration] - If true, skips the GraphQL call and just shows shimmer
  Future<void> generateNewCartId({bool skipCartGeneration = false}) async {
    emit(PaymentStatusGeneratingCart());

    try {
      if (skipCartGeneration) {
        AppLogger.info('🛒 Skipping cart ID generation for single product purchase...');
        // Just show shimmer for a brief moment then complete
        await Future.delayed(const Duration(milliseconds: 1500));
        AppLogger.info('✅ Cart generation skipped successfully');
      } else {
        AppLogger.info('🛒 Payment successful - generating new cart ID...');
        
        // Force create a new cart ID (replace existing one)
        await ApiService().createNewCartId();
        
        AppLogger.success('✅ New cart ID generated successfully');
      }
      
      emit(PaymentStatusCartGenerated());
    } catch (e) {
      AppLogger.error('⚠️ Failed to generate new cart ID: $e');
      // Don't block UI if cart creation fails - emit success anyway
      emit(PaymentStatusCartGenerated());
    }
  }
}