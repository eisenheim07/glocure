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
import '../models/page_model.dart';
import '../models/shopify_order_model.dart';
import '../utils/auth_storage.dart';
import '../utils/app_logger.dart';
import 'connectivity_service.dart';

/// API Service class
/// This class handles all GraphQL API calls
/// All API endpoints will be added here in a simple and organized way
class ApiService {
  // Using secure config file for access token
  static String get adminAccessToken => ApiConfig.shopifyAdminAccessToken;

  // Callback for token expiration (to navigate to login)
  static Function? onTokenExpired;

  /// Check if token is expired and handle accordingly
  Future<bool> _validateToken() async {
    final isExpired = await AuthStorage.isTokenExpired();

    if (isExpired) {
      AppLogger.warning('Token expired! Clearing data and triggering logout...');
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
    // Check internet connectivity first
    final hasConnection = await ConnectivityService().checkConnectivity();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Validate token before making request (skip for login/public APIs)
    if (!skipTokenValidation) {
      final isValid = await _validateToken();
      if (!isValid) {
        throw Exception('Token expired. Please login again.');
      }
    }

    try {
      // Log the request
      AppLogger.apiRequest(
        method: 'GraphQL',
        url: ApiConfig.baseUrl,
        body: {'query': query},
        variables: variables,
      );

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

      // Check if request was successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check for GraphQL errors
        if (responseData['errors'] != null) {
          AppLogger.apiResponse(
            statusCode: response.statusCode,
            method: 'GraphQL',
            error: 'GraphQL Error: ${responseData['errors']}',
          );
          throw Exception('GraphQL Error: ${responseData['errors']}');
        }

        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'GraphQL',
          responseData: responseData,
        );

        return responseData;
      } else {
        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'GraphQL',
          error: 'HTTP Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('GraphQL request exception: $e');
      rethrow;
    }
  }

