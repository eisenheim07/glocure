import 'package:flutter/material.dart';
import '../utils/size_utils.dart';
import 'package:glocure/models/shopify_order_model.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/utils/format_utils.dart';

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
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            _buildOrderHeaderCard(),
            
            SizedBox(height: 16),
            
            // Order Details Card
            _buildOrderDetailsCard(),
            
            SizedBox(height: 16),
            
            // Ordered Items Section
            _buildOrderedItemsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.name,
                style: TextStyle(
                  fontSize: 20.fSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Placed on ${_formatDate(order.createdAt)}',
                style: TextStyle(
                  fontSize: 11.fSize,
                  color: Color(0xFF777777),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(
                color: const Color(0xFFFFE0B2),
                width: 1.w,
              ),
            ),
            child: Text(
              _getStatusText(order),
              style: TextStyle(
                fontSize: 11.fSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF9800),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formatIndianCurrency(order.totalPrice),
                    style: TextStyle(
                      fontSize: 20.fSize,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${order.lineItems.length} items',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Divider(
            color: Color(0xFFE5E5E5).withOpacity(0.5),
            thickness: 1,
            height: 1.h,
          ),
          
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Status',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    order.financialStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Fulfillment',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    order.fulfillmentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
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

  Widget _buildOrderedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordered Items',
          style: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Inter',
          ),
        ),
        
        SizedBox(height: 12),
        
        // Items List
        ...order.lineItems.map((item) => _buildItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildItemCard(ShopifyLineItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Placeholder
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFFCCCCCC),
              size: 24.h,
            ),
          ),
          
          SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Inter',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 8),
                
                // Quantity Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                  child: Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 10.fSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF5C9A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Sold by text
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 12.h,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sold by Glo Cure',
                      style: TextStyle(
                        fontSize: 10.fSize,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12),
          
          // Unit Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Unit Price',
                style: TextStyle(
                  fontSize: 9.fSize,
                  color: Color(0xFF777777),
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 4),
              Text(
                formatIndianCurrency(item.price),
                style: TextStyle(
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(ShopifyOrder order) {
    final financial = order.financialStatus.toLowerCase();
    final fulfillment = order.fulfillmentStatus.toLowerCase();

    if (financial == 'paid' && fulfillment == 'fulfilled') {
      return 'Delivered';
    } else if (financial == 'pending' || fulfillment == 'unfulfilled') {
      return 'Pending';
    } else if (financial == 'refunded' || fulfillment == 'cancelled') {
      return 'Cancelled';
    } else {
      return 'Processing';
    }
  }
}