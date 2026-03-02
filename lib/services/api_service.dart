import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/home_top_banner_model.dart';
import '../models/top_products_model.dart';
import '../models/browse_category_model.dart';
import '../models/discounted_products_model.dart';
import '../models/category_menu_model.dart';
import '../models/filter_model.dart';
import '../models/customer_model.dart';
import '../utils/auth_storage.dart';

/// API Service class
/// This class handles all GraphQL API calls
/// All API endpoints will be added here in a simple and organized way
class ApiService {
  // Using secure config file for access token
  static String get adminAccessToken => ApiConfig.shopifyAdminAccessToken;

  // Callback for token expiration (to navigate to login)
  static Function? onTokenExpired;

  /// Simple continuous logging without decorative boxes
  void _log(String message) {
    debugPrint('🔵 API_LOG: $message');
  }

  /// Logs full response continuously with formatted JSON
  void _logFullResponse(String tag, Map<String, dynamic> responseData) {
    _log('$tag (length: ${jsonEncode(responseData).length})');

    // Format JSON with proper indentation (2 spaces)
    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(responseData);

    // Print formatted JSON line by line for better readability
    _log('📥 Formatted JSON Response:');
    debugPrint('🔵 API_RESPONSE_JSON:');
    formattedJson.split('\n').forEach((line) {
      debugPrint('🔵 $line');
    });
  }

  /// Check if token is expired and handle accordingly
  Future<bool> _validateToken() async {
    final isExpired = await AuthStorage.isTokenExpired();

    if (isExpired) {
      _log('❌ Token expired! Clearing data and triggering logout...');
      await AuthStorage.clearAllData();

      // Trigger callback to navigate to login
      if (onTokenExpired != null) {
        onTokenExpired!();
      }

      return false;
    }

    return true;
  }

  /// Make a GraphQL request
  /// [query] – GraphQL query string. Use \$variableName in the query for variables.
  /// [variables] – optional map of variable names (without \$) to values, e.g. {'handle': 'top-products'}.
  /// [skipTokenValidation] – set to true to skip token validation (e.g., for login)
  Future<Map<String, dynamic>> _makeGraphQLRequest(
    String query, {
    Map<String, dynamic>? variables,
    bool skipTokenValidation = false,
  }) async {
    // Validate token before making request (skip for login/public APIs)
    if (!skipTokenValidation) {
      final isValid = await _validateToken();
      if (!isValid) {
        throw Exception('Token expired. Please login again.');
      }
    }

    try {
      // Log the request continuously
      _log('═══════════════════════════════════════════════════════════');
      _log('📤 API REQUEST START');
      _log('═══════════════════════════════════════════════════════════');
      _log('URL: ${ApiConfig.baseUrl}');
      _log('Query:');
      debugPrint('🔵 API_QUERY: $query');
      if (variables != null && variables.isNotEmpty) {
        _log('Variables: $variables');
      }
      _log('═══════════════════════════════════════════════════════════');

      final body = <String, dynamic>{'query': query};
      if (variables != null && variables.isNotEmpty) {
        body['variables'] = variables;
      }

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': ApiConfig.accessToken,
        },
        body: jsonEncode(body),
      );

      // Log the response status
      _log('═══════════════════════════════════════════════════════════');
      _log('📥 API RESPONSE RECEIVED');
      _log('═══════════════════════════════════════════════════════════');
      _log('Status Code: ${response.statusCode}');

      // Check if request was successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Log full response with formatted JSON
        _logFullResponse('📥 Response Data', responseData);

        // Check for GraphQL errors
        if (responseData['errors'] != null) {
          _log('❌ GraphQL Errors: ${responseData['errors']}');
          throw Exception('GraphQL Error: ${responseData['errors']}');
        }

        _log('═══════════════════════════════════════════════════════════');
        _log('✅ API REQUEST COMPLETED SUCCESSFULLY');
        _log('═══════════════════════════════════════════════════════════');

