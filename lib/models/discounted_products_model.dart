import 'top_products_model.dart';

/// Response wrapper for the `products(first: N)` GraphQL query.
/// Reuses [TopProduct] and related classes from top_products_model.dart.
class DiscountedProductsResponse {
  final List<TopProduct> products;
  final bool hasNextPage;
  final String? endCursor;

  DiscountedProductsResponse({
    required this.products,
    required this.hasNextPage,
    required this.endCursor,
  });

  factory DiscountedProductsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final productsConnection = data['products'] ?? {};
    final edges = productsConnection['edges'] as List<dynamic>? ?? [];

    final products = edges
        .map((edge) => TopProduct.fromJson(edge['node'] ?? const <String, dynamic>{}))
        .toList();

    final pageInfo = productsConnection['pageInfo'] ?? {};

    return DiscountedProductsResponse(
      products: products,
      hasNextPage: pageInfo['hasNextPage'] ?? false,
      endCursor: pageInfo['endCursor'],
    );
  }
}
