import 'package:flutter/material.dart';
import '../services/payu_sdk_service.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_colors.dart';
import '../utils/size_utils.dart';
import '../widgets/custom_app_bar.dart';
import 'payu_redirect_screen.dart';

/// PayU SDK Payment Screen
class PayUSDKScreen extends StatefulWidget {
  final OrderModel order;
  final Customer customer;
  final double totalAmountWithShipping;

  const PayUSDKScreen({
    super.key,
    required this.order,
    required this.customer,
    required this.totalAmountWithShipping,
  });

  @override
  State<PayUSDKScreen> createState() => _PayUSDKScreenState();
}

class _PayUSDKScreenState extends State<PayUSDKScreen> {
  final PayUSDKService _payuService = PayUSDKService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the screen is fully rendered before starting payment
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startPayment();
      }
    });
  }

  void _startPayment() {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    AppLogger.info('PayU_SDK Screen: Starting payment initialization');

    _payuService.startPayment(
      context: context,
      order: widget.order,
      customer: widget.customer,
      totalAmount: widget.totalAmountWithShipping,
      // totalAmount: 1,
      onSuccess: (result) {
        AppLogger.success('PayU_SDK Payment Success: $result');
        if (mounted) {
          _showTimerScreen('success', result);
        }
      },
      onFailure: (result) {
        AppLogger.error('PayU_SDK Payment Failed: $result');
        if (mounted) {
          _showTimerScreen('failure', result);
        }
      },
      onCancel: (result) {
        AppLogger.info('PayU_SDK Payment Cancelled: $result');
        if (mounted) {
          _showTimerScreen('cancelled', result);
        }
      },
      onError: (result) {
        AppLogger.error('PayU_SDK Error: $result');
        if (mounted) {
          _showTimerScreen('error', result);
        }
      },
    );
  }

  /// Show timer screen and then return result
  Future<void> _showTimerScreen(String status, Map<String, dynamic> result) async {
    AppLogger.info('PayU SDK Screen: Showing timer screen for status: $status');

    // Navigate to timer screen and wait for result
    final timerResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayURedirectScreen(
          status: status,
          paymentData: result,
        ),
      ),
    );

    // After timer completes, return the original result
    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // appBar: AppBar(
      //   title: const Text('Payment'),
      //   backgroundColor: AppColors.primary,
      //   foregroundColor: AppColors.white,
      // ),
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Payment',
      ),
      body: SafeArea(
        child: _buildLoadingScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isProcessing) ...[
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Initializing Payment...',
              style: TextStyle(
                fontSize: 16.fSize,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 8.h),
            Text('Please wait while we set up your payment',
                style: TextStyle(fontSize: 14.fSize, color: AppColors.textMuted, fontFamily: 'Inter'), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
