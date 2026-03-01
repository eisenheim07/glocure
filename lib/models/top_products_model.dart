/// Models for the "top-products" collection GraphQL response
class TopProductsCollectionResponse {
  final TopProductsCollection? collection;

  TopProductsCollectionResponse({required this.collection});

  factory TopProductsCollectionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final collectionJson = data['collectionByHandle'];

    return TopProductsCollectionResponse(
      collection:
          collectionJson != null ? TopProductsCollection.fromJson(collectionJson) : null,
    );
  }
}

class TopProductsCollection {
  final String title;
  final String handle;
  final List<TopProduct> products;
  final bool hasNextPage;
  final String? endCursor;

  TopProductsCollection({
    required this.title,
    required this.handle,
    required this.products,
    required this.hasNextPage,
    required this.endCursor,
  });

  factory TopProductsCollection.fromJson(Map<String, dynamic> json) {
    final productsConnection = json['products'] ?? {};
    final edges = productsConnection['edges'] as List<dynamic>? ?? [];

    final products = edges
        .map((edge) => TopProduct.fromJson(edge['node'] ?? const <String, dynamic>{}))
        .toList();

    final pageInfo = productsConnection['pageInfo'] ?? {};

    return TopProductsCollection(
      title: json['title'] ?? '',
      handle: json['handle'] ?? '',
      products: products,
      hasNextPage: pageInfo['hasNextPage'] ?? false,
      endCursor: pageInfo['endCursor'],
    );
  }
}

class TopProduct {
  final String id;
  final String title;
  final String description;
  final String handle;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final String productType;
  final String vendor;
  final List<String> tags;
  final String createdAt;
  final String updatedAt;
  final String? onlineStoreUrl;

  TopProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.handle,
    required this.images,
    required this.variants,
    required this.productType,
    required this.vendor,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.onlineStoreUrl,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    final imagesConnection = json['images'] ?? {};
    final imageEdges = imagesConnection['edges'] as List<dynamic>? ?? [];

    final variantsConnection = json['variants'] ?? {};
    final variantEdges = variantsConnection['edges'] as List<dynamic>? ?? [];

    return TopProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      handle: json['handle'] ?? '',
      images: imageEdges
          .map((edge) => ProductImage.fromJson(edge['node'] ?? const <String, dynamic>{}))
          .toList(),
      variants: variantEdges
          .map(
            (edge) => ProductVariant.fromJson(edge['node'] ?? const <String, dynamic>{}),
          )
          .toList(),
      productType: json['productType'] ?? '',
      vendor: json['vendor'] ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      onlineStoreUrl: json['onlineStoreUrl'],
    );
  }
}

class ProductImage {
  final String originalSrc;
  final String? altText;

  ProductImage({
    required this.originalSrc,
    required this.altText,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      originalSrc: json['originalSrc'] ?? '',
      altText: json['altText'],
    );
  }
}

class ProductVariant {
  final String id;
  final String title;
  final String? sku;
  final Money priceV2;
  final Money? compareAtPriceV2;
  final bool availableForSale;

  ProductVariant({
    required this.id,
    required this.title,
    required this.sku,
    required this.priceV2,
    required this.compareAtPriceV2,
    required this.availableForSale,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sku: json['sku'],
      priceV2: Money.fromJson(json['priceV2'] ?? const <String, dynamic>{}),
      compareAtPriceV2: json['compareAtPriceV2'] != null
          ? Money.fromJson(json['compareAtPriceV2'])
          : null,
      availableForSale: json['availableForSale'] ?? false,
    );
  }
}

class Money {
  final String amount;
  final String currencyCode;

  Money({
    required this.amount,
    required this.currencyCode,
  });

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: json['amount']?.toString() ?? '0',
      currencyCode: json['currencyCode'] ?? '',
    );
  }
}

