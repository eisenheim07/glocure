import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/wishlist_item_model.dart';
import '../models/top_products_model.dart';
import '../utils/wishlist_storage.dart';
import '../utils/format_utils.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../utils/auth_storage.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/wishlist_icon_with_badge.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<WishlistItem> _wishlistItems = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _movingToCartItemId; // Track which item is being moved to cart

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  /// Load wishlist from local storage
  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);

    try {
      final items = await WishlistStorage.getWishlist();
      if (mounted) {
        setState(() {
          _wishlistItems = items;
          _isLoading = false;
        });
      }
      debugPrint('✅ Loaded ${items.length} items from wishlist');
    } catch (e) {
      debugPrint('❌ Error loading wishlist: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadWishlist();
    setState(() => _isRefreshing = false);
  }

  /// Remove item from wishlist
  Future<void> _removeFromWishlist(WishlistItem item) async {
    try {
      final success = await WishlistStorage.removeFromWishlist(item.productId);
      if (success && mounted) {
        setState(() {
          _wishlistItems.removeWhere((i) => i.productId == item.productId);
        });
        
        // Notify wishlist badge to update
        WishlistNotifier.notifyWishlistChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Move item to cart and remove from wishlist
  Future<void> _moveToCart(WishlistItem item) async {
    // Set shimmer state for this item
    setState(() {
      _movingToCartItemId = item.productId;
    });

    try {
      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();
      
      if (cartId == null || cartId.isEmpty) {
        setState(() {
          _movingToCartItemId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cart not initialized. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Validate variant ID
      if (item.variantId.isEmpty) {
        setState(() {
          _movingToCartItemId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product variant not available'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Moving to cart...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call API to add to cart
      await ApiService().cartLinesAdd(
        cartId: cartId,
        merchandiseId: item.variantId,
        quantity: 1,
      );

      // Remove from wishlist after successfully adding to cart
      final removeSuccess = await WishlistStorage.removeFromWishlist(item.productId);
      
      if (removeSuccess && mounted) {
        setState(() {
          _wishlistItems.removeWhere((i) => i.productId == item.productId);
          _movingToCartItemId = null; // Clear shimmer state
        });
        
        // Notify wishlist badge to update
        WishlistNotifier.notifyWishlistChanged();
      }

      // Hide loading and show success
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Format message: truncate title if needed
        final maxTitleLength = 35;
        String message;
        
        if (item.title.length > maxTitleLength) {
          final truncatedTitle = item.title.substring(0, maxTitleLength).trim();
          message = '$truncatedTitle...moved to cart';
        } else {
          message = '${item.title} moved to cart';
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
      debugPrint('❌ Error moving to cart: $e');
      setState(() {
        _movingToCartItemId = null; // Clear shimmer state on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move to cart: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Navigate to product details
  void _navigateToProductDetails(WishlistItem item) {
    // Create a TopProduct object from WishlistItem
    final product = TopProduct(
      id: item.productId,
      title: item.title,
      description: '',
      handle: item.productHandle,
      images: item.imageUrl != null
          ? [ProductImage(originalSrc: item.imageUrl!, altText: null)]
          : [],
      variants: [
        ProductVariant(
          id: item.productId,
          title: 'Default',
          sku: null,
          priceV2: Money(
            amount: item.price,
            currencyCode: 'INR',
          ),
          compareAtPriceV2: item.discountedPrice != null
              ? Money(
                  amount: item.discountedPrice!,
                  currencyCode: 'INR',
                )
              : null,
          availableForSale: true,
        ),
      ],
      productType: '',
      vendor: '',
      tags: [],
      createdAt: '',
      updatedAt: '',
      onlineStoreUrl: null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          handle: item.mainHandle,
        ),
      ),
    ).then((_) {
      // Refresh wishlist when returning from product details
      _loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Wishlist',
      ),
      body: _isLoading || _isRefreshing
          ? _buildShimmerLoading()
          : _wishlistItems.isEmpty
              ? _buildEmptyState()
              : _buildWishlistContent(),
    );
  }

  /// Build wishlist content with pull-to-refresh
  Widget _buildWishlistContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.all(12.w),
        itemCount: _wishlistItems.length,
        separatorBuilder: (context, index) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = _wishlistItems[index];
          return _buildWishlistCard(item);
        },
      ),
    );
  }

  /// Build individual wishlist card
  Widget _buildWishlistCard(WishlistItem item) {
    final currentPrice = formatIndianCurrency(item.price);
    final originalPrice = item.discountedPrice != null
        ? formatIndianCurrency(item.discountedPrice!)
        : null;
    final discount = item.discountPercent;
    final isMovingToCart = _movingToCartItemId == item.productId;

    return GestureDetector(
      onTap: isMovingToCart ? null : () => _navigateToProductDetails(item),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.borderSecondary,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 95.w,
              height: 95.h,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  bottomLeft: Radius.circular(10.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  bottomLeft: Radius.circular(10.r),
                ),
                child: item.imageUrl != null
                    ? NetworkImageLoader(
                        imageUrl: item.imageUrl!,
                        width: 95.w,
                        height: 95.h,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.fSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    // Price Row
                    Row(
                      children: [
                        Text(
                          currentPrice,
                          style: TextStyle(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (originalPrice != null) ...[
                          SizedBox(width: 6.w),
                          Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.gray500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 5.h),

                    // Move to Cart Button and Discount Badge
                    Row(
                      children: [
                        // Move to Cart Button
                        GestureDetector(
                          onTap: () => _moveToCart(item),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color: AppColors.borderPrimary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 14,
                                  color: AppColors.gray700,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Move to cart',
                                  style: TextStyle(
                                    fontSize: 11.fSize,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (discount != null && discount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '-$discount%',
                              style: TextStyle(
                                fontSize: 11.fSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Heart Icon (Remove from Wishlist)
            Padding(
              padding: EdgeInsets.all(6.w),
              child: GestureDetector(
                onTap: isMovingToCart ? null : () => _removeFromWishlist(item),
                child: Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
          
          // Shimmer overlay when moving to cart
          if (isMovingToCart)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: Colors.white.withOpacity(0.7),
                ),
                child: Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.gray300,
          ),
          SizedBox(height: 12.h),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Add products you love to your wishlist',
            style: TextStyle(
              fontSize: 13.fSize,
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
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
    );
  }

  /// Build shimmer loading state
  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: 5,
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            height: 95.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      },
    );
  }
}