  /// Make a GraphQL request to the Admin API
  Future<Map<String, dynamic>> _makeAdminGraphQLRequest(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    // Check internet connectivity first
    final hasConnection = await ConnectivityService().checkConnectivity();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Validate token before making request
    final isValid = await _validateToken();
    if (!isValid) {
      throw Exception('Token expired. Please login again.');
    }

    try {
      AppLogger.apiRequest(
        method: 'Admin GraphQL',
        url: ApiConfig.adminBaseUrl,
        body: {'query': query},
        variables: variables,
      );

      final body = <String, dynamic>{'query': query};
      if (variables != null && variables.isNotEmpty) {
        body['variables'] = variables;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.adminBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': adminAccessToken,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['errors'] != null) {
          AppLogger.apiResponse(
            statusCode: response.statusCode,
            method: 'Admin GraphQL',
            error: 'GraphQL Error: ${responseData['errors']}',
          );
          throw Exception('GraphQL Error: ${responseData['errors']}');
        }

        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'Admin GraphQL',
          responseData: responseData,
        );

        return responseData;
      } else {
        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'Admin GraphQL',
          error: 'HTTP Error: ${response.statusCode}',
        );
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Admin GraphQL request exception: $e');
      rethrow;
    }
  }

  /// Fetch a Shopify menu by its ID (Admin API)
  Future<CategoryMenuResponse> getMenuById(String menuId) async {
    try {
      AppLogger.api('🚀 Starting to fetch menu: $menuId');

      final query = 'query { menu(id: "$menuId") { id handle title items { id title type url resourceId } } }';

      final responseData = await _makeAdminGraphQLRequest(query);
      final menuResponse = CategoryMenuResponse.fromJson(responseData);

      AppLogger.success('Successfully fetched menu: ${menuResponse.menu?.title} with ${menuResponse.menu?.items.length ?? 0} items');

      return menuResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch menu $menuId: $e');
      rethrow;
    }
  }

  /// Fetch all collection handles + image URLs (Storefront API)
  /// Returns a map of handle → imageUrl for matching menu items to images
  Future<Map<String, String>> getAllCollectionImages() async {
    try {
      AppLogger.api('🚀 Starting to fetch all collection images...');

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

      AppLogger.success('Successfully fetched images for ${imageMap.length} collections');
      return imageMap;
    } catch (e) {
      AppLogger.error('Failed to fetch collection images: $e');
      rethrow;
    }
  }

  /// Get home top banners
  /// This method fetches all home top banners from the API
  Future<HomeTopBannerResponse> getHomeTopBanners() async {
    try {
      AppLogger.api('🚀 Starting to fetch home top banners...');

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

      AppLogger.success('Successfully fetched ${bannerResponse.banners.length} banners');

      return bannerResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch home top banners: $e');
      rethrow;
    }
  }

  /// Get home middle banner(s)
  /// Same structure as top banner, type: "home_middle_banner"
  Future<HomeTopBannerResponse> getHomeMiddleBanners() async {
    try {
      AppLogger.api('Starting to fetch home middle banners...');

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

      AppLogger.success('Successfully fetched ${bannerResponse.banners.length} middle banners');

      return bannerResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch home middle banners: $e');
      rethrow;
    }
  }

  /// Get home bottom banners
  /// Same structure as top/middle banner, type: "home_bottom_banner"
  Future<HomeTopBannerResponse> getHomeBottomBanners() async {
    try {
      AppLogger.api('Starting to fetch home bottom banners...');

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

      AppLogger.success('Successfully fetched ${bannerResponse.banners.length} bottom banners');

      return bannerResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch home bottom banners: $e');
      rethrow;
    }
  }

  /// Get Skin Genius analyzes
  /// This method hits the same GraphQL endpoint with `skin_genius_analyzes` type
  /// and reuses the same response model because the structure is identical
  Future<HomeTopBannerResponse> getSkinGeniusAnalyzes() async {
    try {
      AppLogger.api('Starting to fetch Skin Genius analyzes...');

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

      AppLogger.success('Successfully fetched ${analyzesResponse.banners.length} Skin Genius analyzes');

      return analyzesResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch Skin Genius analyzes: $e');
      rethrow;
    }
  }

  /// Get products collection by handle (e.g. "top-products")
  /// This is a direct translation of the provided GraphQL query, but
  /// the handle is dynamic so it can be reused for multiple tabs.
  Future<TopProductsCollectionResponse> getCollectionByHandle(String handle) async {
    try {
      AppLogger.api('Starting to fetch products collection for handle: $handle');

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

      AppLogger.success(
        'Successfully fetched ${collectionResponse.collection?.products.length ?? 0} products for handle: $handle',
      );

      return collectionResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch products collection for handle $handle: $e');
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
      AppLogger.api(
          'Starting to fetch collection products for handle: $handle (first: $first, after: $after, sortKey: $sortKey, reverse: $reverse, filters: ${filters?.length ?? 0})');

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

      AppLogger.success(
        'Successfully fetched ${collectionResponse.collection?.products.length ?? 0} products for handle: $handle',
      );

      return collectionResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch collection products for handle $handle: $e');
      rethrow;
    }
  }

  /// Get available filters for a collection
  Future<ShopifyFiltersResponse> getCollectionFilters({
    required String handle,
  }) async {
    try {
      AppLogger.api('Starting to fetch filters for collection: $handle');

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
      AppLogger.success(
        'Successfully fetched ${filtersResponse.filters.length} filter categories for handle: $handle',
      );
      return filtersResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch filters for handle $handle: $e');
      rethrow;
    }
  }

  /// Get brand logos
  /// Same metaobject structure as banners, type: "brand_logo"
  Future<HomeTopBannerResponse> getBrandLogos() async {
    try {
      AppLogger.api('Starting to fetch brand logos...');

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

      AppLogger.success('Successfully fetched ${brandResponse.banners.length} brand logos');

      return brandResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch brand logos: $e');
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
      AppLogger.api('Starting to fetch all products (first: $first, after: $after)');

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

      AppLogger.success(
        'Successfully fetched ${response.products.length} products',
      );

      return response;
    } catch (e) {
      AppLogger.error('Failed to fetch all products: $e');
      rethrow;
    }
  }

  /// Get all products and filter to only those with a compareAtPrice (discounted)
  Future<DiscountedProductsResponse> getDiscountedProducts() async {
    try {
      AppLogger.api('Starting to fetch discounted products...');

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

      AppLogger.success('Successfully fetched ${response.products.length} products (before discount filter)');

      return response;
    } catch (e) {
      AppLogger.error('Failed to fetch discounted products: $e');
      rethrow;
    }
  }

  /// Fetch a single product by its Shopify GID using the Admin REST API
  /// Falls back to this when the TopProduct object is missing images or description
  Future<TopProduct> getProductById(String productId) async {
    try {
      // Extract numeric ID from Shopify GID (e.g. "gid://shopify/Product/8595686588594" → "8595686588594")
      final numericId = productId.contains('/') ? productId.split('/').last : productId;
      AppLogger.api('Starting to fetch product by ID: $numericId');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$numericId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': adminAccessToken,
        },
      );

      AppLogger.info('getProductById Status Code: ${response.statusCode}');

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

        AppLogger.success('Successfully fetched product: ${product.title}');
        return product;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch product by ID: $e');
      rethrow;
    }
  }

  /// Fetch product specifications (weight, quantity, options, etc.) from Admin API
  /// Returns additional product details not available in the Storefront API
  Future<Map<String, dynamic>> getProductSpecifications(String productId) async {
    try {
      // Extract numeric ID from Shopify GID
      final numericId = productId.contains('/') ? productId.split('/').last : productId;
      AppLogger.api('Fetching product specifications for ID: $numericId');

      final url = 'https://glocure.com/admin/api/2025-10/products.json?ids=$numericId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': adminAccessToken,
        },
      );

      AppLogger.info('getProductSpecifications Status Code: ${response.statusCode}');

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

        AppLogger.success('Successfully fetched product specifications');
        return specifications;
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch product specifications: $e');
      rethrow;
    }
  }

  /// Get collections for \"Browse by categories\" section
  /// Direct translation of the provided collections GraphQL query
  Future<BrowseCategoriesResponse> getBrowseCategories() async {
    try {
      AppLogger.api('Starting to fetch browse categories...');

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

      AppLogger.success('Successfully fetched ${categoriesResponse.categories.length} browse categories');

      return categoriesResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch browse categories: $e');
      rethrow;
    }
  }

  /// Search products by query term
  /// This method searches products using the Shopify search query
  Future<DiscountedProductsResponse> searchProducts(String searchTerm, {int first = 20, String? cursor}) async {
    try {
      AppLogger.api('Starting to search products with term: $searchTerm');

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

      AppLogger.success('Successfully searched products: ${searchResponse.products.length} results');

      return searchResponse;
    } catch (e) {
      AppLogger.error('Failed to search products: $e');
      rethrow;
    }
  }

  /// Fetch products from a collection by collection ID
  /// Used for discover/related products section
  Future<List<TopProduct>> getCollectionProductsById(String collectionId) async {
    try {
      AppLogger.api('Starting to fetch collection products for ID: $collectionId');

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
        AppLogger.warning('No collection found for ID: $collectionId');
        return [];
      }

      final productsData = collection['products']?['edges'] as List<dynamic>? ?? [];
      final products = productsData.map((edge) {
        final node = edge['node'] as Map<String, dynamic>;
        return TopProduct.fromJson(node);
      }).toList();

      AppLogger.success('Successfully fetched ${products.length} products from collection');

      return products;
    } catch (e) {
      AppLogger.error('Failed to fetch collection products: $e');
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
      AppLogger.api('Starting customer login for email: $email');

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
        AppLogger.error('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAccessToken = customerAccessTokenCreate?['customerAccessToken'];
      if (customerAccessToken == null) {
        AppLogger.error('No access token received');
        throw Exception('Login failed: No access token received');
      }

      AppLogger.success('Successfully logged in');

      return {
        'accessToken': customerAccessToken['accessToken'],
        'expiresAt': customerAccessToken['expiresAt'],
      };
    } catch (e) {
      AppLogger.error('Failed to login: $e');
      rethrow;
    }
  }

  /// Create a new cart and return cart ID
  /// This mutation creates a new Shopify cart
  Future<String> cartCreate() async {
    try {
      AppLogger.api('Starting to create new cart...');

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
        AppLogger.error('Cart creation failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartCreate?['cart'];
      if (cart == null || cart['id'] == null) {
        AppLogger.error('No cart ID received');
        throw Exception('Cart creation failed: No cart ID received');
      }

      final cartId = cart['id'] as String;
      AppLogger.success('Successfully created cart with ID: $cartId');

      return cartId;
    } catch (e) {
      AppLogger.error('Failed to create cart: $e');
      rethrow;
    }
  }

  /// Get or create cart ID
  /// Checks if cart ID exists in preferences, if not creates a new one
  /// This should be called after successful login when token is valid
  Future<String> getOrCreateCartId() async {
    try {
      AppLogger.info('Checking for existing cart ID...');

      // Check if cart ID already exists in preferences
      final existingCartId = await AuthStorage.getCartId();

      if (existingCartId != null && existingCartId.isNotEmpty) {
        AppLogger.success('Using existing cart ID: $existingCartId');
        return existingCartId;
      }

      // No cart ID exists, create a new one
      AppLogger.info('No cart ID found, creating new cart...');
      final newCartId = await cartCreate();

      // Save the new cart ID to preferences
      await AuthStorage.saveCartId(newCartId);

      return newCartId;
    } catch (e) {
      AppLogger.error('Failed to get or create cart ID: $e');
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
      AppLogger.info('Adding product to cart...');
      AppLogger.info('Cart ID: $cartId');
      AppLogger.info('Merchandise ID: $merchandiseId');
      AppLogger.info('Quantity: $quantity');

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
        AppLogger.error('Add to cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesAdd?['cart'];
      if (cart == null) {
        AppLogger.error('No cart data received');
        throw Exception('Add to cart failed: No cart data received');
      }

      AppLogger.success('Successfully added product to cart');

      return cart as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to add product to cart: $e');
      rethrow;
    }
  }

  /// Get cart details with all line items
  /// Fetches complete cart information including products, quantities, and pricing
  Future<Map<String, dynamic>> getCart(String cartId) async {
    try {
      AppLogger.info('Fetching cart details for ID: $cartId');

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
        AppLogger.error('No cart data received');
        throw Exception('Cart not found');
      }

      AppLogger.success('Successfully fetched cart details');

      return cart as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch cart: $e');
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
      AppLogger.info('Updating cart line quantities...');
      AppLogger.info('Cart ID: $cartId');
      AppLogger.info('Lines: $lines');

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
        AppLogger.error('Update cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesUpdate?['cart'];
      if (cart == null) {
        AppLogger.error('No cart data received');
        throw Exception('Update cart failed: No cart data received');
      }

      AppLogger.success('Successfully updated cart lines');

      return cart as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to update cart lines: $e');
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
      AppLogger.info('Removing lines from cart...');
      AppLogger.info('Cart ID: $cartId');
      AppLogger.info('Line IDs: $lineIds');

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
        AppLogger.error('Remove from cart failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final cart = cartLinesRemove?['cart'];
      if (cart == null) {
        AppLogger.error('No cart data received');
        throw Exception('Remove from cart failed: No cart data received');
      }

      AppLogger.success('Successfully removed lines from cart');

      return cart as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to remove lines from cart: $e');
      rethrow;
    }
  }

  /// Get customer details with addresses
  /// [customerAccessToken] - The customer access token
  Future<Customer?> getCustomer(String customerAccessToken) async {
    try {
      AppLogger.api('Fetching customer details...');
      AppLogger.info('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');

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
        AppLogger.warning('No customer data received');
        return null;
      }

      final customerModel = Customer.fromJson(customer);
      
      // Extract and save customer ID for orders API
      if (customerModel.id.isNotEmpty) {
        await AuthStorage.extractAndSaveCustomerId(customerModel.id);
      }
      
      AppLogger.success('Successfully fetched customer details');
      AppLogger.info('Customer has ${customerModel.addresses.length} addresses');
      AppLogger.info('Has default address: ${customerModel.defaultAddress != null}');
      AppLogger.info('Has complete address: ${customerModel.hasCompleteAddress()}');

      return customerModel;
    } catch (e) {
      AppLogger.error('Failed to fetch customer: $e');
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
      AppLogger.api('Deleting customer address...');
      AppLogger.info('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      AppLogger.info('Address ID: $addressId');

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
        AppLogger.error('Delete address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final deletedId = customerAddressDelete?['deletedCustomerAddressId'];
      if (deletedId == null) {
        AppLogger.error('No deleted address ID received');
        return false;
      }

      AppLogger.success('Successfully deleted address: $deletedId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete address: $e');
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
      AppLogger.api('Creating customer address...');
      AppLogger.info('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      AppLogger.info('Address data: $address');

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
        AppLogger.error('Create address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAddress = customerAddressCreate?['customerAddress'];
      if (customerAddress == null) {
        AppLogger.error('No customer address received');
        throw Exception('Failed to create address');
      }

      AppLogger.success('Successfully created address: ${customerAddress['id']}');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      AppLogger.error('Failed to create address: $e');
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
      AppLogger.api('Updating customer address...');
      AppLogger.info('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      AppLogger.info('Address ID: $addressId');
      AppLogger.info('Address data: $address');

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
        AppLogger.error('Update address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      final customerAddress = customerAddressUpdate?['customerAddress'];
      if (customerAddress == null) {
        AppLogger.error('No customer address received');
        throw Exception('Failed to update address');
      }

      AppLogger.success('Successfully updated address: ${customerAddress['id']}');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      AppLogger.error('Failed to update address: $e');
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
      AppLogger.api('Updating customer default address...');
      AppLogger.info('Customer Access Token: ${customerAccessToken.substring(0, 10)}...');
      AppLogger.info('Address ID: $addressId');

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
        AppLogger.error('Update default address failed: $errorMessage');
        throw Exception(errorMessage);
      }

      AppLogger.success('Successfully updated default address');

      // Fetch updated customer data to return
      final updatedCustomer = await getCustomer(customerAccessToken);
      return updatedCustomer;
    } catch (e) {
      AppLogger.error('Failed to update default address: $e');
      rethrow;
    }
  }

  /// Get pages (Privacy Policy, Terms & Conditions, etc.)
  /// Returns a list of pages from Shopify
  Future<PagesResponse> getPages({int first = 50}) async {
    try {
      AppLogger.api('Fetching pages...');

      const query = r'''
        query getPages($first: Int!) {
          pages(first: $first) {
            edges {
              node {
                id
                title
                handle
                body
                bodySummary
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

      final variables = {
        'first': first,
      };

      final responseData = await _makeGraphQLRequest(
        query,
        variables: variables,
        skipTokenValidation: true, // Public API, no token needed
      );

      final pagesResponse = PagesResponse.fromJson(responseData['data']);
      AppLogger.success('Successfully fetched ${pagesResponse.pages.length} pages');

      return pagesResponse;
    } catch (e) {
      AppLogger.error('Failed to fetch pages: $e');
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

      AppLogger.api('Fetching related products for product ID: $numericId');

      final url = 'https://glocure.com/recommendations/products.json?product_id=$numericId&intent=related&limit=$limit';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': ApiConfig.accessToken,
        },
      );

      AppLogger.info('Related products API Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['products'] != null) {
          final products = responseData['products'] as List<dynamic>;
          AppLogger.success('Successfully fetched ${products.length} related products');
          return products.cast<Map<String, dynamic>>();
        }

        AppLogger.warning('No related products found');
        return [];
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch related products: $e');
      rethrow;
    }
  }

  /// Get customer orders from Shopify Admin API (REST)
  Future<List<ShopifyOrder>> getCustomerOrders(String customerId) async {
    AppLogger.info('ApiService: Fetching orders for customer: $customerId');

    try {
      // Use REST API instead of GraphQL for better reliability
      final url = 'https://glocure.com/admin/api/2025-10/orders.json?customer_id=$customerId&status=any&limit=50';
      
      AppLogger.apiRequest(
        method: 'GET',
        url: url,
        body: {},
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Shopify-Access-Token': ApiConfig.shopifyAdminAccessToken,
          'Content-Type': 'application/json',
        },
      );

      AppLogger.info('ApiService: REST API response received - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        AppLogger.info('ApiService: Response data keys: ${responseData.keys}');

        final ordersData = responseData['orders'] as List?;
        if (ordersData == null || ordersData.isEmpty) {
          AppLogger.info('ApiService: No orders found for customer: $customerId');
          AppLogger.info('ApiService: Full response: $responseData');
          return [];
        }

        AppLogger.info('ApiService: Found ${ordersData.length} orders');

        final orders = ordersData.map((orderData) {
          // Convert REST API response to our model format
          final convertedOrderData = {
            'id': orderData['id']?.toString(),
            'name': orderData['name']?.toString() ?? orderData['order_number']?.toString(),
            'email': orderData['email']?.toString() ?? '',
            'financial_status': orderData['financial_status']?.toString()?.toLowerCase(),
            'fulfillment_status': orderData['fulfillment_status']?.toString()?.toLowerCase(),
            'total_price': orderData['total_price']?.toString(),
            'subtotal_price': orderData['subtotal_price']?.toString(),
            'total_tax': orderData['total_tax']?.toString(),
            'currency': orderData['currency']?.toString() ?? 'INR',
            'created_at': orderData['created_at'],
            'updated_at': orderData['updated_at'],
            'note': orderData['note']?.toString(),
            'tags': orderData['tags']?.toString() ?? '',
            'line_items': (orderData['line_items'] as List?)?.map((lineItem) {
              return {
                'id': lineItem['id']?.toString(),
                'title': lineItem['title']?.toString(),
                'variant_title': lineItem['variant_title']?.toString() ?? '',
                'quantity': lineItem['quantity'] ?? 1,
                'price': lineItem['price']?.toString(),
                'total_discount': lineItem['total_discount']?.toString() ?? '0.00',
                'sku': lineItem['sku']?.toString() ?? '',
                'vendor': lineItem['vendor']?.toString() ?? '',
                'product_id': lineItem['product_id']?.toString(),
                'variant_id': lineItem['variant_id']?.toString(),
              };
            }).toList() ?? [],
            'shipping_address': orderData['shipping_address'],
            'billing_address': orderData['billing_address'],
          };

          return ShopifyOrder.fromJson(convertedOrderData);
        }).toList();

        AppLogger.success('ApiService: Successfully fetched ${orders.length} orders');
        return orders;

      } else {
        AppLogger.error('ApiService: REST API error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch orders: HTTP ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error('ApiService: Failed to fetch orders: $e');
      rethrow;
    }
  }
}