import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/payment_selection/payment_selection_cubit.dart';
import '../cubits/payment_selection/payment_selection_state.dart';
import '../cubits/order/order_cubit.dart';
import '../cubits/order/order_state.dart';
import '../models/serviceability_model.dart';
import '../models/cart_model.dart';
import '../models/customer_model.dart';
import '../services/order_service.dart';
import '../utils/app_logger.dart';
import '../utils/app_colors.dart';
import '../screens/payu_payment_screen.dart';

/// Payment Selection Bottom Sheet
/// Shows available payment options based on delivery serviceability
class PaymentSelectionBottomSheet extends StatelessWidget {
  final String pincode;
  final Cart cart;
  final Customer customer;
  final Function(String paymentMethod)? onPaymentSelected;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.pincode,
    required this.cart,
    required this.customer,
    this.onPaymentSelected,
  });

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String pincode,
    required Cart cart,
    required Customer customer,
    Function(String paymentMethod)? onPaymentSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => BlocProvider(
        create: (context) => PaymentSelectionCubit()
          ..checkServiceability(pincode),
        child: PaymentSelectionBottomSheet(
          pincode: pincode,
          cart: cart,
          customer: customer,
          onPaymentSelected: onPaymentSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            BlocBuilder<PaymentSelectionCubit, PaymentSelectionState>(
              builder: (context, paymentState) {
                if (paymentState is PaymentSelectionLoading) {
                  return _buildLoadingState();
                } else if (paymentState is PaymentSelectionSuccess) {
                  return _buildPaymentOptions(context, paymentState.serviceability);
                } else if (paymentState is PaymentSelectionError) {
                  return _buildErrorState(context, paymentState.message);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Checking delivery availability...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(
    BuildContext context,
    ServiceabilityModel serviceability,
  ) {
    final isServiceable = serviceability.isServiceable;
    final supportsPrepaid = serviceability.supportsPrepaid;
    final supportsCOD = serviceability.supportsCOD;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pre-paid option
          _buildPaymentOption(
            context: context,
            icon: Icons.payment,
            title: 'Pre-paid',
            subtitle: 'UPI / Online Payment',
            enabled: isServiceable && supportsPrepaid,
            onTap: () => _handlePrepaidSelection(context),
          ),

          const SizedBox(height: 12),

          // COD option
          _buildPaymentOption(
            context: context,
            icon: Icons.money,
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive',
            enabled: isServiceable && supportsCOD,
            onTap: () => _handleCODSelection(context),
          ),

          // Error message if not serviceable
          if (!isServiceable) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.errorLight,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery is unavailable at this pincode',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.white : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.borderPrimary : AppColors.borderSecondary,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.gray400,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.textPrimary : AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled ? AppColors.gray600 : AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow or disabled indicator
            Icon(
              enabled ? Icons.arrow_forward_ios : Icons.block,
              color: enabled ? AppColors.gray400 : AppColors.gray300,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to check delivery availability',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<PaymentSelectionCubit>().checkServiceability(pincode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _handlePrepaidSelection(BuildContext context) {
    AppLogger.info('Pre-paid payment method selected');
    // Close bottom sheet and notify parent
    Navigator.pop(context);
    onPaymentSelected?.call('Pre-paid');
  }

  void _handleCODSelection(BuildContext context) {
    AppLogger.info('COD payment method selected');
    // Close bottom sheet and notify parent
    Navigator.pop(context);
    onPaymentSelected?.call('COD');
  }
}
