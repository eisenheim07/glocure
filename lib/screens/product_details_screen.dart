import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../config/api_config.dart';
import '../models/top_products_model.dart';
import '../models/wishlist_item_model.dart';
import '../utils/format_utils.dart';
import '../utils/size_utils.dart';
import '../utils/auth_storage.dart';
import '../utils/wishlist_storage.dart';
import '../services/api_service.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/custom_app_bar.dart';
import '../cubits/top_products/top_products_cubit.dart';
import '../cubits/top_products/top_products_state.dart';
import 'category_products.dart';

class ProductDetailsScreen extends StatefulWidget {
  final TopProduct product;
  final String? handle;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.handle,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with TickerProviderStateMixin {
  late TopProduct _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  int _selectedVariantIndex = 0;
  Map<String, dynamic>? _specifications;
  late String discoverHandle;
  final PageController _pageController = PageController();
  
  // Wishlist state
  bool _isInWishlist = false;
  bool _isCheckingWishlist = true;
  
  // Animation controller for heart icon
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  
  // Animation controller for cart icon
  late AnimationController _cartAnimationController;
  late Animation<double> _cartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchProductDetails();
    _checkWishlistStatus();

    // Initialize heart animation
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
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
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_cartAnimationController);

    // Fetch discover products using handle (default to "top-products" if null)
    discoverHandle = widget.handle ?? 'top-products';
    debugPrint('ProductDetailsScreen - Handle received: $discoverHandle');
    context.read<TopProductsCubit>().fetchProductsForHandle(discoverHandle);
  }

  /// Check if product is in wishlist
  Future<void> _checkWishlistStatus() async {
    setState(() => _isCheckingWishlist = true);
    
    try {
      final isInWishlist = await WishlistStorage.isInWishlist(_product.id);
      setState(() {
        _isInWishlist = isInWishlist;
        _isCheckingWishlist = false;
      });
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
      setState(() => _isCheckingWishlist = false);
    }
  }

  /// Toggle wishlist status
  Future<void> _toggleWishlist() async {
    // Trigger animation
    _heartAnimationController.forward(from: 0.0);
    
    try {
      if (_isInWishlist) {
        // Remove from wishlist
        final success = await WishlistStorage.removeFromWishlist(_product.id);
        if (success) {
          setState(() => _isInWishlist = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Removed from wishlist'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Add to wishlist
        final variant = _product.variants.isNotEmpty 
            ? _product.variants[_selectedVariantIndex] 
            : null;
        
        if (variant == null) {
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

        // Calculate discount
        int? discountPercent;
        if (variant.compareAtPriceV2 != null) {
          final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
          final price = double.tryParse(variant.priceV2.amount) ?? 0;
          if (compareAt > 0 && price < compareAt) {
            discountPercent = ((compareAt - price) / compareAt * 100).round();
          }
        }

        final wishlistItem = WishlistItem(
          productId: _product.id,
          variantId: variant.id,
          productHandle: _product.handle,
          mainHandle: widget.handle ?? 'top-products',
          title: _product.title,
          price: variant.priceV2.amount,
          discountedPrice: variant.compareAtPriceV2?.amount,
          discountPercent: discountPercent,
          imageUrl: _product.images.isNotEmpty ? _product.images[0].originalSrc : null,
          addedAt: DateTime.now(),
        );

        final success = await WishlistStorage.addToWishlist(wishlistItem);
        if (success) {
          setState(() => _isInWishlist = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to wishlist'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
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

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  /// Fetch complete product details from Admin API
  /// Falls back to passed _product object only if API returns null
  Future<void> _fetchProductDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Extract numeric ID from Shopify GID
      final numericId = _product.id.contains('/') ? _product.id.split('/').last : _product.id;
      debugPrint('🚀 Fetching complete product details for ID: $numericId');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$numericId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': ApiConfig.shopifyAdminAccessToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final productsJson = responseData['products'] as List<dynamic>? ?? [];

        if (productsJson.isNotEmpty) {
          final productJson = productsJson.first as Map<String, dynamic>;

          // Parse all product details from API
          final images = (productJson['images'] as List<dynamic>? ?? [])
              .map((img) => ProductImage(
                    originalSrc: img['src'] ?? '',
                    altText: img['alt'] as String?,
                  ))
              .toList();

          final variants = (productJson['variants'] as List<dynamic>? ?? [])
              .map((v) => ProductVariant(
                    id: 'gid://shopify/ProductVariant/${v['id']}',
                    title: v['title'] ?? '',
                    sku: v['sku'] as String?,
                    priceV2: Money(
                      amount: v['price']?.toString() ?? '0',
                      currencyCode: 'INR',
                    ),
                    compareAtPriceV2: v['compare_at_price'] != null
                        ? Money(
                            amount: v['compare_at_price'].toString(),
                            currencyCode: 'INR',
                          )
                        : null,
                    availableForSale: v['available'] ?? false,
                  ))
              .toList();

          // Extract specifications
          final specifications = <String, dynamic>{
            'options': productJson['options'] ?? [],
            'variants': (productJson['variants'] as List<dynamic>? ?? []).map((v) {
              return {
                'id': v['id'],
                'title': v['title'],
                'weight': v['weight'],
                'weight_unit': v['weight_unit'],
                'inventory_quantity': v['inventory_quantity'],
                'option1': v['option1'],
                'option2': v['option2'],
                'option3': v['option3'],
                'sku': v['sku'],
                'barcode': v['barcode'],
              };
            }).toList(),
          };

          // Use API data as primary source
          final updatedProduct = TopProduct(
            id: 'gid://shopify/Product/${productJson['id']}',
            title: productJson['title'] ?? _product.title,
            description: productJson['body_html'] ?? _product.description,
            handle: productJson['handle'] ?? _product.handle,
            images: images.isNotEmpty ? images : _product.images,
            variants: variants.isNotEmpty ? variants : _product.variants,
            productType: productJson['product_type'] ?? _product.productType,
            vendor: productJson['vendor'] ?? _product.vendor,
            tags: (productJson['tags'] as String? ?? '').split(', ').where((t) => t.isNotEmpty).toList(),
            createdAt: productJson['created_at'] ?? _product.createdAt,
            updatedAt: productJson['updated_at'] ?? _product.updatedAt,
            onlineStoreUrl: _product.onlineStoreUrl,
          );

          if (mounted) {
            setState(() {
              _product = updatedProduct;
              _specifications = specifications;
              _isLoading = false;
            });
          }

          debugPrint('✅ Successfully fetched complete product details from API');
          return;
        }
      }

      // If API fails or returns no data, use the passed product object
      debugPrint('⚠️ API returned no data, using passed product object');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching product details: $e');
      // Fall back to passed product object
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ProductVariant get _selectedVariant => _product.variants.isNotEmpty
      ? _product.variants[_selectedVariantIndex]
      : ProductVariant(
          id: '',
          title: '',
          sku: null,
          priceV2: Money(amount: '0', currencyCode: 'INR'),
          compareAtPriceV2: null,
          availableForSale: false,
        );

  int _discountPercent() {
    final variant = _selectedVariant;
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
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Get the first variant ID (as per requirement)
      if (_product.variants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product variant not available'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final variantId = _selectedVariant.id;

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
        
        if (_product.title.length > maxTitleLength) {
          // Truncate and add ellipsis before "added to cart"
          final truncatedTitle = _product.title.substring(0, maxTitleLength).trim();
          message = '$truncatedTitle...added to cart';
        } else {
          message = '${_product.title} added to cart';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 20),
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('❌ Add to cart error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = formatIndianCurrency(_selectedVariant.priceV2.amount);
    final originalPrice = _selectedVariant.compareAtPriceV2 != null ? formatIndianCurrency(_selectedVariant.compareAtPriceV2!.amount) : '';
    final discount = _discountPercent();
    final description = _cleanDescription(_product.description);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Product detail',
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel with shimmer
                  _isLoading ? _buildImageShimmer() : _buildImageCarousel(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Product title with shimmer
                        _isLoading
                            ? _buildTitleShimmer()
                            : Text(
                                _product.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),

                        const SizedBox(height: 12),

                        // Pricing row with shimmer
                        _isLoading
                            ? _buildPriceShimmer()
                            : _buildPricingRow(currentPrice, originalPrice, discount),

                        const SizedBox(height: 12),

                        // Variant selector with shimmer
                        if (_isLoading)
                          _buildVariantShimmer()
                        else if (_product.variants.length > 1)
                          _buildVariantSelector(),

                        // Product Specifications with shimmer
                        _isLoading ? _buildSpecificationsShimmer() : _buildSpecificationsSection(),

                        // Description with shimmer
                        if (_isLoading)
                          _buildDescriptionShimmer()
                        else if (description.isNotEmpty)
                          _buildDescription(description),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Discover Products Section
                  _buildDiscoverSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom "Add to Cart" button
          _isLoading ? _buildBottomBarShimmer() : _buildBottomBar(),
        ],
      ),
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
  Widget _buildImageCarousel() {
    final images = _product.images;

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
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
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
                setState(() => _currentImageIndex = index);
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
                final url = _product.onlineStoreUrl ?? 'https://glocure.com/products/${_product.handle}';
                Clipboard.setData(ClipboardData(text: '${_product.title}\n$url'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.share_outlined, size: 18, color: Colors.black54),
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
                  final isActive = index == _currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 10 : 7,
                    height: isActive ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? const Color(0xFFFF5C9A) : Colors.grey.shade400,
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
            color: Colors.black,
          ),
        ),
        if (originalPrice.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            originalPrice,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey.shade500,
            ),
          ),
        ],
        if (discount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$discount% off',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Variant selector with horizontal chips
  Widget _buildVariantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Size',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(_product.variants.length, (index) {
            final variant = _product.variants[index];
            final isSelected = index == _selectedVariantIndex;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedVariantIndex = index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFE9F0) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF5C9A) : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  variant.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFFFF5C9A) : Colors.grey.shade700,
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
  Widget _buildSpecificationsSection() {
    if (_specifications == null) {
      return const SizedBox.shrink();
    }

    final options = _specifications!['options'] as List<dynamic>? ?? [];
    final variants = _specifications!['variants'] as List<dynamic>? ?? [];
    
    if (options.isEmpty && variants.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current variant specs
    final currentVariantSpec = variants.isNotEmpty && _selectedVariantIndex < variants.length
        ? variants[_selectedVariantIndex] as Map<String, dynamic>
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
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
            color: Colors.black,
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
              Text(
                'View all details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5C9A),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: Color(0xFFFF5C9A)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
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
                    color: Colors.grey.shade300,
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
        child: Row(
          children: [
            // Price section shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 60,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

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
      ),
    );
  }

  /// Bottom sticky bar with price and action buttons
  Widget _buildBottomBar() {
    final variant = _selectedVariant;
    final currentPrice = formatIndianCurrency(variant.priceV2.amount);
    final originalPrice = variant.compareAtPriceV2 != null
        ? formatIndianCurrency(variant.compareAtPriceV2!.amount)
        : '';
    final discount = _discountPercent();

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
        child: Row(
          children: [
            // Price section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        currentPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          originalPrice,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$discount% off',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

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
                    _isInWishlist ? Icons.favorite : Icons.favorite_border,
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
                child: ElevatedButton(
                  onPressed: () {
                    // Buy now action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5C9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Buy now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
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
}
