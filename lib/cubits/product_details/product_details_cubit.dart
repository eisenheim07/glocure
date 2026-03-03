import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/top_products_model.dart';
import '../../utils/wishlist_storage.dart';
import '../../models/wishlist_item_model.dart';
import '../../utils/app_logger.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit() : super(ProductDetailsInitial());

  /// Initialize product details with either product object or product ID
  Future<void> initializeProduct({
    TopProduct? product,
    String? productId,
    String? handle,
  }) async {
    emit(ProductDetailsLoading());

    try {
      // Determine the product ID to use
      String productIdToFetch;
      if (productId != null) {
        // Case 2: Use provided product ID
        productIdToFetch = productId;
      } else if (product != null) {
        // Case 1: Extract numeric ID from existing product's Shopify GID
        productIdToFetch = product.id.contains('/') ? product.id.split('/').last : product.id;
      } else {
        throw Exception('No product ID available');
      }

      AppLogger.api('Fetching complete product details for ID: $productIdToFetch');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$productIdToFetch';
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

          // Create product object from API data
          final fetchedProduct = TopProduct(
            id: 'gid://shopify/Product/${productJson['id']}',
            title: productJson['title'] ?? '',
            description: productJson['body_html'] ?? '',
            handle: productJson['handle'] ?? '',
            images: images,
            variants: variants,
            productType: productJson['product_type'] ?? '',
            vendor: productJson['vendor'] ?? '',
            tags: (productJson['tags'] as String? ?? '').split(', ').where((t) => t.isNotEmpty).toList(),
            createdAt: productJson['created_at'] ?? '',
            updatedAt: productJson['updated_at'] ?? '',
            onlineStoreUrl: null,
          );

          // Emit loaded state with fetched product
          emit(ProductDetailsLoaded(
            product: fetchedProduct,
            specifications: specifications,
            isInWishlist: false,
            isCheckingWishlist: false,
            currentImageIndex: 0,
            selectedVariantIndex: 0,
          ));

          // Check wishlist status after product is loaded
          await checkWishlistStatus();

          AppLogger.success('Successfully fetched complete product details from API');
          return;
        }
      }

      // API call failed or returned no data
      throw Exception('Product not found or API error');
      
    } catch (e) {
      AppLogger.error('Error fetching product details: $e');
      
      // Case 1: Product object available → Use fallback data
      if (product != null) {
        AppLogger.warning('Using fallback product object due to API error');
        emit(ProductDetailsLoaded(
          product: product,
          specifications: null,
          isInWishlist: false,
          isCheckingWishlist: false,
          currentImageIndex: 0,
          selectedVariantIndex: 0,
        ));
        // Check wishlist status with fallback data
        await checkWishlistStatus();
      } 
      // Case 2: Only product ID provided → Show error
      else {
        AppLogger.error('No fallback data available, showing error');
        emit(ProductDetailsError(
          message: e.toString(),
          hasProductFallback: false,
        ));
      }
    }
  }

  /// Check if product is in wishlist
  Future<void> checkWishlistStatus() async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;

    // Set checking state
    emit(currentState.copyWith(isCheckingWishlist: true));
    
    try {
      final isInWishlist = await WishlistStorage.isInWishlist(currentState.product.id);
      emit(currentState.copyWith(
        isInWishlist: isInWishlist,
        isCheckingWishlist: false,
      ));
    } catch (e) {
      AppLogger.error('Error checking wishlist status: $e');
      emit(currentState.copyWith(isCheckingWishlist: false));
    }
  }

  /// Toggle wishlist status
  Future<void> toggleWishlist(String? handle) async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;

    try {
      if (currentState.isInWishlist) {
        // Remove from wishlist
        final success = await WishlistStorage.removeFromWishlist(currentState.product.id);
        if (success) {
          emit(currentState.copyWith(isInWishlist: false));
        }
      } else {
        // Add to wishlist
        final variant = currentState.product.variants.isNotEmpty 
            ? currentState.product.variants[currentState.selectedVariantIndex] 
            : null;
        
        if (variant == null) return;

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
          productId: currentState.product.id,
          variantId: variant.id,
          productHandle: currentState.product.handle,
          mainHandle: handle ?? 'top-products',
          title: currentState.product.title,
          price: variant.priceV2.amount,
          discountedPrice: variant.compareAtPriceV2?.amount,
          discountPercent: discountPercent,
          imageUrl: currentState.product.images.isNotEmpty ? currentState.product.images[0].originalSrc : null,
          addedAt: DateTime.now(),
        );

        final success = await WishlistStorage.addToWishlist(wishlistItem);
        if (success) {
          emit(currentState.copyWith(isInWishlist: true));
        }
      }
    } catch (e) {
      AppLogger.error('Error toggling wishlist: $e');
    }
  }

  /// Update current image index
  void updateImageIndex(int index) {
    final currentState = state;
    if (currentState is ProductDetailsLoaded) {
      emit(currentState.copyWith(currentImageIndex: index));
    }
  }

  /// Update selected variant index
  void updateVariantIndex(int index) {
    final currentState = state;
    if (currentState is ProductDetailsLoaded) {
      emit(currentState.copyWith(selectedVariantIndex: index));
    }
  }
}