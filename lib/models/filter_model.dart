/// Models for Shopify Storefront API product filters

/// Top-level response wrapper for collection filters
class ShopifyFiltersResponse {
  final List<ShopifyFilter> filters;

  ShopifyFiltersResponse({required this.filters});

  factory ShopifyFiltersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final collection = data['collectionByHandle'] ?? {};
    final products = collection['products'] ?? {};
    final filtersList = products['filters'] as List<dynamic>? ?? [];

    return ShopifyFiltersResponse(
      filters: filtersList.map((f) => ShopifyFilter.fromJson(f)).toList(),
    );
  }
}

/// A single filter category (e.g., "Brand", "Price", "Category")
class ShopifyFilter {
  final String id;
  final String label;
  final String type; // "LIST", "PRICE_RANGE", "BOOLEAN"
  final List<ShopifyFilterValue> values;

  ShopifyFilter({
    required this.id,
    required this.label,
    required this.type,
    required this.values,
  });

  factory ShopifyFilter.fromJson(Map<String, dynamic> json) {
    final valuesList = json['values'] as List<dynamic>? ?? [];
    return ShopifyFilter(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'LIST',
      values: valuesList.map((v) => ShopifyFilterValue.fromJson(v)).toList(),
    );
  }
}

/// A single selectable value within a filter category
class ShopifyFilterValue {
  final String id;
  final String label;
  final int count;
  final String input; // JSON string to pass back to the API

  ShopifyFilterValue({
    required this.id,
    required this.label,
    required this.count,
    required this.input,
  });

  factory ShopifyFilterValue.fromJson(Map<String, dynamic> json) {
    return ShopifyFilterValue(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      input: json['input']?.toString() ?? '',
    );
  }
}
