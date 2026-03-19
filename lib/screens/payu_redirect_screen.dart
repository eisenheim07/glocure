import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../utils/size_utils.dart';
import '../utils/app_logger.dart';

/// PayU Redirect Screen with Timer
/// This screen is shown when PayU redirects to success/failure URLs
/// Shows a 10-second timer before redirecting back to the app
class PayURedirectScreen extends StatefulWidget {
  final String status; // 'success' or 'failure'
  final Map<String, dynamic>? paymentData;

  const PayURedirectScreen({
    super.key,
    required this.status,
    this.paymentData,
  });

  @override
  State<PayURedirectScreen> createState() => _PayURedirectScreenState();
}

class _PayURedirectScreenState extends State<PayURedirectScreen> {
  Timer? _redirectTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    AppLogger.info('PayU Redirect Screen: ${widget.status} - Starting 10 second timer');
    _startRedirectTimer();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _redirectToApp();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _redirectToApp() {
    _redirectTimer?.cancel();
    AppLogger.info('PayU Redirect Screen: Timer completed, redirecting to app');
    
    if (mounted) {
      // Create result data to pass back
      final result = {
        'status': widget.status,
        'paymentData': widget.paymentData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Pop back to the PayU SDK screen with result
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Container(
                width: 102.w,
                height: 102.h,
                decoration: BoxDecoration(
                  color: _getStatusConfig()['backgroundColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusConfig()['icon'],
                  size: 51.h,
                  color: AppColors.white,
                ),
              ),

              SizedBox(height: 24.h),

              // Status title
              Text(
                _getStatusConfig()['title'],
                style: TextStyle(
                  fontSize: 20.fSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // Status message
              Text(
                _getStatusConfig()['message'],
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: AppColors.gray600,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30.h),

              // Timer display
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: AppColors.gray300,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18.h,
                      color: AppColors.gray600,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Redirecting in $_remainingSeconds seconds',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        color: AppColors.gray600,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // Manual navigation button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _redirectToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _getButtonText(),
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig() {
    switch (widget.status.toLowerCase()) {
      case 'success':
        return {
          'icon': Icons.check_circle_outline,
          'backgroundColor': AppColors.success,
          'title': 'Payment Successful!',
          'message': 'Your payment has been processed successfully.\nRedirecting you back to the app...',
        };
      case 'failure':
      case 'failed':
        return {
          'icon': Icons.error_outline,
          'backgroundColor': AppColors.error,
          'title': 'Payment Failed',
          'message': 'We couldn\'t process your payment.\nRedirecting you back to try again...',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_outlined,
          'backgroundColor': AppColors.warning,
          'title': 'Payment Cancelled',
          'message': 'You have cancelled the payment.\nRedirecting you back to the app...',
        };
      default:
        return {
          'icon': Icons.info_outline,
          'backgroundColor': AppColors.gray500,
          'title': 'Payment Status',
          'message': 'Processing payment status...',
        };
    }
  }

  String _getButtonText() {
    switch (widget.status.toLowerCase()) {
      case 'success':
        return 'Continue to App';
      case 'failure':
      case 'failed':
        return 'Back to App';
      case 'cancelled':
        return 'Back to App';
      default:
        return 'Continue';
    }
  }
}