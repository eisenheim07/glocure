import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/judgeme_product_model.dart';
import '../models/judgeme_reviews_model.dart';
import 'connectivity_service.dart';

/// Judge.me API Service
/// This service handles all Judge.me API calls for product reviews
class JudgemeService {
  // Judge.me API configuration
  static const String _baseUrl = 'https://judge.me/api/v1';
  static const String _shopDomain = 'bxaqgp-p1.myshopify.com';
  static const String _apiToken = 'Ght5-t24nmY0x8e7EYDoyp26ca8';

  /// Simple continuous logging
  void _log(String message) {
    debugPrint('🟡 JUDGEME_API: $message');
  }

  /// Get Judge.me product ID by external product ID (Shopify product ID)
  /// [externalId] - Shopify product ID (e.g., "8595686588594")
  Future<JudgemeProductResponse> getProductByExternalId(String externalId) async {
    // Check internet connectivity first
    final hasConnection = await ConnectivityService().checkConnectivity();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    try {
      _log('🚀 Fetching Judge.me product for external ID: $externalId');

      final url = '$_baseUrl/products/-1?shop_domain=$_shopDomain&api_token=$_apiToken&external_id=$externalId';
      
      _log('📤 Request URL: $url');

      final response = await http.get(Uri.parse(url));

      _log('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        _log('📥 Response Data: ${jsonEncode(responseData)}');

        final productResponse = JudgemeProductResponse.fromJson(responseData);
        
        _log('✅ Successfully fetched Judge.me product: ${productResponse.product?.name}');
        
        return productResponse;
      } else {
        _log('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch product reviews: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Exception occurred: $e');
      rethrow;
    }
  }

  /// Get product reviews by Judge.me product ID
  /// [productId] - Judge.me product ID (from getProductByExternalId response)
  /// [page] - Page number for pagination (default: 1)
  /// [limit] - Number of reviews per page (default: 10)
  Future<JudgemeReviewsResponse> getProductReviews({
    required int productId,
    int page = 1,
    int limit = 10,
  }) async {
    // Check internet connectivity first
    final hasConnection = await ConnectivityService().checkConnectivity();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    try {
      _log('🚀 Fetching reviews for product ID: $productId (page: $page, limit: $limit)');

      final url = '$_baseUrl/reviews?shop_domain=$_shopDomain&api_token=$_apiToken&product_id=$productId&limit=$limit&page=$page';
      
      _log('📤 Request URL: $url');

      final response = await http.get(Uri.parse(url));

      _log('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        _log('📥 Response Data Length: ${jsonEncode(responseData).length}');

        final reviewsResponse = JudgemeReviewsResponse.fromJson(responseData);
        
        _log('✅ Successfully fetched ${reviewsResponse.reviews.length} reviews (page $page/${reviewsResponse.meta.totalPages})');
        
        return reviewsResponse;
      } else {
        _log('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Exception occurred: $e');
      rethrow;
    }
  }

  /// Get product reviews with automatic product ID resolution
  /// [externalId] - Shopify product ID
  /// [page] - Page number for pagination (default: 1)
  /// [limit] - Number of reviews per page (default: 10)
  Future<JudgemeReviewsResponse> getReviewsByExternalId({
    required String externalId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      _log('🚀 Getting reviews for external ID: $externalId');

      // First, get the Judge.me product ID
      final productResponse = await getProductByExternalId(externalId);
      
      if (productResponse.product == null) {
        _log('❌ No Judge.me product found for external ID: $externalId');
        // Return empty response if product not found
        return JudgemeReviewsResponse(
          reviews: [],
          meta: JudgemeReviewsMeta(
            currentPage: 1,
            totalPages: 1,
            totalCount: 0,
            perPage: limit,
          ),
        );
      }

      // Then, get the reviews using the Judge.me product ID
      final reviewsResponse = await getProductReviews(
        productId: productResponse.product!.id,
        page: page,
        limit: limit,
      );

      _log('✅ Successfully fetched reviews for external ID: $externalId');
      
      return reviewsResponse;
    } catch (e) {
      _log('❌ Failed to get reviews for external ID $externalId: $e');
      rethrow;
    }
  }
}