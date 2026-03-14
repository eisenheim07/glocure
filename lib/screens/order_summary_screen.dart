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
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/payment_selection_bottom_sheet.dart';
import '../cubits/cart/cart_cubit.dart';
import '../cubits/cart/cart_state.dart';
import '../cubits/customer/customer_cubit.dart';
import '../cubits/customer/customer_state.dart';
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
  bool _isLoading = true;
  bool _isRefreshing = false; // Track refresh state
  bool _showAllProducts = false; // Track if user wants to see all products

  // Related products state
  bool _isLoadingRelatedProducts = false;
  List<Map<String, dynamic>> _relatedProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRelatedProducts(String productId) async {
    if (_isLoadingRelatedProducts) return;

    setState(() => _isLoadingRelatedProducts = true);

    try {
      final products = await ApiService().getRelatedProducts(
        productId: productId,
        limit: 4,
      );

      setState(() {
        _relatedProducts = products;
        _isLoadingRelatedProducts = false;
      });
    } catch (e) {
      debugPrint('Error fetching related products: $e');
      setState(() => _isLoadingRelatedProducts = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

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
          await _fetchRelatedProducts(firstProduct.id);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing order summary: $e');
    } finally {
      setState(() => _isRefreshing = false);
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
        // Show loading state on order summary screen
        setState(() => _isLoading = true);

        try {
          // Create order
          debugPrint('📦 Creating $paymentMethod order...');
          final order = await OrderService().createOrder(
            cart: cart,
            customer: customer,
            paymentMethod: paymentMethod,
          );

          debugPrint('✅ Order created: ${order.id}');

          // Hide loading
          if (mounted) {
            setState(() => _isLoading = false);
          }

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
            setState(() => _isLoading = false);
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

    // Show shimmer loading on order summary screen
    setState(() => _isLoading = true);

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

    // Navigate to payment status screen (shimmer will close in background)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusScreen(
            status: status,
            order: order,
          ),
        ),
      ).then((_) {
        // Close shimmer in background after navigation
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
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
          if (_isLoading || _isRefreshing || customerState is CustomerLoading) {
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
                    child: _buildContent(customer),
                  ),

                  // Fixed bottom section with total and button
                  if (cartState is CartSuccess) _buildBottomSection(cartState.cart, customer),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(Customer customer) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        // Fetch related products when cart is loaded
        if (cartState is CartSuccess && !_isLoadingRelatedProducts && _relatedProducts.isEmpty && cartState.cart.lines.isNotEmpty) {
          // Get first product ID from cart
          final firstProduct = cartState.cart.lines.first.merchandise?.product;
          if (firstProduct != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchRelatedProducts(firstProduct.id);
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
                if (cartState is CartSuccess) _buildCartProductsCard(cartState.cart),

                if (cartState is CartLoading) _buildCartProductsShimmer(),

                SizedBox(height: 16),

                // Related Products Section
                if (_isLoadingRelatedProducts) _buildRelatedProductsShimmer() else if (_relatedProducts.isNotEmpty) _buildRelatedProductsSection(),

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
    final formattedTotal = formatIndianCurrency(totalAmount);

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
      padding: EdgeInsets.all(10.w),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: 17.fSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  formattedTotal,
                  style: TextStyle(
                    fontSize: 17.fSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Proceed to Pay button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => _handleProceedToPay(context, cart, customer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Pay',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
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
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              // Edit button
              Container(
                width: 34.w,
                height: 34.h,
                decoration: BoxDecoration(
                  color: Color(0xFFFF5C9A),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
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

  Widget _buildCartProductsCard(Cart cart) {
    final totalItems = cart.lines.length;
    final displayedItems = _showAllProducts ? cart.lines : cart.lines.take(2).toList();

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
                    setState(() {
                      _showAllProducts = !_showAllProducts;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5C9A),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllProducts ? 'View Less' : 'View More',
                        style: TextStyle(
                          fontSize: 12.fSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        _showAllProducts ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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

  Widget _buildRelatedProductsSection() {
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
            children: _relatedProducts.map((product) {
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
          padding: EdgeInsets.all(14.w),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total row shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 51.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                      Container(
                        width: 85.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
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
      ],
    );
  }
}
