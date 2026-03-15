import 'package:flutter/material.dart';
import '../utils/size_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/screens/product_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../models/cart_model.dart';
import '../models/top_products_model.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import '../utils/format_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/payment_selection_bottom_sheet.dart';
import '../widgets/common_bottom_sheet.dart';
import '../cubits/cart/cart_cubit.dart';
import '../cubits/cart/cart_state.dart';
import '../cubits/customer/customer_cubit.dart';
import '../cubits/customer/customer_state.dart';
import '../cubits/order_summary/order_summary_cubit.dart';
import '../cubits/order_summary/order_summary_state.dart';
import '../screens/payu_payment_screen.dart';
import '../screens/payment_status_screen.dart';
import '../models/order_model.dart';
import 'address_list_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final Customer? customer;

  const OrderSummaryScreen({
    super.key,
    this.customer,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the OrderSummaryCubit
    context.read<OrderSummaryCubit>().initialize();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      // Fetch cart data
      context.read<CartCubit>().fetchCart();

      // If customer object is passed, use it
      if (widget.customer != null) {
        context.read<CustomerCubit>().updateCustomer(widget.customer!);
      } else {
        // Fetch customer data
        await context.read<CustomerCubit>().fetchCustomer();
      }
    } catch (e) {
      debugPrint('Error initializing screen: $e');
    }
  }

  Future<void> _handleRefresh() async {
    final orderSummaryCubit = context.read<OrderSummaryCubit>();
    orderSummaryCubit.startRefresh();

    try {
      // Refresh cart data
      await context.read<CartCubit>().refreshCart();

      // Refresh customer data
      await context.read<CustomerCubit>().refreshCustomer();

      // Refresh related products if cart has items
      final cartState = context.read<CartCubit>().state;
      if (cartState is CartSuccess && cartState.cart.lines.isNotEmpty) {
        final firstProduct = cartState.cart.lines.first.merchandise?.product;
        if (firstProduct != null) {
          await orderSummaryCubit.fetchRelatedProducts(firstProduct.id);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing order summary: $e');
    } finally {
      orderSummaryCubit.endRefresh();
    }
  }

  void _handleProceedToPay(BuildContext context, Cart cart, Customer customer) {
    // Validate customer and address
    final defaultAddress = customer.defaultAddress;
    if (defaultAddress == null || defaultAddress.zip == null || defaultAddress.zip!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address with pincode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate cart
    if (cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment selection bottom sheet
    PaymentSelectionBottomSheet.show(
      context,
      pincode: defaultAddress.zip!,
      cart: cart,
      customer: customer,
      onPaymentSelected: (paymentMethod) async {
        debugPrint('Payment method selected: $paymentMethod');
        // Show loading state
        context.read<OrderSummaryCubit>().initialize(); // This will show loading

        try {
          // Create order
          debugPrint('📦 Creating $paymentMethod order...');
          final order = await OrderService().createOrder(
            cart: cart,
            customer: customer,
            paymentMethod: paymentMethod,
          );

          debugPrint('✅ Order created: ${order.id}');

          // Handle based on payment method
          if (paymentMethod == 'Pre-paid') {
            // Navigate to PayU
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PayUPaymentScreen(
                    order: order,
                    customer: customer,
                  ),
                ),
              );

              _handlePaymentResult(result, order);
            }
          } else {
            // COD success - navigate to payment status screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentStatusScreen(
                    status: 'success',
                    order: order,
                  ),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Order creation error: $e');
          if (mounted) {
            // Reset to loaded state
            context.read<OrderSummaryCubit>().reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create order: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
    );
  }

  void _handlePaymentResult(dynamic result, OrderModel order) async {
    if (result == null || !mounted) return;

    final status = result['status']?.toString().toLowerCase() ?? 'cancelled';

    // Show loading
    context.read<OrderSummaryCubit>().initialize();

    if (status == 'success') {
      // Payment successful - update order status
      debugPrint('✅ Payment successful!');

      OrderService()
          .updateOrderStatus(
        orderId: order.id!,
        financialStatus: 'paid',
      )
          .then((_) {
        debugPrint('✅ Order status updated to paid');
      }).catchError((e) {
        debugPrint('⚠️ Failed to update order status: $e');
      });
    }

    // Wait for 2 seconds with shimmer showing
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to payment status screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusScreen(
            status: status,
            order: order,
          ),
        ),
      );
    }
  }

  void _showGrandTotalInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (BuildContext context) {
        return Container(
            width: double.infinity,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    width: 32.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderPrimary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  // Icon and Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Container(
                        //   width: 36.w,
                        //   height: 36.h,
                        //   decoration: BoxDecoration(
                        //     color: AppColors.primary.withValues(alpha: 0.1),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: Icon(
                        //     Icons.info_outline,
                        //     size: 20.h,
                        //     color: AppColors.primary,
                        //   ),
                        // ),
                        // SizedBox(width: 12.w),
                        Text(
                          'Grand Total Breakdown',
                          style: TextStyle(
                            fontSize: 17.fSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Content
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item price
                        _buildInfoRow(
                          '• Item Price',
                          'Cost of all products in your cart',
                        ),

                        SizedBox(height: 12.h),

                        // Delivery charges
                        _buildInfoRow(
                          '• Delivery Charges',
                          '₹99 for orders below ₹1000\nFREE for orders ₹1000 & above',
                        ),

                        SizedBox(height: 16.h),

                        // Highlight box
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 16.h,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Enjoy FREE delivery on orders ₹1000+',
                                  style: TextStyle(
                                    fontSize: 12.fSize,
                                    color: AppColors.success,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Close button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: SizedBox(
                      width: double.infinity,
                      height: 40.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // SizedBox(height: 16.h),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildInfoRow(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.fSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.fSize,
            color: AppColors.textMuted,
            fontFamily: 'Inter',
            height: 1.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Order Summary',
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, customerState) {
          return BlocBuilder<OrderSummaryCubit, OrderSummaryState>(
            builder: (context, orderSummaryState) {
              // Show loading if any state is loading
              if (orderSummaryState is OrderSummaryLoading ||
                  customerState is CustomerLoading ||
                  (orderSummaryState is OrderSummaryLoaded && orderSummaryState.isRefreshing)) {
                return _buildLoadingShimmer();
              }

              if (customerState is CustomerError) {
                return _buildErrorState();
              }

              if (customerState is! CustomerSuccess) {
                return _buildLoadingShimmer();
              }

              final customer = customerState.customer;

              return BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  return Column(
                    children: [
                      // Scrollable content
                      Expanded(
                        child: _buildContent(customer, orderSummaryState),
                      ),

                      // Fixed bottom section with total and button
                      if (cartState is CartSuccess) _buildBottomSection(cartState.cart, customer),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(Customer customer, OrderSummaryState orderSummaryState) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        // Fetch related products when cart is loaded
        if (cartState is CartSuccess &&
            orderSummaryState is OrderSummaryLoaded &&
            !orderSummaryState.isLoadingRelatedProducts &&
            orderSummaryState.relatedProducts.isEmpty &&
            cartState.cart.lines.isNotEmpty) {
          // Get first product ID from cart
          final firstProduct = cartState.cart.lines.first.merchandise?.product;
          if (firstProduct != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<OrderSummaryCubit>().fetchRelatedProducts(firstProduct.id);
            });
          }
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFFFF5C9A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipping Address Card
                _buildShippingAddressCard(customer),

                SizedBox(height: 16),

                // Contact Information Card
                _buildContactInformationCard(customer),

                SizedBox(height: 16),

                // Cart Products Card
                if (cartState is CartSuccess) _buildCartProductsCard(cartState.cart, orderSummaryState),

                if (cartState is CartLoading) _buildCartProductsShimmer(),

                SizedBox(height: 16),

                // Related Products Section
                if (orderSummaryState is OrderSummaryLoaded) ...[
                  if (orderSummaryState.isLoadingRelatedProducts)
                    _buildRelatedProductsShimmer()
                  else if (orderSummaryState.relatedProducts.isNotEmpty)
                    _buildRelatedProductsSection(orderSummaryState.relatedProducts),
                ],

                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(Cart cart, Customer customer) {
    final totalAmount = cart.cost?.totalAmount.amount ?? '0';
    final subtotal = double.tryParse(totalAmount) ?? 0;

    // Add shipping charges if subtotal is less than 1000
    const shippingCharges = 99.0;
    final needsShipping = subtotal < 1000;
    final finalTotal = needsShipping ? subtotal + shippingCharges : subtotal;

    final formattedSubtotal = formatIndianCurrency(totalAmount);
    final formattedShipping = formatIndianCurrency(shippingCharges.toString());
    final formattedTotal = formatIndianCurrency(finalTotal.toString());

    return Container(
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
      padding: EdgeInsets.fromLTRB(8.h, 8.h, 8.h, 2.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown card
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Subtotal row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 13.fSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        formattedSubtotal,
                        style: TextStyle(
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Shipping charges row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Shipping Charges',
                            style: TextStyle(
                              fontSize: 13.fSize,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 4.w),
                          GestureDetector(
                            onTap: () => _showGrandTotalInfoBottomSheet(context),
                            child: Icon(
                              Icons.info_outline,
                              size: 14.h,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        needsShipping ? formattedShipping : 'FREE',
                        style: TextStyle(
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w600,
                          color: needsShipping ? AppColors.textPrimary : AppColors.success,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Divider
                  Divider(
                    color: AppColors.borderSecondary,
                    thickness: 1,
                  ),

                  SizedBox(height: 4.h),

                  // Grand Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        formattedTotal,
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // Proceed to Pay button
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: () => _handleProceedToPay(context, cart, customer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Pay',
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, size: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddressCard(Customer customer) {
    final defaultAddr = customer.defaultAddress;

    if (defaultAddr == null) {
      return _buildEmptyCard('Shipping Address', 'No address available');
    }

    // Build full address string
    final addressParts = <String>[];
    if (defaultAddr.address1 != null && defaultAddr.address1!.isNotEmpty) {
      addressParts.add(defaultAddr.address1!);
    }
    if (defaultAddr.address2 != null && defaultAddr.address2!.isNotEmpty) {
      addressParts.add(defaultAddr.address2!);
    }
    if (defaultAddr.city != null && defaultAddr.city!.isNotEmpty) {
      addressParts.add(defaultAddr.city!);
    }
    if (defaultAddr.province != null && defaultAddr.province!.isNotEmpty) {
      addressParts.add(defaultAddr.province!);
    }
    if (defaultAddr.zip != null && defaultAddr.zip!.isNotEmpty) {
      addressParts.add(defaultAddr.zip!);
    }

    final fullAddress = addressParts.join(', ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
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
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              // Edit button
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 17.h,
                ),
                onPressed: () async {
                  // Navigate to address list screen
                  final updatedCustomer = await Navigator.push<Customer>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddressListScreen(
                        customer: customer,
                        returnSelectedAddress: true,
                      ),
                    ),
                  );

                  // If customer was updated, refresh the cubit
                  if (updatedCustomer != null && mounted) {
                    context.read<CustomerCubit>().updateCustomer(updatedCustomer);
                  }
                },
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          Text(
            fullAddress.isNotEmpty ? fullAddress : 'Address not available',
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformationCard(Customer customer) {
    final firstName = customer.firstName ?? '';
    final lastName = customer.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = customer.email ?? '';
    final phone = customer.defaultAddress?.phone ?? customer.phone ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
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
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              // Edit button for contact info
              // Container(
              //   width: 34.w,
              //   height: 34.h,
              //   decoration: BoxDecoration(
              //     color: Color(0xFFFF5C9A),
              //     shape: BoxShape.circle,
              //   ),
              //   child: IconButton(
              //     icon: Icon(
              //       Icons.edit_outlined,
              //       color: Colors.white,
              //       size: 17.h,
              //     ),
              //     onPressed: () {
              //       // TODO: Navigate to edit contact screen
              //       debugPrint('Edit contact tapped');
              //     },
              //     padding: EdgeInsets.zero,
              //   ),
              // ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            Text(
              phone,
              style: TextStyle(
                fontSize: 12.fSize,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                fontSize: 12.fSize,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String message) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartProductsCard(Cart cart, OrderSummaryState orderSummaryState) {
    final totalItems = cart.lines.length;
    final showAllProducts = orderSummaryState is OrderSummaryLoaded ? orderSummaryState.showAllProducts : false;
    final displayedItems = showAllProducts ? cart.lines : cart.lines.take(2).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          childrenPadding: EdgeInsets.only(bottom: 14.h),
          title: Text(
            'Products (${cart.lines.length})',
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          children: [
            // Display products
            ...displayedItems.map((cartLine) => _buildProductItem(cartLine)),

            // View More/Less button
            if (totalItems > 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                child: TextButton(
                  onPressed: () {
                    context.read<OrderSummaryCubit>().toggleShowAllProducts();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5C9A),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        showAllProducts ? 'View Less' : 'View More',
                        style: TextStyle(
                          fontSize: 12.fSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        showAllProducts ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 17.h,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(CartLine cartLine) {
    final merchandise = cartLine.merchandise;
    if (merchandise == null) return const SizedBox.shrink();

    final product = merchandise.product;
    final currentPrice = formatIndianCurrency(merchandise.priceV2.amount);
    final originalPrice = merchandise.compareAtPriceV2 != null ? formatIndianCurrency(merchandise.compareAtPriceV2!.amount) : '';
    final discount = _discountPercent(cartLine);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(5.r),
            child: Container(
              width: 68.w,
              height: 68.h,
              color: Colors.grey.shade50,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? NetworkImageLoader(
                      imageUrl: product.imageUrl!,
                      width: 68.w,
                      height: 68.h,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
            ),
          ),

          SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product title
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 6),

                // Quantity
                Text(
                  'Qty: ${cartLine.quantity}',
                  style: TextStyle(
                    fontSize: 11.fSize,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: 6),

                // Price row
                Row(
                  children: [
                    Text(
                      currentPrice,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (originalPrice.isNotEmpty) ...[
                      SizedBox(width: 6),
                      Text(
                        originalPrice,
                        style: TextStyle(
                          fontSize: 10.fSize,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    if (discount > 0) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                        child: Text(
                          '-$discount%',
                          style: TextStyle(
                            fontSize: 9.fSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _discountPercent(CartLine cartLine) {
    final merchandise = cartLine.merchandise;
    if (merchandise == null || merchandise.compareAtPriceV2 == null) return 0;

    final compareAt = double.tryParse(merchandise.compareAtPriceV2!.amount) ?? 0;
    final price = double.tryParse(merchandise.priceV2.amount) ?? 0;

    if (compareAt <= 0 || price >= compareAt) return 0;
    return ((compareAt - price) / compareAt * 100).round();
  }

  Widget _buildCartProductsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 213.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  Widget _buildRelatedProductsSection(List<Map<String, dynamic>> relatedProducts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Last Minute Addition',
          style: TextStyle(
            fontSize: 17.fSize,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        SizedBox(height: 16),

        // Horizontal scrollable product list
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: relatedProducts.map((product) {
              return _buildRelatedProductCard(product);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(Map<String, dynamic> product) {
    final title = product['title'] ?? '';
    final productId = product['id']?.toString() ?? '';
    final price = product['price'] ?? 0;
    final compareAtPrice = product['compare_at_price'];

    // Get image URL - try multiple possible fields
    String imageUrl = '';
    if (product['featured_image'] != null && product['featured_image'].toString().isNotEmpty) {
      imageUrl = product['featured_image'].toString();
    } else if (product['image'] != null && product['image'].toString().isNotEmpty) {
      imageUrl = product['image'].toString();
    } else if (product['images'] != null && product['images'] is List && (product['images'] as List).isNotEmpty) {
      imageUrl = (product['images'] as List).first.toString();
    }

    // Ensure image URL is absolute
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'https:$imageUrl';
    }

    debugPrint('Product: $title, Image URL: $imageUrl');

    // Format prices
    final currentPrice = formatIndianCurrency((price / 100).toString());
    final originalPrice = compareAtPrice != null ? formatIndianCurrency((compareAtPrice / 100).toString()) : '';

    // Calculate discount
    int discountPercent = 0;
    if (compareAtPrice != null && compareAtPrice > price) {
      discountPercent = ((compareAtPrice - price) / compareAtPrice * 100).round();
    }

    return GestureDetector(
      onTap: () async {
        // Navigate to product details using productId
        debugPrint('Product tapped: $productId');
        debugPrint('Product tapped: $product');

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: productId),
          ),
        );

        // Refresh cart data when returning from product details
        // This ensures newly added items are visible in the cart
        if (mounted) {
          await _handleRefresh();
        }
      },
      child: Container(
        width: 136.w,
        margin: EdgeInsets.only(right: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with discount badge
            Stack(
              children: [
                Container(
                  height: 136.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: imageUrl.isNotEmpty
                        ? NetworkImageLoader(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 136.h,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 34.h,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),

                // Discount badge
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: TextStyle(
                          fontSize: 10.fSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Divider between image and text
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),

            // Product details
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Price row
                  Row(
                    children: [
                      Text(
                        currentPrice,
                        style: TextStyle(
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 10.fSize,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 128.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Product cards shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              return Container(
                width: 136.w,
                margin: EdgeInsets.only(right: 10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image shimmer
                      Container(
                        height: 136.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),

                      // Content shimmer
                      Padding(
                        padding: EdgeInsets.all(10.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              width: 85.w,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: 68.w,
                              height: 15.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 68.h,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load customer data',
              style: TextStyle(
                fontSize: 15.fSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _initializeScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.r),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        // Scrollable shimmer content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                // Shipping Address Card Shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 102.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Contact Information Card Shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 102.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Cart Products Card Shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 213.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Related Products Shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 213.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom section shimmer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price breakdown card
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Subtotal row shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 70.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            Container(
                              width: 120.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Shipping charges row shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 110.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            Container(
                              width: 50.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Divider
                      Divider(
                        color: AppColors.borderSecondary,
                        thickness: 1,
                      ),

                      SizedBox(height: 4.h),

                      // Grand Total row shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 80.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            Container(
                              width: 90.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
