import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/format_utils.dart';
import '../widgets/custom_app_bar.dart';
import 'main_navigation_screen.dart';

/// Payment Status Screen
/// Shows payment result (success, failed, cancelled) with order details
class PaymentStatusScreen extends StatelessWidget {
  final String status; // 'success', 'failed', 'cancelled'
  final OrderModel order;

  const PaymentStatusScreen({
    super.key,
    required this.status,
    required this.order,
  });

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
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          type: AppBarType.simple,
          title: 'Payment Status',
          onBackPressed: () => _navigateToHome(context),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Status icon and message
                      _buildStatusSection(),

                      const SizedBox(height: 40),

                      // Order details card
                      _buildOrderDetailsCard(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              _buildBottomButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final statusConfig = _getStatusConfig();

    return Column(
      children: [
        // Status icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: statusConfig['backgroundColor'],
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusConfig['icon'],
            size: 60,
            color: statusConfig['iconColor'],
          ),
        ),

        const SizedBox(height: 24),

        // Status title
        Text(
          statusConfig['title'],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Status message
        Text(
          statusConfig['message'],
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
    final totalAmount = order.totalPrice ?? '0';
    final formattedTotal = formatIndianCurrency(totalAmount);
    final itemCount = order.lineItems.length;
    final createdAt = order.createdAt != null
        ? _formatDateTime(order.createdAt!)
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          // Order ID
          _buildDetailRow(
            'Order ID',
            '#${order.orderNumber ?? order.id ?? 'N/A'}',
          ),

          const SizedBox(height: 16),

          // Order Date
          _buildDetailRow(
            'Order Date',
            createdAt,
          ),

          const SizedBox(height: 16),

          // Number of Items
          _buildDetailRow(
            'Items',
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          ),

          const SizedBox(height: 16),

          // Payment Method
          _buildDetailRow(
            'Payment Method',
            _getPaymentMethod(),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),

          const SizedBox(height: 20),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                formattedTotal,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF5C9A),
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
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary button (based on status)
          if (status == 'success')
            _buildPrimaryButton(
              context,
              'Continue Shopping',
              () => _navigateToHome(context),
            )
          else if (status == 'failed')
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

          const SizedBox(height: 12),

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
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5C9A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF5C9A),
          side: const BorderSide(
            color: Color(0xFFFF5C9A),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig() {
    switch (status.toLowerCase()) {
      case 'success':
        return {
          'icon': Icons.check_circle_outline,
          'iconColor': Colors.white,
          'backgroundColor': const Color(0xFF4CAF50),
          'title': 'Payment Successful!',
          'message':
              'Your order has been placed successfully.\nYou will receive a confirmation email shortly.',
        };
      case 'failed':
        return {
          'icon': Icons.error_outline,
          'iconColor': Colors.white,
          'backgroundColor': Colors.red.shade400,
          'title': 'Payment Failed',
          'message':
              'We couldn\'t process your payment.\nPlease try again or use a different payment method.',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_outlined,
          'iconColor': Colors.white,
          'backgroundColor': Colors.orange.shade400,
          'title': 'Payment Cancelled',
          'message':
              'You have cancelled the payment.\nYour order has been created but not confirmed.',
        };
      default:
        return {
          'icon': Icons.info_outline,
          'iconColor': Colors.white,
          'backgroundColor': Colors.grey.shade400,
          'title': 'Payment Status Unknown',
          'message': 'Unable to determine payment status.',
        };
    }
  }

  String _getPaymentMethod() {
    final tags = order.tags?.split(',') ?? [];
    final isPrePaid = tags.any(
      (tag) =>
          tag.trim().toLowerCase().contains('pre-paid') ||
          tag.trim().toLowerCase().contains('prepaid'),
    );
    return isPrePaid ? 'Pre-paid (Online)' : 'Cash on Delivery';
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

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
