import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/auth_storage.dart';
import 'order_summary_state.dart';

class OrderSummaryCubit extends Cubit<OrderSummaryState> {
  OrderSummaryCubit() : super(OrderSummaryInitial());

  /// Initialize the screen
  void initialize() {
    emit(OrderSummaryLoading());
    // After initialization, emit loaded state
    emit(const OrderSummaryLoaded());
  }

  /// Toggle showing all products
  void toggleShowAllProducts() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(
        showAllProducts: !currentState.showAllProducts,
      ));
    }
  }

  /// Start refresh
  void startRefresh() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(isRefreshing: true));
    }
  }

  /// End refresh
  void endRefresh() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(isRefreshing: false));
    }
  }

  /// Fetch related products
  Future<void> fetchRelatedProducts(String productId) async {
    if (state is! OrderSummaryLoaded) return;
    
    final currentState = state as OrderSummaryLoaded;
    
    // Don't fetch if already loading
    if (currentState.isLoadingRelatedProducts) return;

    // Start loading
    emit(currentState.copyWith(isLoadingRelatedProducts: true));

    try {
      final products = await ApiService().getRelatedProducts(
        productId: productId,
        limit: 4,
      );

      emit(currentState.copyWith(
        isLoadingRelatedProducts: false,
        relatedProducts: products,
      ));
    } catch (e) {
      AppLogger.error('Error fetching related products: $e');
      emit(currentState.copyWith(isLoadingRelatedProducts: false));
    }
  }

  /// Add product to cart from last minute addition section
  Future<void> addProductToCart(String productId, Map<String, dynamic> product) async {
    if (state is! OrderSummaryLoaded) return;
    
    final currentState = state as OrderSummaryLoaded;
    
    // Don't add if already adding this product
    if (currentState.isAddingToCart(productId)) return;

    try {
      // Start adding to cart - show shimmer
      final updatedAddingIds = Set<String>.from(currentState.addingToCartProductIds);
      updatedAddingIds.add(productId);
      
      emit(currentState.copyWith(addingToCartProductIds: updatedAddingIds));

      // Debug: Log the product data structure
      AppLogger.info('Product data structure: $product');

      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        throw Exception('Cart not found');
      }

      // For related products from recommendations API, we need to get the first variant
      // The structure is different from GraphQL products
      String? variantId;
      
      // Method 1: Check if variants array exists
      if (product['variants'] != null && product['variants'] is List) {
        final variants = product['variants'] as List;
        AppLogger.info('Found variants array with ${variants.length} items');
        
        if (variants.isNotEmpty) {
          final firstVariant = variants.first;
          AppLogger.info('First variant data: $firstVariant');
          
          if (firstVariant is Map) {
            final rawId = firstVariant['id']?.toString();
            if (rawId != null) {
              // Ensure the ID is in proper global ID format
              if (rawId.startsWith('gid://shopify/ProductVariant/')) {
                variantId = rawId;
              } else {
                variantId = 'gid://shopify/ProductVariant/$rawId';
              }
              AppLogger.info('Extracted variant ID from variants array: $variantId');
            }
          }
        }
      }
      
      // Method 2: Check for direct variant_id field
      if (variantId == null && product['variant_id'] != null) {
        final rawId = product['variant_id'].toString();
        // Ensure the ID is in proper global ID format
        if (rawId.startsWith('gid://shopify/ProductVariant/')) {
          variantId = rawId;
        } else {
          variantId = 'gid://shopify/ProductVariant/$rawId';
        }
        AppLogger.info('Extracted variant ID from variant_id field: $variantId');
      }
      
      // Method 3: For Shopify products, fetch the actual product to get the correct variant ID
      if (variantId == null) {
        AppLogger.info('No variant ID found in product data, fetching from Shopify API...');
        
        // Extract numeric product ID - handle both formats
        String numericProductId;
        if (productId.contains('gid://shopify/Product/')) {
          numericProductId = productId.split('/').last;
        } else if (productId.contains('/')) {
          numericProductId = productId.split('/').last;
        } else {
          numericProductId = productId;
        }
        
        // Use the existing getProductById method to get proper variant data
        try {
          final productDetails = await ApiService().getProductById('gid://shopify/Product/$numericProductId');
          
          if (productDetails.variants.isNotEmpty) {
            variantId = productDetails.variants.first.id;
            AppLogger.info('Fetched variant ID from API: $variantId');
          }
        } catch (e) {
          AppLogger.error('Failed to fetch product details: $e');
        }
      }

      if (variantId == null) {
        throw Exception('Could not determine variant ID for this product');
      }

      AppLogger.info('Final variant ID for cart: $variantId');

      // Add to cart via API
      await ApiService().cartLinesAdd(
        cartId: cartId,
        merchandiseId: variantId,
        quantity: 1,
      );

      // Set cart indicator to show dot
      await AuthStorage.setCartHasItems(true);

      AppLogger.success('Product added to cart successfully');

    } catch (e) {
      AppLogger.error('Error adding product to cart: $e');
      rethrow;
    } finally {
      // Stop adding to cart - hide shimmer
      if (state is OrderSummaryLoaded) {
        final currentState = state as OrderSummaryLoaded;
        final updatedAddingIds = Set<String>.from(currentState.addingToCartProductIds);
        updatedAddingIds.remove(productId);
        
        emit(currentState.copyWith(addingToCartProductIds: updatedAddingIds));
      }
    }
  }

  /// Clear related products
  void clearRelatedProducts() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(relatedProducts: []));
    }
  }

  /// Reset to initial loaded state
  void reset() {
    emit(const OrderSummaryLoaded());
  }
}