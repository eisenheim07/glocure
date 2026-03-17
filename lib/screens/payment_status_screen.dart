import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/size_utils.dart';
import '../models/order_model.dart';
import '../utils/format_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../cubits/payment_status/payment_status_cubit.dart';
import '../cubits/payment_status/payment_status_state.dart';
import 'main_navigation_screen.dart';

/// Payment Status Screen
/// Shows payment result (success, failed, cancelled) with order details
class PaymentStatusScreen extends StatefulWidget {
  final String status; // 'success', 'failed', 'cancelled'
  final OrderModel order;
  final Map<String, dynamic>? payuData; // PayU response data

  const PaymentStatusScreen({
    super.key,
    required this.status,
    required this.order,
    this.payuData, // Optional PayU data
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Generate new cart ID if payment is successful
    if (widget.status.toLowerCase() == 'success') {
      context.read<PaymentStatusCubit>().generateNewCartId();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          type: AppBarType.simple,
          title: 'Payment Status',
          onBackPressed: () => _navigateToHome(context),
        ),
        body: SafeArea(
          child: BlocBuilder<PaymentStatusCubit, PaymentStatusState>(
            builder: (context, state) {
              final isGeneratingCart = state is PaymentStatusGeneratingCart;
              return isGeneratingCart ? _buildLoadingShimmer() : _buildContent(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                SizedBox(height: 40),

                // Status icon and message
                _buildStatusSection(),

                SizedBox(height: 40),

                // Order details card
                _buildOrderDetailsCard(),

                SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(context),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        // Scrollable shimmer content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                SizedBox(height: 40),

                // Status section shimmer
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Column(
                    children: [
                      // Status icon shimmer
                      Container(
                        width: 102.w,
                        height: 102.h,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Status title shimmer
                      Container(
                        width: 200.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Status message shimmer
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 250.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Order details card shimmer
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    width: double.infinity,
                    height: 300.h,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom buttons shimmer
        Container(
          padding: EdgeInsets.fromLTRB(8.h, 12.h, 12.h, 0.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary button shimmer
                Container(
                  width: double.infinity,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),

                SizedBox(height: 12),

                // Secondary button shimmer
                Container(
                  width: double.infinity,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final statusConfig = _getStatusConfig();

    return Column(
      children: [
        // Status icon
        Container(
          width: 102.w,
          height: 102.h,
          decoration: BoxDecoration(
            color: statusConfig['backgroundColor'],
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusConfig['icon'],
            size: 51.h,
            color: statusConfig['iconColor'],
          ),
        ),

        SizedBox(height: 24),

        // Status title
        Text(
          statusConfig['title'],
          style: TextStyle(
            fontSize: 20.fSize,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 12),

        // Status message
        Text(
          statusConfig['message'],
          style: TextStyle(
            fontSize: 13.fSize,
            color: AppColors.gray600,
            fontFamily: 'Inter',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
    // Use PayU transaction amount if available, otherwise use order total
    String totalAmount;
    if (widget.payuData != null && widget.payuData!['txnAmount'] != null) {
      totalAmount = widget.payuData!['txnAmount'].toString();
    } else {
      totalAmount = widget.order.totalPrice ?? '0';
    }

    // Parse the total amount to check if shipping charges should be added
    final numericTotal = double.tryParse(totalAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final finalTotal = numericTotal < 1000 ? numericTotal + 99 : numericTotal;
    final formattedTotal = formatIndianCurrency(finalTotal.toString());

    final itemCount = widget.order.lineItems.length;
    final createdAt = widget.order.createdAt != null ? _formatDateTime(widget.order.createdAt!) : 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.gray200,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Text(
            'Order Details',
            style: TextStyle(
              fontSize: 15.fSize,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              fontFamily: 'Inter',
            ),
          ),

          SizedBox(height: 20),

          // Order ID
          _buildDetailRow(
            'Order ID',
            '#${widget.order.orderNumber ?? widget.order.id ?? 'N/A'}',
          ),

          SizedBox(height: 16),

          // Order Date
          _buildDetailRow(
            'Order Date',
            createdAt,
          ),

          SizedBox(height: 16),

          // Number of Items
          _buildDetailRow(
            'Items',
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          ),

          SizedBox(height: 16),

          // Payment Method
          _buildDetailRow(
            'Payment Method',
            _getPaymentMethod(),
          ),

          // Transaction Reference ID (if available from PayU)
          if (widget.payuData != null && 
              widget.payuData!['txnRefId'] != null && 
              widget.payuData!['txnRefId'].toString().isNotEmpty)
            ...[
              SizedBox(height: 16),
              _buildDetailRow(
                'Transaction Ref ID',
                widget.payuData!['txnRefId'].toString(),
              ),
            ],

          SizedBox(height: 20),

          // Divider
          Divider(
            color: AppColors.gray300,
            thickness: 1,
          ),

          SizedBox(height: 20),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                formattedTotal,
                style: TextStyle(
                  fontSize: 17.fSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.fSize,
            color: AppColors.gray600,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.h, 12.h, 12.h, 0.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary button (based on status)
          if (widget.status == 'success')
            _buildPrimaryButton(
              context,
              'Continue Shopping',
              () => _navigateToHome(context),
            )
          else if (widget.status == 'failed')
            _buildPrimaryButton(
              context,
              'Try Again',
              () => _navigateToHome(context),
            )
          else
            _buildPrimaryButton(
              context,
              'Back to Home',
              () => _navigateToHome(context),
            ),

          SizedBox(height: 12),

          // Secondary button (View Orders)
          _buildSecondaryButton(
            context,
            'View My Orders',
            () {
              // Navigate to main screen with orders tab selected
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 3),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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
          'iconColor': AppColors.white,
          'backgroundColor': AppColors.success,
          'title': 'Payment Successful!',
          'message': 'Your order has been placed successfully.\nYou will receive a confirmation email shortly.',
        };
      case 'failed':
        return {
          'icon': Icons.error_outline,
          'iconColor': AppColors.white,
          'backgroundColor': AppColors.error,
          'title': 'Payment Failed',
          'message': 'We couldn\'t process your payment.\nPlease try again or use a different payment method.',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_outlined,
          'iconColor': AppColors.white,
          'backgroundColor': AppColors.warning,
          'title': 'Payment Cancelled',
          'message': 'You have cancelled the payment.\nYour order has been created but not confirmed.',
        };
      default:
        return {
          'icon': Icons.info_outline,
          'iconColor': AppColors.white,
          'backgroundColor': AppColors.gray500,
          'title': 'Payment Status Unknown',
          'message': 'Unable to determine payment status.',
        };
    }
  }

  String _getPaymentMethod() {
    final tags = widget.order.tags?.split(',') ?? [];
    final isPrePaid = tags.any(
      (tag) => tag.trim().toLowerCase().contains('pre-paid') || tag.trim().toLowerCase().contains('prepaid'),
    );
    return isPrePaid ? 'Pre-paid (Online)' : 'Cash on Delivery';
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final day = dateTime.day;
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$day $month $year, $hour:$minute $period';
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'N/A';
    }
  }

  void _navigateToHome(BuildContext context) {
    // Remove all routes and navigate to home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