        return responseData;
      } else {
        _log('❌ HTTP Error: ${response.statusCode}');
        _log('Response Body: ${response.body}');
        _log('═══════════════════════════════════════════════════════════');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _log('═══════════════════════════════════════════════════════════');
      _log('❌ EXCEPTION OCCURRED: $e');
      _log('═══════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Make a GraphQL request to the Admin API
  Future<Map<String, dynamic>> _makeAdminGraphQLRequest(String query) async {
    // Validate token before making request
    final isValid = await _validateToken();
    if (!isValid) {
      throw Exception('Token expired. Please login again.');
    }

    try {
      _log('═══════════════════════════════════════════════════════════');
      _log('📤 ADMIN API REQUEST START');
      _log('═══════════════════════════════════════════════════════════');

      final response = await http.post(
        Uri.parse(ApiConfig.adminBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': adminAccessToken,
        },
        body: jsonEncode({'query': query}),
      );

      _log('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['errors'] != null) {
          _log('❌ GraphQL Errors: ${responseData['errors']}');
          throw Exception('GraphQL Error: ${responseData['errors']}');
        }
        _log('✅ ADMIN API REQUEST COMPLETED SUCCESSFULLY');
        return responseData;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ ADMIN API EXCEPTION: $e');
      rethrow;
    }
  }

  /// Fetch a Shopify menu by its ID (Admin API)
  Future<CategoryMenuResponse> getMenuById(String menuId) async {
    try {
      _log('🚀 Starting to fetch menu: $menuId');

      final query = 'query { menu(id: "$menuId") { id handle title items { id title type url resourceId } } }';

      final responseData = await _makeAdminGraphQLRequest(query);
      final menuResponse = CategoryMenuResponse.fromJson(responseData);

      _log('✅ Successfully fetched menu: ${menuResponse.menu?.title} with ${menuResponse.menu?.items.length ?? 0} items');

      return menuResponse;
    } catch (e) {
      _log('❌ Failed to fetch menu $menuId: $e');
      rethrow;
    }
  }

  /// Fetch all collection handles + image URLs (Storefront API)
  /// Returns a map of handle → imageUrl for matching menu items to images
  Future<Map<String, String>> getAllCollectionImages() async {
    try {
      _log('🚀 Starting to fetch all collection images...');

      const query = '''
        {
          collections(first: 100) {
            edges {
              node {
                handle
                image { src }
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final edges = responseData['data']?['collections']?['edges'] as List<dynamic>? ?? [];

      final imageMap = <String, String>{};
      for (final edge in edges) {
        final node = edge['node'] as Map<String, dynamic>? ?? {};
        final handle = node['handle'] as String? ?? '';
        final imageSrc = node['image']?['src'] as String?;
        if (handle.isNotEmpty && imageSrc != null && imageSrc.isNotEmpty) {
          imageMap[handle] = imageSrc;
        }
      }

      _log('✅ Successfully fetched images for ${imageMap.length} collections');
      return imageMap;
    } catch (e) {
      _log('❌ Failed to fetch collection images: $e');
      rethrow;
    }
  }

  /// Get home top banners
  /// This method fetches all home top banners from the API
  Future<HomeTopBannerResponse> getHomeTopBanners() async {
    try {
      _log('🚀 Starting to fetch home top banners...');

      // GraphQL query
      const query = '''
        {
          metaobjects(type: "home_top_banner", first: 50) {
            edges {
              node {
                id
                handle
                fields {
                  key
                  value
                  reference {
                    __typename
                    ... on MediaImage {
                      image {
                        url
                        altText
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      // Make the API call
      final responseData = await _makeGraphQLRequest(query);

      // Convert response to model
      final bannerResponse = HomeTopBannerResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${bannerResponse.banners.length} banners');

      return bannerResponse;
    } catch (e) {
      _log('❌ Failed to fetch home top banners: $e');
      rethrow;
    }
  }

  /// Get home middle banner(s)
  /// Same structure as top banner, type: "home_middle_banner"
  Future<HomeTopBannerResponse> getHomeMiddleBanners() async {
    try {
      _log('🚀 Starting to fetch home middle banners...');

      const query = '''
        {
          metaobjects(type: "home_middle_banner", first: 50) {
            edges {
              node {
                id
                handle
                fields {
                  key
                  value
                  reference {
                    __typename
                    ... on MediaImage {
                      image {
                        url
                        altText
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final bannerResponse = HomeTopBannerResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${bannerResponse.banners.length} middle banners');

      return bannerResponse;
    } catch (e) {
      _log('❌ Failed to fetch home middle banners: $e');
      rethrow;
    }
  }

  /// Get home bottom banners
  /// Same structure as top/middle banner, type: "home_bottom_banner"
  Future<HomeTopBannerResponse> getHomeBottomBanners() async {
    try {
      _log('🚀 Starting to fetch home bottom banners...');

      const query = '''
        {
          metaobjects(type: "home_bottom_banner", first: 50) {
            edges {
              node {
                id
                handle
                fields {
                  key
                  value
                  reference {
                    __typename
                    ... on MediaImage {
                      image {
                        url
                        altText
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final bannerResponse = HomeTopBannerResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${bannerResponse.banners.length} bottom banners');

      return bannerResponse;
    } catch (e) {
      _log('❌ Failed to fetch home bottom banners: $e');
      rethrow;
    }
  }

  /// Get Skin Genius analyzes
  /// This method hits the same GraphQL endpoint with `skin_genius_analyzes` type
  /// and reuses the same response model because the structure is identical
  Future<HomeTopBannerResponse> getSkinGeniusAnalyzes() async {
    try {
      _log('🚀 Starting to fetch Skin Genius analyzes...');

      // GraphQL query (direct translation of the provided curl)
      const query = '''
        {
          metaobjects(type: "skin_genius_analyzes", first: 10) {
            edges {
              node {
                id
                handle
                fields {
                  key
                  value
                  reference {
                    __typename
                    ... on MediaImage {
                      image {
                        url
                        altText
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      // Make the API call using the common helper
      final responseData = await _makeGraphQLRequest(query);

      // Reuse the same model since the GraphQL shape is the same
      final analyzesResponse = HomeTopBannerResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${analyzesResponse.banners.length} Skin Genius analyzes');

      return analyzesResponse;
    } catch (e) {
      _log('❌ Failed to fetch Skin Genius analyzes: $e');
      rethrow;
    }
  }

  /// Get products collection by handle (e.g. "top-products")
  /// This is a direct translation of the provided GraphQL query, but
  /// the handle is dynamic so it can be reused for multiple tabs.
  Future<TopProductsCollectionResponse> getCollectionByHandle(String handle) async {
    try {
      _log('🚀 Starting to fetch products collection for handle: $handle');

      // Use \$handle so the query contains literal $handle (GraphQL variable), not Dart interpolation
      const query = r'''
        query collectionByHandleQuery($handle: String!) {
          collectionByHandle(handle: $handle) {
            title
            handle
            products(first: 100) {
              edges {
                node {
                  id
                  title
                  description
                  handle
                  images(first: 10) {
                    edges {
                      node {
                        originalSrc
                        altText
                      }
                    }
                  }
                  variants(first: 10) {
                    edges {
                      node {
                        id
                        title
                        sku
                        priceV2 { amount currencyCode }
                        compareAtPriceV2 { amount currencyCode }
                        availableForSale
                      }
                    }
                  }
                  productType
                  vendor
                  tags
                  createdAt
                  updatedAt
                  onlineStoreUrl
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(
        query,
        variables: {'handle': handle},
      );
      final collectionResponse = TopProductsCollectionResponse.fromJson(responseData);

      _log(
        '✅ Successfully fetched ${collectionResponse.collection?.products.length ?? 0} products for handle: $handle',
      );

      return collectionResponse;
    } catch (e) {
      _log('❌ Failed to fetch products collection for handle $handle: $e');
      rethrow;
    }
  }

  /// Get collection products with pagination and sorting support
  /// Used by the category products screen for paginated product listing
  /// [sortKey] – Shopify sort key (e.g. BEST_SELLING, PRICE, TITLE, CREATED_AT, MANUAL)
  /// [reverse] – whether to reverse the sort order
  Future<TopProductsCollectionResponse> getCollectionProducts({
    required String handle,
    int first = 20,
    String? after,
    String? sortKey,
    bool? reverse,
    List<Map<String, dynamic>>? filters,
  }) async {
    try {
      _log(
          '🚀 Starting to fetch collection products for handle: $handle (first: $first, after: $after, sortKey: $sortKey, reverse: $reverse, filters: ${filters?.length ?? 0})');

      const query = r'''
        query collectionProducts($handle: String!, $first: Int!, $after: String, $sortKey: ProductCollectionSortKeys, $reverse: Boolean, $filters: [ProductFilter!]) {
          collectionByHandle(handle: $handle) {
            title
            handle
            products(first: $first, after: $after, sortKey: $sortKey, reverse: $reverse, filters: $filters) {
              edges {
                node {
                  id
                  title
                  description
                  handle
                  images(first: 10) {
                    edges {
                      node {
                        originalSrc
                        altText
                      }
                    }
                  }
                  variants(first: 10) {
                    edges {
                      node {
                        id
                        title
                        sku
                        priceV2 { amount currencyCode }
                        compareAtPriceV2 { amount currencyCode }
                        availableForSale
                      }
                    }
                  }
                  productType
                  vendor
                  tags
                  createdAt
                  updatedAt
                  onlineStoreUrl
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        }
      ''';

      final variables = <String, dynamic>{
        'handle': handle,
        'first': first,
      };
      if (after != null) variables['after'] = after;
      if (sortKey != null) variables['sortKey'] = sortKey;
      if (reverse != null) variables['reverse'] = reverse;
      if (filters != null && filters.isNotEmpty) {
        variables['filters'] = filters;
      }

      final responseData = await _makeGraphQLRequest(query, variables: variables);
      final collectionResponse = TopProductsCollectionResponse.fromJson(responseData);

      _log(
        '✅ Successfully fetched ${collectionResponse.collection?.products.length ?? 0} products for handle: $handle',
      );

      return collectionResponse;
    } catch (e) {
      _log('❌ Failed to fetch collection products for handle $handle: $e');
      rethrow;
    }
  }

  /// Get available filters for a collection
  Future<ShopifyFiltersResponse> getCollectionFilters({
    required String handle,
  }) async {
    try {
      _log('🚀 Starting to fetch filters for collection: $handle');

      const query = r'''
        query collectionFilters($handle: String!) {
          collectionByHandle(handle: $handle) {
            products(first: 1) {
              filters {
                id
                label
                type
                values {
                  id
                  label
                  count
                  input
                }
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(
        query,
        variables: {'handle': handle},
      );

      final filtersResponse = ShopifyFiltersResponse.fromJson(responseData);
      _log(
        '✅ Successfully fetched ${filtersResponse.filters.length} filter categories for handle: $handle',
      );
      return filtersResponse;
    } catch (e) {
      _log('❌ Failed to fetch filters for handle $handle: $e');
      rethrow;
    }
  }

  /// Get brand logos
  /// Same metaobject structure as banners, type: "brand_logo"
  Future<HomeTopBannerResponse> getBrandLogos() async {
    try {
      _log('🚀 Starting to fetch brand logos...');

      const query = '''
        {
          metaobjects(type: "brand_logo", first: 50) {
            edges {
              node {
                id
                handle
                fields {
                  key
                  value
                  reference {
                    __typename
                    ... on MediaImage {
                      image {
                        url
                        altText
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final brandResponse = HomeTopBannerResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${brandResponse.banners.length} brand logos');

      return brandResponse;
    } catch (e) {
      _log('❌ Failed to fetch brand logos: $e');
      rethrow;
    }
  }

  /// Get all products with pagination support
  /// Used by category products screen for discounted products listing
  Future<DiscountedProductsResponse> getAllProducts({
    int first = 100,
    String? after,
  }) async {
    try {
      _log('🚀 Starting to fetch all products (first: $first, after: $after)');

      const query = r'''
        query allProducts($first: Int!, $after: String) {
          products(first: $first, after: $after) {
            edges {
              node {
                id
                title
                description
                handle
                images(first: 10) {
                  edges {
                    node {
                      originalSrc
                      altText
                    }
                  }
                }
                variants(first: 10) {
                  edges {
                    node {
                      id
                      title
                      sku
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      availableForSale
                    }
                  }
                }
                productType
                vendor
                tags
                createdAt
                updatedAt
                onlineStoreUrl
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      ''';

      final variables = <String, dynamic>{'first': first};
      if (after != null) variables['after'] = after;

      final responseData = await _makeGraphQLRequest(query, variables: variables);
      final response = DiscountedProductsResponse.fromJson(responseData);

      _log(
        '✅ Successfully fetched ${response.products.length} products',
      );

      return response;
    } catch (e) {
      _log('❌ Failed to fetch all products: $e');
      rethrow;
    }
  }

  /// Get all products and filter to only those with a compareAtPrice (discounted)
  Future<DiscountedProductsResponse> getDiscountedProducts() async {
    try {
      _log('🚀 Starting to fetch discounted products...');

      const query = '''
        {
          products(first: 30) {
            edges {
              node {
                id
                title
                description
                handle
                images(first: 10) {
                  edges {
                    node {
                      originalSrc
                      altText
                    }
                  }
                }
                variants(first: 10) {
                  edges {
                    node {
                      id
                      title
                      sku
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      availableForSale
                    }
                  }
                }
                productType
                vendor
                tags
                createdAt
                updatedAt
                onlineStoreUrl
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final response = DiscountedProductsResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${response.products.length} products (before discount filter)');

      return response;
    } catch (e) {
      _log('❌ Failed to fetch discounted products: $e');
      rethrow;
    }
  }

  /// Fetch a single product by its Shopify GID using the Admin REST API
  /// Falls back to this when the TopProduct object is missing images or description
  Future<TopProduct> getProductById(String productId) async {
    try {
      // Extract numeric ID from Shopify GID (e.g. "gid://shopify/Product/8595686588594" → "8595686588594")
      final numericId = productId.contains('/') ? productId.split('/').last : productId;
      _log('🚀 Starting to fetch product by ID: $numericId');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$numericId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': adminAccessToken,
        },
      );

      _log('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final productsJson = responseData['products'] as List<dynamic>? ?? [];

        if (productsJson.isEmpty) {
          throw Exception('Product not found');
        }

        final productJson = productsJson.first as Map<String, dynamic>;

        // Parse Admin REST API format into TopProduct
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

        final product = TopProduct(
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

        _log('✅ Successfully fetched product: ${product.title}');
        return product;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to fetch product by ID: $e');
      rethrow;
    }
  }

  /// Fetch product specifications (weight, quantity, options, etc.) from Admin API
  /// Returns additional product details not available in the Storefront API
  Future<Map<String, dynamic>> getProductSpecifications(String productId) async {
    try {
      // Extract numeric ID from Shopify GID
      final numericId = productId.contains('/') ? productId.split('/').last : productId;
      _log('🚀 Fetching product specifications for ID: $numericId');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$numericId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': adminAccessToken,
        },
      );

      _log('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final productsJson = responseData['products'] as List<dynamic>? ?? [];

        if (productsJson.isEmpty) {
          throw Exception('Product not found');
        }

        final productJson = productsJson.first as Map<String, dynamic>;

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

        _log('✅ Successfully fetched product specifications');
        return specifications;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to fetch product specifications: $e');
      rethrow;
    }
  }

  /// Get collections for \"Browse by categories\" section
  /// Direct translation of the provided collections GraphQL query
  Future<BrowseCategoriesResponse> getBrowseCategories() async {
    try {
      _log('🚀 Starting to fetch browse categories...');

      const query = '''
        {
          collections(first: 50) {
            edges {
              node {
                id
                handle
                title
                description
                image { src }
                metafield(namespace: "custom", key: "mobile_category") {
                  value
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final categoriesResponse = BrowseCategoriesResponse.fromJson(responseData);

      _log('✅ Successfully fetched ${categoriesResponse.categories.length} browse categories');

      return categoriesResponse;
    } catch (e) {
      _log('❌ Failed to fetch browse categories: $e');
      rethrow;
    }
  }

  /// Search products by query term
  /// This method searches products using the Shopify search query
  Future<DiscountedProductsResponse> searchProducts(String searchTerm, {int first = 20, String? cursor}) async {
    try {
      _log('🚀 Starting to search products with term: $searchTerm');

      final query = cursor == null
          ? '''
        {
          products(first: $first, query: "$searchTerm") {
            edges {
              node {
                id
                title
                description
                handle
                images(first: 10) {
                  edges {
                    node {
                      originalSrc
                      altText
                    }
                  }
                }
                variants(first: 10) {
                  edges {
                    node {
                      id
                      title
                      sku
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      availableForSale
                    }
                  }
                }
                productType
                vendor
                tags
                createdAt
                updatedAt
                onlineStoreUrl
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      '''
          : '''
        {
          products(first: $first, query: "$searchTerm", after: "$cursor") {
            edges {
              node {
                id
                title
                description
                handle
                images(first: 10) {
                  edges {
                    node {
                      originalSrc
                      altText
                    }
                  }
                }
                variants(first: 10) {
                  edges {
                    node {
                      id
                      title
                      sku
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      availableForSale
                    }
                  }
                }
                productType
                vendor
                tags
                createdAt
                updatedAt
                onlineStoreUrl
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(query);
      final searchResponse = DiscountedProductsResponse.fromJson(responseData);

      _log('✅ Successfully searched products: ${searchResponse.products.length} results');

      return searchResponse;
    } catch (e) {
      _log('❌ Failed to search products: $e');
      rethrow;
    }
  }

  /// Fetch products from a collection by collection ID
  /// Used for discover/related products section
  Future<List<TopProduct>> getCollectionProductsById(String collectionId) async {
    try {
      _log('🚀 Starting to fetch collection products for ID: $collectionId');

      const query = '''
        query getCollectionWithProducts(\$id: ID!) {
          collection(id: \$id) {
            id
            title
            products(first: 50) {
              edges {
                node {
                  id
                  handle
                  title
                  description
                  featuredImage {
                    url
                    altText
                  }
                  images(first: 10) {
                    edges {
                      node {
                        originalSrc
                        altText
                      }
                    }
                  }
                  variants(first: 10) {
                    edges {
                      node {
                        id
                        title
                        sku
                        priceV2 { amount currencyCode }
                        compareAtPriceV2 { amount currencyCode }
                        availableForSale
                      }
                    }
                  }
                  productType
                  vendor
                  tags
                  createdAt
                  updatedAt
                  onlineStoreUrl
                }
              }
            }
          }
        }
      ''';

      final variables = {'id': collectionId};
      final responseData = await _makeGraphQLRequest(query, variables: variables);

      // Parse the response
      final collection = responseData['data']?['collection'];
      if (collection == null) {
        _log('⚠️ No collection found for ID: $collectionId');
        return [];
      }

      final productsData = collection['products']?['edges'] as List<dynamic>? ?? [];
      final products = productsData.map((edge) {
        final node = edge['node'] as Map<String, dynamic>;
        return TopProduct.fromJson(node);
      }).toList();

      _log('✅ Successfully fetched ${products.length} products from collection');

      return products;
    } catch (e) {
      _log('❌ Failed to fetch collection products: $e');
      rethrow;
    }
  }

  /// Customer login with email and password
  /// Returns access token and expiry date
  Future<Map<String, dynamic>> customerLogin({
    required String email,
    required String password,
  }) async {
    try {
      _log('🚀 Starting customer login for email: $email');

      const query = '''
        mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
          customerAccessTokenCreate(input: \$input) {
            customerAccessToken {
              accessToken
              expiresAt
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'input': {
          'email': email,
          'password': password,
        }
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: true, // Skip token validation for login
      );

      // Check for user errors
      final customerAccessTokenCreate = responseData['data']?['customerAccessTokenCreate'];
      final userErrors = customerAccessTokenCreate?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Login failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAccessToken = customerAccessTokenCreate?['customerAccessToken'];
      if (customerAccessToken == null) {
        _log('❌ No access token received');
        throw Exception('Login failed: No access token received');
      }

      _log('✅ Successfully logged in');

      return {
        'accessToken': customerAccessToken['accessToken'],
        'expiresAt': customerAccessToken['expiresAt'],
      };
    } catch (e) {
      _log('❌ Failed to login: $e');
      rethrow;
    }
  }

  /// Create a new cart and return cart ID
  /// This mutation creates a new Shopify cart
  Future<String> cartCreate() async {
    try {
      _log('🚀 Starting to create new cart...');

      const query = '''
        mutation {
          cartCreate {
            cart {
              id
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final responseData = await _makeGraphQLRequest(
        query,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartCreate = responseData['data']?['cartCreate'];
      final userErrors = cartCreate?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Cart creation failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartCreate?['cart'];
      if (cart == null || cart['id'] == null) {
        _log('❌ No cart ID received');
        throw Exception('Cart creation failed: No cart ID received');
      }

      final cartId = cart['id'] as String;
      _log('✅ Successfully created cart with ID: $cartId');

      return cartId;
    } catch (e) {
      _log('❌ Failed to create cart: $e');
      rethrow;
    }
  }

  /// Get or create cart ID
  /// Checks if cart ID exists in preferences, if not creates a new one
  /// This should be called after successful login when token is valid
  Future<String> getOrCreateCartId() async {
    try {
      _log('🛒 Checking for existing cart ID...');

      // Check if cart ID already exists in preferences
      final existingCartId = await AuthStorage.getCartId();

      if (existingCartId != null && existingCartId.isNotEmpty) {
        _log('✅ Using existing cart ID: $existingCartId');
        return existingCartId;
      }

      // No cart ID exists, create a new one
      _log('📝 No cart ID found, creating new cart...');
      final newCartId = await cartCreate();

      // Save the new cart ID to preferences
      await AuthStorage.saveCartId(newCartId);

      return newCartId;
    } catch (e) {
      _log('❌ Failed to get or create cart ID: $e');
      rethrow;
    }
  }

  /// Add product to cart
  /// [cartId] - The cart ID to add items to
  /// [merchandiseId] - The variant ID of the product to add
  /// [quantity] - The quantity to add (default: 1)
  Future<Map<String, dynamic>> cartLinesAdd({
    required String cartId,
    required String merchandiseId,
    int quantity = 1,
  }) async {
    try {
      _log('🛒 Adding product to cart...');
      _log('Cart ID: $cartId');
      _log('Merchandise ID: $merchandiseId');
      _log('Quantity: $quantity');

      const query = r'''
        mutation cartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
          cartLinesAdd(cartId: $cartId, lines: $lines) {
            cart {
              id
              lines(first: 10) {
                edges {
                  node {
                    id
                    quantity
                    merchandise {
                      ... on ProductVariant {
                        id
                        title
                      }
                    }
                  }
                }
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'cartId': cartId,
        'lines': [
          {
            'quantity': quantity,
            'merchandiseId': merchandiseId,
          }
        ],
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartLinesAdd = responseData['data']?['cartLinesAdd'];
      final userErrors = cartLinesAdd?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Add to cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesAdd?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Add to cart failed: No cart data received');
      }

      _log('✅ Successfully added product to cart');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to add product to cart: $e');
      rethrow;
    }
  }

  /// Get cart details with all line items
  /// Fetches complete cart information including products, quantities, and pricing
  Future<Map<String, dynamic>> getCart(String cartId) async {
    try {
      _log('🛒 Fetching cart details for ID: $cartId');

      const query = r'''
        query getCart($cartId: ID!) {
          cart(id: $cartId) {
            id
            lines(first: 20) {
              edges {
                node {
                  id
                  quantity
                  attributes {
                    key
                    value
                  }
                  merchandise {
                    ... on ProductVariant {
                      id
                      title
                      sku
                      availableForSale
                      quantityAvailable
                      priceV2 {
                        amount
                        currencyCode
                      }
                      compareAtPriceV2 {
                        amount
                        currencyCode
                      }
                      product {
                        id
                        title
                        handle
                        images(first: 1) {
                          edges {
                            node {
                              url
                              altText
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            cost {
              subtotalAmount {
                amount
                currencyCode
              }
              totalAmount {
                amount
                currencyCode
              }
              totalTaxAmount {
                amount
                currencyCode
              }
              totalDutyAmount {
                amount
                currencyCode
              }
            }
            discountCodes {
              code
              applicable
            }
          }
        }
      ''';

      final variables = {'cartId': cartId};

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      final cart = responseData['data']?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Cart not found');
      }

      _log('✅ Successfully fetched cart details');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to fetch cart: $e');
      rethrow;
    }
  }

  /// Update cart line quantities
  /// [cartId] - The cart ID
  /// [lines] - List of line updates with id and quantity
  Future<Map<String, dynamic>> cartLinesUpdate({
    required String cartId,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      _log('🛒 Updating cart line quantities...');
      _log('Cart ID: $cartId');
      _log('Lines: $lines');

      const query = r'''
        mutation cartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
          cartLinesUpdate(cartId: $cartId, lines: $lines) {
            cart {
              id
              lines(first: 20) {
                edges {
                  node {
                    id
                    quantity
                  }
                }
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'cartId': cartId,
        'lines': lines,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartLinesUpdate = responseData['data']?['cartLinesUpdate'];
      final userErrors = cartLinesUpdate?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Update cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesUpdate?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Update cart failed: No cart data received');
      }

      _log('✅ Successfully updated cart lines');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to update cart lines: $e');
      rethrow;
    }
  }

  /// Remove lines from cart
  /// [cartId] - The cart ID
  /// [lineIds] - List of line IDs to remove
  Future<Map<String, dynamic>> cartLinesRemove({
    required String cartId,
    required List<String> lineIds,
  }) async {
    try {
      _log('🛒 Removing lines from cart...');
      _log('Cart ID: $cartId');
      _log('Line IDs: $lineIds');

      const query = r'''
        mutation cartLinesRemove($cartId: ID!, $lineIds: [ID!]!) {
          cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
            cart {
              id
              lines(first: 10) {
                edges {
                  node {
                    id
                    quantity
                    merchandise {
                      ... on ProductVariant {
                        id
                        title
                      }
                    }
                  }
                }
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'cartId': cartId,
        'lineIds': lineIds,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final cartLinesRemove = responseData['data']?['cartLinesRemove'];
      final userErrors = cartLinesRemove?['userErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Remove from cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesRemove?['cart'];
      if (cart == null) {
        _log('❌ No cart data received');
        throw Exception('Remove from cart failed: No cart data received');
      }

      _log('✅ Successfully removed lines from cart');

      return cart as Map<String, dynamic>;
    } catch (e) {
      _log('❌ Failed to remove lines from cart: $e');
      rethrow;
    }
  }

  /// Get customer details with addresses
  /// [customerAccessToken] - The customer access token
  Future<Customer?> getCustomer(String customerAccessToken) async {
    try {
      _log('👤 Fetching customer details...');
      _log('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');

      const query = r'''
        query getCustomer($customerAccessToken: String!) {
          customer(customerAccessToken: $customerAccessToken) {
            id
            firstName
            lastName
            email
            defaultAddress {
              id
              name
              firstName
              lastName
              address1
              address2
              city
              country
              zip
              company
              province
              phone
            }
            addresses(first: 10) {
              edges {
                node {
                  id
                  name
                  firstName
                  lastName
                  address1
                  address2
                  city
                  country
                  zip
                  company
                  province
                  phone
                }
              }
            }
          }
        }
      ''';

      final variables = {'customerAccessToken': customerAccessToken};

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      final customer = responseData['data']?['customer'];
      if (customer == null) {
        _log('⚠️ No customer data received');
        return null;
      }

      final customerModel = Customer.fromJson(customer);
      _log('✅ Successfully fetched customer details');
      _log('Customer has ${customerModel.addresses.length} addresses');
      _log('Has default address: ${customerModel.defaultAddress != null}');
      _log('Has complete address: ${customerModel.hasCompleteAddress()}');

      return customerModel;
    } catch (e) {
      _log('❌ Failed to fetch customer: $e');
      rethrow;
    }
  }

  /// Delete customer address
  /// [customerAccessToken] - The customer access token
  /// [addressId] - The address ID to delete
  Future<bool> customerAddressDelete({
    required String customerAccessToken,
    required String addressId,
  }) async {
    try {
      _log('🗑️ Deleting customer address...');
      _log('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      _log('Address ID: $addressId');

      const query = r'''
        mutation customerAddressDelete($customerAccessToken: String!, $id: ID!) {
          customerAddressDelete(customerAccessToken: $customerAccessToken, id: $id) {
            deletedCustomerAddressId
            customerUserErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'customerAccessToken': customerAccessToken,
        'id': addressId,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final customerAddressDelete = responseData['data']?['customerAddressDelete'];
      final userErrors = customerAddressDelete?['customerUserErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Delete address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final deletedId = customerAddressDelete?['deletedCustomerAddressId'];
      if (deletedId == null) {
        _log('❌ No deleted address ID received');
        return false;
      }

      _log('✅ Successfully deleted address: $deletedId');
      return true;
    } catch (e) {
      _log('❌ Failed to delete address: $e');
      rethrow;
    }
  }

  /// Create customer address
  /// [customerAccessToken] - The customer access token
  /// [address] - Map containing address fields
  Future<Customer?> customerAddressCreate({
    required String customerAccessToken,
    required Map<String, dynamic> address,
  }) async {
    try {
      _log('📝 Creating customer address...');
      _log('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      _log('Address data: $address');

      const query = r'''
        mutation customerAddressCreate($customerAccessToken: String!, $address: MailingAddressInput!) {
          customerAddressCreate(customerAccessToken: $customerAccessToken, address: $address) {
            customerAddress {
              id
              firstName
              lastName
              address1
              address2
              city
              province
              country
              zip
              phone
              company
            }
            customerUserErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'customerAccessToken': customerAccessToken,
        'address': address,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final customerAddressCreate = responseData['data']?['customerAddressCreate'];
      final userErrors = customerAddressCreate?['customerUserErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Create address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAddress = customerAddressCreate?['customerAddress'];
      if (customerAddress == null) {
        _log('❌ No customer address received');
        throw Exception('Failed to create address');
      }

      _log('✅ Successfully created address: ${customerAddress['id']}');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      _log('❌ Failed to create address: $e');
      rethrow;
    }
  }

  /// Update an existing customer address
  /// [customerAccessToken] - The customer access token
  /// [addressId] - The ID of the address to update
  /// [address] - Map containing updated address fields
  Future<Customer?> customerAddressUpdate({
    required String customerAccessToken,
    required String addressId,
    required Map<String, dynamic> address,
  }) async {
    try {
      _log('📝 Updating customer address...');
      _log('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      _log('Address ID: $addressId');
      _log('Address data: $address');

      const query = r'''
        mutation customerAddressUpdate($customerAccessToken: String!, $id: ID!, $address: MailingAddressInput!) {
          customerAddressUpdate(customerAccessToken: $customerAccessToken, id: $id, address: $address) {
            customerAddress {
              id
              firstName
              lastName
              address1
              address2
              city
              province
              country
              zip
              phone
              company
            }
            customerUserErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'customerAccessToken': customerAccessToken,
        'id': addressId,
        'address': address,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final customerAddressUpdate = responseData['data']?['customerAddressUpdate'];
      final userErrors = customerAddressUpdate?['customerUserErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Update address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAddress = customerAddressUpdate?['customerAddress'];
      if (customerAddress == null) {
        _log('❌ No customer address received');
        throw Exception('Failed to update address');
      }

      _log('✅ Successfully updated address: ${customerAddress['id']}');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      _log('❌ Failed to update address: $e');
      rethrow;
    }
  }

  /// Update customer default address
  /// [customerAccessToken] - The customer access token
  /// [addressId] - The address ID to set as default
  Future<Customer?> customerDefaultAddressUpdate({
    required String customerAccessToken,
    required String addressId,
  }) async {
    try {
      _log('🔄 Updating customer default address...');
      _log('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      _log('Address ID: $addressId');

      const query = r'''
        mutation customerDefaultAddressUpdate($customerAccessToken: String!, $addressId: ID!) {
          customerDefaultAddressUpdate(customerAccessToken: $customerAccessToken, addressId: $addressId) {
            customer {
              id
            }
            customerUserErrors {
              field
              message
            }
          }
        }
      ''';

      final variables = {
        'customerAccessToken': customerAccessToken,
        'addressId': addressId,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: false,
      );

      // Check for user errors
      final customerDefaultAddressUpdate = responseData['data']?['customerDefaultAddressUpdate'];
      final userErrors = customerDefaultAddressUpdate?['customerUserErrors'] as List<dynamic>? ?? [];

      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.map((e) => e['message']).join(', ');
        _log('❌ Update default address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      _log('✅ Successfully updated default address');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      _log('❌ Failed to update default address: $e');
      rethrow;
    }
  }

  /// Get related products recommendations
  /// [productId] - The product ID (numeric ID, not GID)
  /// [limit] - Number of related products to fetch (default: 4)
  Future<List<Map<String, dynamic>>> getRelatedProducts({
    required String productId,
    int limit = 4,
  }) async {
    try {
      // Extract numeric ID if GID is provided
      final numericId = productId.contains('/') ? productId.split('/').last : productId;

      _log('🔗 Fetching related products for product ID: $numericId');

      final url = 'https://glocure.com/recommendations/products.json?product_id=$numericId&intent=related&limit=$limit';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': ApiConfig.accessToken,
        },
      );

      _log('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['products'] != null) {
          final products = responseData['products'] as List<dynamic>;
          _log('✅ Successfully fetched ${products.length} related products');
          return products.cast<Map<String, dynamic>>();
        }

        _log('⚠️ No related products found');
        return [];
      } else {
        _log('❌ HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to fetch related products: $e');
      rethrow;
    }
  }
}
