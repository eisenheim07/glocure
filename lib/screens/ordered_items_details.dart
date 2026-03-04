import 'package:flutter/material.dart';
import 'package:glocure/models/shopify_order_model.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/utils/size_utils.dart';

class OrderedItemsDetails extends StatelessWidget {
  final ShopifyOrder order;

  const OrderedItemsDetails({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderSummaryCard(),
            
            SizedBox(height: 20.h),
            
            // Items Section
            _buildItemsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.h,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: Color(int.parse(order.statusColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.displayStatus,
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Order Details
          _buildDetailRow('Order Number', order.name),
          _buildDetailRow('Order Date', _formatDate(order.createdAt)),
          _buildDetailRow('Email', order.email),
          
          SizedBox(height: 16.h),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          SizedBox(height: 16.h),
          
          // Price Details
          _buildPriceRow('Subtotal', '₹${order.subtotalPrice}'),
          _buildPriceRow('Tax', '₹${order.totalTax}'),
          
          SizedBox(height: 12.h),
          
          // Total
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPriceRow(
              'Total Amount',
              '₹${order.totalPrice}',
              isTotal: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${order.lineItems.length})',
          style: TextStyle(
            fontSize: 18.fSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Items List
        ...order.lineItems.map((item) => _buildItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildItemCard(ShopifyLineItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          if (item.variantTitle.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              item.variantTitle,
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          SizedBox(height: 12.h),
          
          // Item Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.sku.isNotEmpty) ...[
                      _buildItemDetailRow('SKU', item.sku),
                      SizedBox(height: 4.h),
                    ],
                    _buildItemDetailRow('Quantity', '${item.quantity}'),
                    SizedBox(height: 4.h),
                    _buildItemDetailRow('Price', item.formattedPrice),
                    if (item.vendor.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      _buildItemDetailRow('Vendor', item.vendor),
                    ],
                  ],
                ),
              ),
              
              // Total Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.totalPrice,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5C9A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.fSize,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? 8.h : 4.h,
        horizontal: isTotal ? 12.h : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.fSize : 14.fSize,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal ? Colors.black : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16.fSize : 14.fSize,
              fontWeight: FontWeight.w600,
              color: isTotal ? const Color(0xFFFF5C9A) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.fSize,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.fSize,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}