import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../models/top_products_model.dart';
import '../models/customer_model.dart';
import '../utils/format_utils.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../utils/auth_storage.dart';
import '../utils/app_logger.dart';
import '../services/api_service.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/common_payment_flow.dart';
import '../cubits/top_products/top_products_cubit.dart';
import '../cubits/top_products/top_products_state.dart';
import '../cubits/product_details/product_details_cubit.dart';
import '../cubits/product_details/product_details_state.dart';
import '../cubits/customer/customer_cubit.dart';
import '../cubits/customer/customer_state.dart';
import '../cubits/reviews/reviews_cubit.dart';
import '../models/judgeme_reviews_model.dart';
import '../models/judgeme_product_model.dart';
import '../widgets/product_rating_widget.dart';
import '../screens/reviews_screen.dart';
import 'category_products.dart';
import 'address_screen.dart';
import 'address_list_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final TopProduct? product;
  final String? productId;
  final String? handle;

  const ProductDetailsScreen({
    super.key,
    this.product,
    this.productId,
    this.handle,
  }) : assert(product != null || productId != null, 'Either product or productId must be provided');

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with TickerProviderStateMixin {
  late String discoverHandle;
  final PageController _pageController = PageController();

  // Address checking variables
  bool _hasCompleteAddress = false;
  bool _hasCheckedAddress = false;
  bool _buttonTextReady = false;
  bool _isRefreshingAddress = false; // New flag for refresh shimmer
  bool _isPaymentLoading = false; // New flag for payment loading shimmer
  Customer? _customer;

  // Animation controller for heart icon
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  // Animation controller for cart icon
  late AnimationController _cartAnimationController;
  late Animation<double> _cartScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize product details via Cubit
    context.read<ProductDetailsCubit>().initializeProduct(
          product: widget.product,
          productId: widget.productId,
          handle: widget.handle,
        );

    // Initialize reviews if we have a product ID
    final productId = widget.product?.id ?? widget.productId;
    if (productId != null) {
      // Extract numeric ID from Shopify GID
      final numericId = productId.contains('/') ? productId.split('/').last : productId;
      context.read<ReviewsCubit>().fetchReviews(numericId);
    }

    // Initialize heart animation
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartAnimationController);

    // Initialize cart animation
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_cartAnimationController);

    // Fetch discover products using handle (default to "top-products" if null)
    discoverHandle = widget.handle ?? 'top-products';
    AppLogger.navigation('ProductDetailsScreen', 'Handle received: $discoverHandle');
    context.read<TopProductsCubit>().fetchProductsForHandle(discoverHandle);

    // Check customer address for button text
    _checkCustomerAddress();
  }

  /// Toggle wishlist status
  Future<void> _toggleWishlist() async {
    // Trigger animation
    _heartAnimationController.forward(from: 0.0);

    // Use Cubit to handle wishlist toggle
    await context.read<ProductDetailsCubit>().toggleWishlist(widget.handle);

    // Show appropriate snackbar based on current state
    final currentState = context.read<ProductDetailsCubit>().state;
    if (currentState is ProductDetailsLoaded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentState.isInWishlist ? 'Added to wishlist' : 'Removed from wishlist'),
          backgroundColor: currentState.isInWishlist ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Check customer address and set button text accordingly
  Future<void> _checkCustomerAddress() async {
    if (_hasCheckedAddress) return; // Prevent multiple calls
    _hasCheckedAddress = true;

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true;
        });
        return;
      }

      // Fetch customer to get default address
      final customer = await ApiService().getCustomer(token);
      _customer = customer;

      if (customer == null) {
        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true;
        });
        return;
      }

      // Use the model's validation method
      final hasCompleteAddress = customer.hasCompleteAddress();

      if (!hasCompleteAddress) {
        // If defaultAddress exists but is incomplete, delete it
        final defaultAddr = customer.defaultAddress;
        if (defaultAddr != null && defaultAddr.id != null) {
          try {
            await ApiService().customerAddressDelete(
              customerAccessToken: token,
              addressId: defaultAddr.id!,
            );
            AppLogger.info('Default address deleted successfully');
          } catch (e) {
            AppLogger.error('Error deleting default address: $e');
          }
        }

        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true;
        });
      } else {
        AppLogger.info('Address is complete, no deletion needed');
        setState(() {
          _hasCompleteAddress = true;
          _buttonTextReady = true;
        });
      }
    } catch (e) {
      AppLogger.error('Error in address check flow: $e');
      setState(() {
        _hasCompleteAddress = false;
        _buttonTextReady = true;
      });
    }
  }

  /// Handle Buy Now button press
  void _handleBuyNow() {
    if (_hasCompleteAddress && _customer != null) {
      final currentState = context.read<ProductDetailsCubit>().state;
      if (currentState is! ProductDetailsLoaded) return;

      final selectedVariant = _getSelectedVariant(currentState);

      // Start the common payment flow
      CommonPaymentFlow.startPaymentFlow(
        context: context,
        customer: _customer!,
        product: currentState.product,
        selectedVariant: selectedVariant,
        quantity: 1,
        onLoadingStart: () {
          if (mounted) {
            setState(() {
              _isPaymentLoading = true;
            });
          }
        },
        onLoadingEnd: () {
          if (mounted) {
            setState(() {
              _isPaymentLoading = false;
            });
          }
        },
        onSuccess: () {
          // Payment successful - could refresh data or show success message
          AppLogger.success('Buy Now payment completed successfully');
        },
        onError: () {
          // Payment failed - could show error message or retry option
          AppLogger.error('Buy Now payment failed');
        },
      );
    } else {
      // Navigate to address screen with source parameter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddressScreen(
            customer: _customer,
            sourceScreen: 'product_details', // Indicate source screen
          ),
        ),
      ).then((result) async {
        // Handle returned data from address screen
        if (mounted) {
          // Show shimmer during refresh
          setState(() {
            _isRefreshingAddress = true;
            _hasCheckedAddress = false;
            _buttonTextReady = false;
          });

          // If we got updated customer data, use it
          if (result is Customer) {
            setState(() {
              _customer = result;
            });
            // Update the customer cubit as well
            context.read<CustomerCubit>().updateCustomer(result);
          } else {
            // Refresh customer data from API
            context.read<CustomerCubit>().refreshCustomer();
          }

          // Re-check customer address to update button text and card visibility
          await _checkCustomerAddress();

          // Hide shimmer after refresh
          setState(() {
            _isRefreshingAddress = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  /// Show non-cancelable error bottom sheet when product data cannot be loaded
  /// Only used when no fallback product object is available (Case 2)
  void _showErrorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PopScope(
        canPop: false,
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error title
                  const Text(
                    'Unable to Load Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Error message
                  const Text(
                    'There might some error while fetching the product details, Our team is working on it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Okay button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close bottom sheet
                        Navigator.of(context).pop(); // Go back to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Okay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get selected variant from current state
  ProductVariant _getSelectedVariant(ProductDetailsLoaded state) {
    return state.product.variants.isNotEmpty
        ? state.product.variants[state.selectedVariantIndex]
        : ProductVariant(
            id: '',
            title: '',
            sku: null,
            priceV2: Money(amount: '0', currencyCode: 'INR'),
            compareAtPriceV2: null,
            availableForSale: false,
          );
  }

  /// Calculate discount percentage for a variant
  int _calculateDiscountPercent(ProductVariant variant) {
    if (variant.compareAtPriceV2 == null) return 0;
    final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
    final price = double.tryParse(variant.priceV2.amount) ?? 0;
    if (compareAt <= 0) return 0;
    return ((compareAt - price) / compareAt * 100).round();
  }

  /// Strip basic HTML tags from description
  String _cleanDescription(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Add product to cart
  Future<void> _addToCart() async {
    final currentState = context.read<ProductDetailsCubit>().state;
    if (currentState is! ProductDetailsLoaded) return;

    // Trigger cart animation
    _cartAnimationController.forward(from: 0.0);

    try {
      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();

      if (cartId == null || cartId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cart not initialized. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Get the selected variant
      if (currentState.product.variants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product variant not available'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final selectedVariant = _getSelectedVariant(currentState);
      final variantId = selectedVariant.id;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Adding to cart...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call API to add to cart
      await ApiService().cartLinesAdd(
        cartId: cartId,
        merchandiseId: variantId,
        quantity: 1,
      );

      // Hide loading and show success
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Format message: truncate title if needed and always end with "...added to cart"
        final maxTitleLength = 40; // Approximate character limit for 2 lines
        String message;

        if (currentState.product.title.length > maxTitleLength) {
          // Truncate and add ellipsis before "added to cart"
          final truncatedTitle = currentState.product.title.substring(0, maxTitleLength).trim();
          message = '$truncatedTitle...added to cart';
        } else {
          message = '${currentState.product.title} added to cart';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Hide loading and show error
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      AppLogger.error('Add to cart error: $e');
    }
  }

  /// Show shipping charges info dialog
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
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 16.h,
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

                  // Always refresh when returning from address screen
                  if (mounted) {
                    // Show shimmer during refresh
                    setState(() {
                      _isRefreshingAddress = true;
                      _hasCheckedAddress = false;
                      _buttonTextReady = false;
                    });

                    // Update customer state if we got updated customer data
                    if (updatedCustomer != null) {
                      setState(() {
                        _customer = updatedCustomer;
                      });
                      // Update the customer cubit as well
                      context.read<CustomerCubit>().updateCustomer(updatedCustomer);
                    } else {
                      // Even if no customer returned, refresh customer data from API
                      context.read<CustomerCubit>().refreshCustomer();
                    }

                    // Re-check customer address to update button text and card visibility
                    await _checkCustomerAddress();

                    // Hide shimmer after refresh
                    setState(() {
                      _isRefreshingAddress = false;
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Product detail',
      ),
      body: SafeArea(
        child: BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
          listener: (context, state) {
            // Handle error state by showing error bottom sheet
            if (state is ProductDetailsError && !state.hasProductFallback) {
              _showErrorBottomSheet();
            }
          },
          builder: (context, state) {
            // Show shimmer when refreshing address, loading product details, or processing payment
            if (state is ProductDetailsLoading || _isRefreshingAddress || _isPaymentLoading) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(child: _buildLoadingShimmer()),
                  _buildBottomBarShimmer(),
                ],
              );
            }

            if (state is ProductDetailsLoaded) {
              return _buildProductContent(state);
            }

            // Error state with fallback or initial state
            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(child: _buildLoadingShimmer()),
                _buildBottomBarShimmer(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build the main product content when data is loaded
  Widget _buildProductContent(ProductDetailsLoaded state) {
    final selectedVariant = _getSelectedVariant(state);
    final currentPrice = formatIndianCurrency(selectedVariant.priceV2.amount);
    final originalPrice = selectedVariant.compareAtPriceV2 != null ? formatIndianCurrency(selectedVariant.compareAtPriceV2!.amount) : '';
    final discount = _calculateDiscountPercent(selectedVariant);
    final description = _cleanDescription(state.product.description);

    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                _buildImageCarousel(state),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Product title
                      Text(
                        state.product.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Pricing row
                      _buildPricingRow(currentPrice, originalPrice, discount),

                      // Product rating (below price)
                      BlocBuilder<ReviewsCubit, ReviewsState>(
                        builder: (context, reviewsState) {
                          if (reviewsState is ReviewsLoaded && reviewsState.product != null) {
                            final productId = state.product.id;
                            final numericId = productId.contains('/') ? productId.split('/').last : productId;
                            return ProductRatingWidget(
                              product: reviewsState.product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewsScreen(
                                      productId: numericId,
                                      productName: state.product.title,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Variant selector
                      if (state.product.variants.length > 1) _buildVariantSelector(state),

                      // Product Specifications
                      _buildSpecificationsSection(state),

                      // Description
                      if (description.isNotEmpty) _buildDescription(description),

                      const SizedBox(height: 20),

                      // Product Reviews Section
                      _buildReviewsSection(state),
                    ],
                  ),
                ),

                // Address Cards (if customer has complete address)
                if (_hasCompleteAddress && _customer != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      children: [
                        _buildShippingAddressCard(_customer!),
                        const SizedBox(height: 4),
                        _buildContactInformationCard(_customer!),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],

                // Discover Products Section
                _buildDiscoverSection(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom "Add to Cart" button
        _buildBottomBar(state, selectedVariant),
      ],
    );
  }

  /// Image carousel shimmer
  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 300.h,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Image carousel with dot indicators and share icon
  Widget _buildImageCarousel(ProductDetailsLoaded state) {
    final images = state.product.images;

    if (images.isEmpty) {
      return Container(
        height: 300.h,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSecondary, width: 0.8),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 300.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                context.read<ProductDetailsCubit>().updateImageIndex(index);
              },
              itemBuilder: (context, index) {
                return NetworkImageLoader(
                  imageUrl: images[index].originalSrc,
                  width: double.infinity,
                  height: 300.h,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),

          // Share icon (top right)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                final url = state.product.onlineStoreUrl ?? 'https://glocure.com/products/${state.product.handle}';
                Clipboard.setData(ClipboardData(text: '${state.product.title}\n$url'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.share_outlined, size: 18, color: AppColors.textTertiary),
              ),
            ),
          ),

          // Dot indicators (bottom center)
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == state.currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 10 : 7,
                    height: isActive ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// Pricing row: current price + strikethrough original + discount badge
  Widget _buildPricingRow(String currentPrice, String originalPrice, int discount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          currentPrice,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (originalPrice.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            originalPrice,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textMuted,
            ),
          ),
        ],
        if (discount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$discount% off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Variant selector with horizontal chips
  Widget _buildVariantSelector(ProductDetailsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Size',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(state.product.variants.length, (index) {
            final variant = state.product.variants[index];
            final isSelected = index == state.selectedVariantIndex;

            return GestureDetector(
              onTap: () {
                context.read<ProductDetailsCubit>().updateVariantIndex(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderPrimary,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  variant.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Product Specifications Section
  Widget _buildSpecificationsSection(ProductDetailsLoaded state) {
    if (state.specifications == null) {
      return const SizedBox.shrink();
    }

    final options = state.specifications!['options'] as List<dynamic>? ?? [];
    final variants = state.specifications!['variants'] as List<dynamic>? ?? [];

    if (options.isEmpty && variants.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current variant specs
    final currentVariantSpec =
        variants.isNotEmpty && state.selectedVariantIndex < variants.length ? variants[state.selectedVariantIndex] as Map<String, dynamic> : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Weight
              if (currentVariantSpec != null && currentVariantSpec['weight'] != null)
                _buildSpecRow(
                  'Weight',
                  '${currentVariantSpec['weight']} ${currentVariantSpec['weight_unit'] ?? 'g'}',
                ),

              // Inventory/Stock
              if (currentVariantSpec != null && currentVariantSpec['inventory_quantity'] != null)
                _buildSpecRow(
                  'Available Quantity',
                  '${currentVariantSpec['inventory_quantity']} units',
                ),

              // SKU
              if (currentVariantSpec != null && currentVariantSpec['sku'] != null && currentVariantSpec['sku'].toString().isNotEmpty)
                _buildSpecRow(
                  'SKU',
                  currentVariantSpec['sku'].toString(),
                ),

              // Barcode
              if (currentVariantSpec != null && currentVariantSpec['barcode'] != null && currentVariantSpec['barcode'].toString().isNotEmpty)
                _buildSpecRow(
                  'Barcode',
                  currentVariantSpec['barcode'].toString(),
                  isLast: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build specification row
  Widget _buildSpecRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.borderSecondary,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer for specifications section
  Widget _buildSpecificationsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Full page loading shimmer
  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 300.h,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Title shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Price shimmer
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Variant selector shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 80,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Specifications shimmer
                _buildSpecificationsShimmer(),

                const SizedBox(height: 16),

                // Reviews shimmer
                _buildReviewsShimmer(),

                // Description shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 250,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Discover section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Title shimmer
  Widget _buildTitleShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 200,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Price shimmer
  Widget _buildPriceShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: 100,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 70,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Variant selector shimmer
  Widget _buildVariantShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 80,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(
            children: [
              Container(
                width: 90,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 90,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 90,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Description shimmer
  Widget _buildDescriptionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 220,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Description section with "View all details" link
  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _showFullDescription(description);
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'View all details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  /// Show full description in a scrollable bottom sheet
  void _showFullDescription(String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bottom sticky bar shimmer
  Widget _buildBottomBarShimmer() {
    return Container(
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
                  // Item price row shimmer
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

                  // Total price row shimmer
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

            // Action buttons row shimmer
            Row(
              children: [
                // Wishlist button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Cart button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Buy Now button shimmer
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sticky bar with price and action buttons
  Widget _buildBottomBar(ProductDetailsLoaded state, ProductVariant selectedVariant) {
    final currentPrice = formatIndianCurrency(selectedVariant.priceV2.amount);
    final originalPrice = selectedVariant.compareAtPriceV2 != null ? formatIndianCurrency(selectedVariant.compareAtPriceV2!.amount) : '';
    final discount = _calculateDiscountPercent(selectedVariant);

    // Calculate shipping charges
    final itemPrice = double.tryParse(selectedVariant.priceV2.amount) ?? 0;
    const shippingCharges = 99.0;
    final needsShipping = itemPrice < 1000;
    final totalPrice = needsShipping ? itemPrice + shippingCharges : itemPrice;

    return Container(
      padding: EdgeInsets.fromLTRB(8.h, 12.h, 12.h, 16.h),
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
            // Price breakdown section
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
                  // Item price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Price',
                        style: TextStyle(
                          fontSize: 13.fSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            currentPrice,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (originalPrice.isNotEmpty) ...[
                            SizedBox(width: 6.w),
                            Text(
                              originalPrice,
                              style: TextStyle(
                                fontSize: 11.fSize,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textMuted,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                          if (discount > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                '-$discount%',
                                style: TextStyle(
                                  fontSize: 9.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // SizedBox(height: 4.h),

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
                        needsShipping ? formatIndianCurrency(shippingCharges.toString()) : 'FREE',
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

                  // Total price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        formatIndianCurrency(totalPrice.toString()),
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

            // Action buttons row
            Row(
              children: [
                // Wishlist button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _toggleWishlist,
                    icon: ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: Icon(
                        state.isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF5C9A),
                        size: 22,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(width: 8),

                // Cart button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ScaleTransition(
                    scale: _cartScaleAnimation,
                    child: IconButton(
                      onPressed: _addToCart,
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFFFF5C9A),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Buy Now button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: !_buttonTextReady
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _handleBuyNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5C9A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _hasCompleteAddress ? 'Buy Now' : 'Add Address',
                                  style: const TextStyle(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Discover Products Section
  Widget _buildDiscoverSection() {
    return BlocBuilder<TopProductsCubit, TopProductsState>(
      builder: (context, state) {
        if (state is TopProductsLoading) {
          return _buildDiscoverShimmer();
        }

        if (state is TopProductsError) {
          return const SizedBox.shrink();
        }

        if (state is TopProductsSuccess) {
          // Check if collection exists
          if (state.collection == null) {
            return const SizedBox.shrink();
          }

          // Show only first 8 products
          final products = state.collection!.products.take(8).toList();

          if (products.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'You may also like',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProducts(handle: discoverHandle),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF5C9A),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Color(0xFFFF5C9A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Horizontal scrollable product list
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: products.map((product) {
                    return _buildDiscoverProductCard(product);
                  }).toList(),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Discover section shimmer loading
  Widget _buildDiscoverShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Product cards shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image shimmer
                    Container(
                      height: 160,
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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 80,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Individual discover product card
  Widget _buildDiscoverProductCard(TopProduct product) {
    final variant = product.variants.isNotEmpty ? product.variants[0] : null;

    if (variant == null) return const SizedBox.shrink();

    final currentPrice = formatIndianCurrency(variant.priceV2.amount);
    final originalPrice = variant.compareAtPriceV2 != null ? formatIndianCurrency(variant.compareAtPriceV2!.amount) : '';

    int discountPercent = 0;
    if (variant.compareAtPriceV2 != null) {
      final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
      final price = double.tryParse(variant.priceV2.amount) ?? 0;
      if (compareAt > 0) {
        discountPercent = ((compareAt - price) / compareAt * 100).round();
      }
    }

    final imageUrl = product.images.isNotEmpty ? product.images[0].originalSrc : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProducts(handle: discoverHandle),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                  height: 160,
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
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
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
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Product description
                  if (product.description.isNotEmpty)
                    Text(
                      product.description
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .replaceAll('&amp;', '&')
                          .replaceAll('&lt;', '<')
                          .replaceAll('&gt;', '>')
                          .replaceAll('&quot;', '"')
                          .replaceAll('&#39;', "'")
                          .replaceAll('&nbsp;', ' ')
                          .trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Price row
                  Row(
                    children: [
                      Text(
                        currentPrice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPrice,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
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

  /// Product Reviews Section
  Widget _buildReviewsSection(ProductDetailsLoaded state) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, reviewsState) {
        if (reviewsState is ReviewsLoading) {
          return _buildReviewsShimmer();
        }

        if (reviewsState is ReviewsError) {
          return const SizedBox.shrink(); // Hide on error
        }

        if (reviewsState is ReviewsLoaded) {
          // If no reviews available
          if (reviewsState.reviews.isEmpty) {
            return _buildNoReviewsSection();
          }

          // Show reviews in card format
          return _buildReviewsCard(state, reviewsState);
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Reviews card with proper styling matching specifications
  Widget _buildReviewsCard(ProductDetailsLoaded state, ReviewsLoaded reviewsState) {
    final productId = state.product.id;
    final numericId = productId.contains('/') ? productId.split('/').last : productId;
    final limitedReviews = reviewsState.reviews.take(2).toList();
    final hasMoreReviews = reviewsState.reviews.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (hasMoreReviews)
              GestureDetector(
                onTap: () => _navigateToAllReviews(numericId, state.product.title),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5C9A),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Reviews card container
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Average rating section
              // if (reviewsState.product != null)
              //   _buildAverageRatingRow(reviewsState.product!, numericId, state.product.title),

              // Review cards
              ...limitedReviews.asMap().entries.map((entry) {
                final index = entry.key;
                final review = entry.value;
                final isLast = index == limitedReviews.length - 1 && !hasMoreReviews;
                return _buildReviewRow(review, isLast);
              }).toList(),

              // View all button
              if (hasMoreReviews) _buildViewAllReviewsRow(numericId, state.product.title, reviewsState.reviews.length),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Average rating row
  Widget _buildAverageRatingRow(JudgemeProduct product, String productId, String productName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Star rating
          Row(
            children: List.generate(5, (index) {
              final rating = product.averageRating;
              if (index < rating.floor()) {
                return const Icon(
                  Icons.star,
                  size: 18,
                  color: Color(0xFFFFA500),
                );
              } else if (index < rating) {
                return const Icon(
                  Icons.star_half,
                  size: 18,
                  color: Color(0xFFFFA500),
                );
              } else {
                return Icon(
                  Icons.star_border,
                  size: 18,
                  color: Colors.grey.shade300,
                );
              }
            }),
          ),

          const SizedBox(width: 12),

          // Rating text
          Expanded(
            child: Text(
              '${product.averageRating.toStringAsFixed(1)} out of 5 (${product.reviewsCount} review${product.reviewsCount > 1 ? 's' : ''})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Arrow
          GestureDetector(
            onTap: () => _navigateToAllReviews(productId, productName),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual review row
  Widget _buildReviewRow(JudgemeReview review, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info and rating
          Row(
            children: [
              // Reviewer avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C9A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.reviewerInitials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF5C9A),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Reviewer name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      review.formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: const Color(0xFFFFA500),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review title
          if (review.title.isNotEmpty) ...[
            Text(
              review.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],

          // Review body
          if (review.body.isNotEmpty) ...[
            Text(
              review.body,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Verified buyer badge
          if (review.verifiedBuyer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                'Verified Buyer',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// View all reviews row
  Widget _buildViewAllReviewsRow(String productId, String productName, int totalReviews) {
    return GestureDetector(
      onTap: () => _navigateToAllReviews(productId, productName),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View All $totalReviews Reviews',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF5C9A),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward,
              size: 14,
              color: Color(0xFFFF5C9A),
            ),
          ],
        ),
      ),
    );
  }

  /// No reviews section
  Widget _buildNoReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Reviews Available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Be the first to review this product',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Reviews shimmer effect
  Widget _buildReviewsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Navigate to all reviews screen
  void _navigateToAllReviews(String productId, String productName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }
}
