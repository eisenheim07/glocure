import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/cart/cart_cubit.dart';
import '../cubits/cart/cart_state.dart';
import '../models/cart_model.dart';
import '../models/customer_model.dart';
import '../utils/format_utils.dart';
import '../utils/auth_storage.dart';
import '../utils/size_utils.dart';
import '../services/api_service.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/custom_app_bar.dart';
import 'address_screen.dart';
import 'order_summary_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _hasCompleteAddress = false;
  bool _hasCheckedAddress = false;
  bool _buttonTextReady = false; // Track if button text is determined
  Customer? _customer; // Store customer object

  @override
  void initState() {
    super.initState();
    // Fetch cart data on screen load
    context.read<CartCubit>().fetchCart();
  }

  Future<void> _deleteDefaultAddressAndCheck() async {
    if (_hasCheckedAddress) return; // Prevent multiple calls
    _hasCheckedAddress = true;

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true; // Button text is ready
        });
        return;
      }

      // First, fetch customer to get default address
      final customer = await ApiService().getCustomer(token);
      
      // Store customer object
      _customer = customer;
      
      if (customer == null) {
        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true; // Button text is ready
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
            debugPrint('✅ Default address deleted successfully');
          } catch (e) {
            debugPrint('❌ Error deleting default address: $e');
          }
        } else {
          // No address to delete, just log
          debugPrint('ℹ️ No default address to delete');
        }
        
        // After deletion (or if address was null), button shows "Add Address"
        setState(() {
          _hasCompleteAddress = false;
          _buttonTextReady = true; // Button text is ready
        });
      } else {
        // Address is complete, no deletion needed, button shows "Proceed to Pay"
        debugPrint('ℹ️ Address is complete, no deletion needed');
        setState(() {
          _hasCompleteAddress = true;
          _buttonTextReady = true; // Button text is ready
        });
      }
    } catch (e) {
      debugPrint('Error in delete and check flow: $e');
      setState(() {
        _hasCompleteAddress = false;
        _buttonTextReady = true; // Button text is ready even on error
      });
    }
  }

  Future<void> _checkCustomerAddress() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() => _hasCompleteAddress = false);
        return;
      }

      final customer = await ApiService().getCustomer(token);
      setState(() {
        _hasCompleteAddress = customer?.hasCompleteAddress() ?? false;
      });
    } catch (e) {
      debugPrint('Error checking customer address: $e');
      setState(() => _hasCompleteAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'My Cart',
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return _buildLoadingState();
          }

          if (state is CartError) {
            return _buildErrorState(state.message);
          }

          if (state is CartEmpty) {
            return _buildEmptyState();
          }

          if (state is CartSuccess) {
            // Check address only when cart has items and hasn't been checked yet
            if (!_hasCheckedAddress) {
              // Schedule address check after this frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _deleteDefaultAddressAndCheck();
              });
            }
            return _buildCartContent(state.cart);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildCartContent(Cart cart) {
    return Column(
      children: [
        // Cart items list with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _hasCheckedAddress = false; // Reset flag to allow re-check
              await context.read<CartCubit>().refreshCart();
              await _checkCustomerAddress();
            },
            color: const Color(0xFFFF5C9A),
            child: ListView.separated(
              padding: EdgeInsets.all(14.w),
              itemCount: cart.lines.length,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final cartLine = cart.lines[index];
                final isUpdating = context.watch<CartCubit>().isLineUpdating(cartLine.id);
                final isAnyOperationInProgress = context.watch<CartCubit>().isAnyOperationInProgress;
                return _CartItemCard(
                  cartLine: cartLine,
                  isUpdating: isUpdating,
                  isAnyOperationInProgress: isAnyOperationInProgress,
                );
              },
            ),
          ),
        ),

        // Bottom section with total and button
        _buildBottomSection(cart),
      ],
    );
  }

  Widget _buildBottomSection(Cart cart) {
    final totalAmount = cart.cost?.totalAmount.amount ?? '0';
    final formattedTotal = formatIndianCurrency(totalAmount);
    
    // Check if any item is being updated
    final isAnyItemUpdating = cart.lines.any(
      (line) => context.watch<CartCubit>().isLineUpdating(line.id),
    );

    // Show shimmer until button text is ready OR while updating items
    final showShimmer = !_buttonTextReady || isAnyItemUpdating;

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
      padding: EdgeInsets.all(14.w),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total row with shimmer when not ready or updating
            showShimmer
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 55.w,
                          height: 22.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        Container(
                          width: 90.w,
                          height: 22.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18.fSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        formattedTotal,
                        style: TextStyle(
                          fontSize: 18.fSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

            SizedBox(height: 14.h),

            // Button with shimmer until text is ready or while updating
            showShimmer
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_hasCompleteAddress) {
                          // Navigate to order summary screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrderSummaryScreen(),
                            ),
                          );
                        } else {
                          // Navigate to address screen with customer object
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddressScreen(
                                customer: _customer,
                              ),
                            ),
                          );
                        }
                      },
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
                            _hasCompleteAddress ? 'Proceed to Pay' : 'Add Address',
                            style: TextStyle(
                              fontSize: 15.fSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Icon(Icons.arrow_forward, size: 18.h),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CartCubit>().refreshCart();
      },
      color: const Color(0xFFFF5C9A),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    'Add products to get started',
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C9A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 28.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Start Shopping',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 70.h,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 14.h),
            Text(
              'Failed to load cart',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.fSize,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                context.read<CartCubit>().fetchCart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Cart items shimmer
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(14.w),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
            itemBuilder: (context, index) {
              return const _CartItemShimmer();
            },
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
                        width: 55.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Container(
                        width: 90.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
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

/// Cart Item Card Widget
class _CartItemCard extends StatelessWidget {
  final CartLine cartLine;
  final bool isUpdating;
  final bool isAnyOperationInProgress;

  const _CartItemCard({
    required this.cartLine,
    this.isUpdating = false,
    this.isAnyOperationInProgress = false,
  });

  int _discountPercent() {
    final merchandise = cartLine.merchandise;
    if (merchandise == null || merchandise.compareAtPriceV2 == null) return 0;

    final compareAt = double.tryParse(merchandise.compareAtPriceV2!.amount) ?? 0;
    final price = double.tryParse(merchandise.priceV2.amount) ?? 0;

    if (compareAt <= 0 || price >= compareAt) return 0;
    return ((compareAt - price) / compareAt * 100).round();
  }

  void _updateQuantity(BuildContext context, int newQuantity) {
    final merchandise = cartLine.merchandise;
    if (merchandise == null) return;

    // Check if quantity exceeds available quantity
    final availableQty = merchandise.quantityAvailable;
    if (availableQty != null && newQuantity > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $availableQty items available in stock'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if quantity is less than 1
    if (newQuantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity cannot be less than 1'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Update quantity
    context.read<CartCubit>().updateQuantity(cartLine.id, newQuantity);
  }

  Future<void> _removeItem(BuildContext context) async {
    try {
      // Remove item from cart
      await context.read<CartCubit>().removeItem(cartLine.id);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchandise = cartLine.merchandise;
    if (merchandise == null) return const SizedBox.shrink();

    final product = merchandise.product;
    final currentPrice = formatIndianCurrency(merchandise.priceV2.amount);
    final originalPrice = merchandise.compareAtPriceV2 != null ? formatIndianCurrency(merchandise.compareAtPriceV2!.amount) : '';
    final discount = _discountPercent();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(10.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              width: 85.w,
              height: 85.h,
              color: Colors.grey.shade50,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? NetworkImageLoader(
                      imageUrl: product.imageUrl!,
                      width: 85.w,
                      height: 85.h,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
            ),
          ),

          SizedBox(width: 10.w),

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
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 7.h),

                // Price row
                Row(
                  children: [
                    Text(
                      currentPrice,
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (originalPrice.isNotEmpty) ...[
                      SizedBox(width: 7.w),
                      Text(
                        originalPrice,
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    if (discount > 0) ...[
                      SizedBox(width: 7.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '-$discount%',
                          style: TextStyle(
                            fontSize: 11.fSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 7.h),

                // Quantity controls and variant info
                Row(
                  children: [
                    Text(
                      'Quantity: ',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrease button or Delete button when quantity is 1
                          IconButton(
                            onPressed: isAnyOperationInProgress
                                ? null
                                : () {
                                    if (cartLine.quantity == 1) {
                                      _removeItem(context);
                                    } else {
                                      _updateQuantity(context, cartLine.quantity - 1);
                                    }
                                  },
                            icon: Icon(
                              cartLine.quantity == 1 ? Icons.delete_outline : Icons.remove,
                              size: 14.h,
                              color: isAnyOperationInProgress
                                  ? Colors.grey.shade300
                                  : (cartLine.quantity == 1 ? Colors.red : Colors.grey.shade700),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 28.w,
                              minHeight: 28.h,
                            ),
                            splashRadius: 18,
                          ),
                          Container(
                            width: 1,
                            height: 18.h,
                            color: Colors.grey.shade300,
                          ),
                          // Quantity display with loading indicator
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: isUpdating
                                ? SizedBox(
                                    width: 12.w,
                                    height: 12.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${cartLine.quantity}',
                                    style: TextStyle(
                                      fontSize: 13.fSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                          Container(
                            width: 1,
                            height: 18.h,
                            color: Colors.grey.shade300,
                          ),
                          // Increase button
                          IconButton(
                            onPressed: isAnyOperationInProgress
                                ? null
                                : () => _updateQuantity(context, cartLine.quantity + 1),
                            icon: Icon(
                              Icons.add,
                              size: 14.h,
                              color: isAnyOperationInProgress ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 28.w,
                              minHeight: 28.h,
                            ),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    if (merchandise.title.isNotEmpty && merchandise.title != 'Default Title') ...[
                      SizedBox(width: 10.w),
                      Flexible(
                        child: Text(
                          '| ${merchandise.title}',
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: isAnyOperationInProgress ? null : () => _removeItem(context),
            icon: Icon(
              Icons.delete_outline,
              color: isAnyOperationInProgress ? Colors.grey.shade300 : Colors.grey.shade400,
              size: 20.h,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Cart Item Shimmer
class _CartItemShimmer extends StatelessWidget {
  const _CartItemShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.all(10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 85.w,
              height: 85.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14.h,
                    color: Colors.white,
                  ),
                  SizedBox(height: 7.h),
                  Container(
                    width: 130.w,
                    height: 14.h,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 90.w,
                    height: 18.h,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
