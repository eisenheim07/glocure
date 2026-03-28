import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/order_details_checkout/order_details_checkout_cubit.dart';
import '../cubits/order_details_checkout/order_details_checkout_state.dart';
import '../models/customer_model.dart';
import '../models/top_products_model.dart';
import '../utils/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/size_utils.dart';
import '../utils/app_logger.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/common_payment_flow.dart';

class OrderDetailsCheckout extends StatefulWidget {
  final Customer customer;
  final TopProduct product;
  final ProductVariant selectedVariant;
  final int quantity;

  const OrderDetailsCheckout({
    super.key,
    required this.customer,
    required this.product,
    required this.selectedVariant,
    this.quantity = 1,
  });

  @override
  State<OrderDetailsCheckout> createState() => _OrderDetailsCheckoutState();
}

class _OrderDetailsCheckoutState extends State<OrderDetailsCheckout> {
  @override
  void initState() {
    super.initState();
    // Initialize the order details
    context.read<OrderDetailsCheckoutCubit>().initializeOrderDetails(
          product: widget.product,
          selectedVariant: widget.selectedVariant,
          customer: widget.customer,
          quantity: widget.quantity,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Order Summary',
      ),
      body: BlocBuilder<OrderDetailsCheckoutCubit, OrderDetailsCheckoutState>(
        builder: (context, state) {
          if (state is OrderDetailsCheckoutLoading) {
            return _buildLoadingShimmer();
          } else if (state is OrderDetailsCheckoutPaymentLoading) {
            return _buildPaymentLoadingShimmer();
          } else if (state is OrderDetailsCheckoutLoaded) {
            return _buildContent(state);
          } else if (state is OrderDetailsCheckoutError) {
            return _buildErrorState(state.message);
          }
          return _buildLoadingShimmer();
        },
      ),
    );
  }

  /// Build main content
  Widget _buildContent(OrderDetailsCheckoutLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipping address card
                  _buildShippingAddressCard(state.customer),
                  SizedBox(height: 12.h),

                  // Contact information card
                  _buildContactInformationCard(state.customer),
                  SizedBox(height: 16.h),

                  // Product details card
                  _buildProductCard(state),
                  SizedBox(height: 16.h),

                  // Price breakdown card
                  _buildPriceBreakdownCard(state),
                ],
              ),
            ),
          ),

          // Bottom checkout button
          _buildBottomCheckoutButton(state),
        ],
      ),
    );
  }

  /// Build product details card
  Widget _buildProductCard(OrderDetailsCheckoutLoaded state) {
    final product = state.product;
    final variant = state.selectedVariant;
    final imageUrl = product.images.isNotEmpty ? product.images.first.originalSrc : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderSecondary,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Product Details',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12.h),

          // Product info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: imageUrl != null
                      ? NetworkImageLoader(
                          imageUrl: imageUrl,
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32.h,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12.w),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product title
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Variant title (if different from default)
                    if (variant.title != 'Default Title')
                      Text(
                        'Variant: ${variant.title}',
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: AppColors.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    SizedBox(height: 8.h),

                    // Price and quantity row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          formatIndianCurrency(variant.priceV2.amount),
                          style: TextStyle(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'Inter',
                          ),
                        ),

                        // Quantity controls
                        _buildQuantityControls(state),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quantity controls
  Widget _buildQuantityControls(OrderDetailsCheckoutLoaded state) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          GestureDetector(
            onTap: state.quantity > 1 ? () => context.read<OrderDetailsCheckoutCubit>().updateQuantity(state.quantity - 1) : null,
            child: Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: state.quantity > 1 ? AppColors.backgroundSecondary : AppColors.gray200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6.r),
                  bottomLeft: Radius.circular(6.r),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 16.h,
                color: state.quantity > 1 ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
          ),

          // Quantity display
          Container(
            width: 40.w,
            height: 32.h,
            decoration: const BoxDecoration(
              color: AppColors.white,
            ),
            child: Center(
              child: Text(
                '${state.quantity}',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          // Increase button
          GestureDetector(
            onTap: () => context.read<OrderDetailsCheckoutCubit>().updateQuantity(state.quantity + 1),
            child: Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(6.r),
                  bottomRight: Radius.circular(6.r),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 16.h,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build price breakdown card
  Widget _buildPriceBreakdownCard(OrderDetailsCheckoutLoaded state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderSecondary,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Price Details',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12.h),

          // Item price
          _buildPriceRow(
            'Item Total (${state.quantity} ${state.quantity == 1 ? 'item' : 'items'})',
            formatIndianCurrency(state.itemPrice.toString()),
          ),
          SizedBox(height: 8.h),

          // Shipping charges
          _buildPriceRow(
            'Shipping Charges',
            state.needsShipping ? formatIndianCurrency(state.shippingCharges.toString()) : 'FREE',
            isShipping: true,
            isFree: !state.needsShipping,
          ),
          SizedBox(height: 12.h),

          // Divider
          Divider(
            color: AppColors.borderSecondary,
            thickness: 1.w,
          ),
          SizedBox(height: 12.h),

          // Total amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                formatIndianCurrency(state.totalPrice.toString()),
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          // Free shipping message
          if (!state.needsShipping) ...[
            SizedBox(height: 8.h),
            Text(
              'You saved ₹99 on shipping!',
              style: TextStyle(
                fontSize: 12.fSize,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Text(
              'Add ₹${(1000 - state.itemPrice).toStringAsFixed(0)} more for FREE shipping',
              style: TextStyle(
                fontSize: 12.fSize,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build price row
  Widget _buildPriceRow(String label, String value, {bool isShipping = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.fSize,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            color: isFree ? AppColors.success : AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  /// Build bottom checkout button
  Widget _buildBottomCheckoutButton(OrderDetailsCheckoutLoaded state) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 40.h,
          child: ElevatedButton(
            onPressed: () => _handleCheckout(state),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle checkout button press
  void _handleCheckout(OrderDetailsCheckoutLoaded state) {
    AppLogger.info('Starting checkout process for single product');

    // Start the common payment flow
    CommonPaymentFlow.startPaymentFlow(
      context: context,
      customer: state.customer,
      product: state.product,
      selectedVariant: state.selectedVariant,
      quantity: state.quantity,
      onLoadingStart: () {
        context.read<OrderDetailsCheckoutCubit>().setPaymentLoading(true);
      },
      onLoadingEnd: () {
        if (mounted) {
          context.read<OrderDetailsCheckoutCubit>().setPaymentLoading(false);
        }
      },
      onSuccess: () {
        AppLogger.success('Order checkout completed successfully');
      },
      onError: () {
        AppLogger.error('Order checkout failed');
      },
    );
  }

  /// Build shipping address card
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
              // IconButton(
              //   icon: Icon(
              //     Icons.edit_outlined,
              //     color: AppColors.primary,
              //     size: 16.h,
              //   ),
              //   onPressed: () async {
              //     // Navigate to address list screen
              //     final updatedCustomer = await Navigator.push<Customer>(
              //       context,
              //       MaterialPageRoute(
              //         builder: (_) => AddressListScreen(
              //           customer: customer,
              //           returnSelectedAddress: true,
              //         ),
              //       ),
              //     );
              //
              //     // Always refresh when returning from address screen
              //     if (mounted) {
              //       // Show shimmer during refresh
              //       setState(() {
              //         _isRefreshingAddress = true;
              //         _hasCheckedAddress = false;
              //         _buttonTextReady = false;
              //       });
              //
              //       // Update customer state if we got updated customer data
              //       if (updatedCustomer != null) {
              //         setState(() {
              //           _customer = updatedCustomer;
              //         });
              //         // Update the customer cubit as well
              //         context.read<CustomerCubit>().updateCustomer(updatedCustomer);
              //       } else {
              //         // Even if no customer returned, refresh customer data from API
              //         context.read<CustomerCubit>().refreshCustomer();
              //       }
              //
              //       // Re-check customer address to update button text and card visibility
              //       await _checkCustomerAddress();
              //
              //       // Hide shimmer after refresh
              //       setState(() {
              //         _isRefreshingAddress = false;
              //       });
              //     }
              //   },
              //   padding: EdgeInsets.zero,
              // ),
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

  /// Build contact information card
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

  /// Build empty card for missing information
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
          const SizedBox(height: 12),
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

  /// Build loading shimmer
  Widget _buildLoadingShimmer() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Product card shimmer
              Container(
                width: double.infinity,
                height: 120.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Address card shimmer
              Container(
                width: double.infinity,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 12.h),

              // Contact card shimmer
              Container(
                width: double.infinity,
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Price card shimmer
              Container(
                width: double.infinity,
                height: 150.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              const Spacer(),

              // Button shimmer
              Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build payment loading shimmer
  Widget _buildPaymentLoadingShimmer() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          children: [
            // Scrollable content shimmer
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping address card shimmer
                    Container(
                      width: double.infinity,
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Contact information card shimmer
                    Container(
                      width: double.infinity,
                      height: 70.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Product details card shimmer
                    Container(
                      width: double.infinity,
                      height: 140.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Price breakdown card shimmer
                    Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom checkout button shimmer
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.h,
                color: AppColors.error,
              ),
              SizedBox(height: 16.h),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14.fSize,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
