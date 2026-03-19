/// Wishlist Item Model
/// Represents a product saved in the user's wishlist
/// Stored locally using shared_preferences

class WishlistItem {
  final String productId;
  final String variantId; // Product variant ID for cart operations
  final String productHandle;
  final String mainHandle; // Handle passed from home screen
  final String title;
  final String price;
  final String? discountedPrice;
  final int? discountPercent;
  final String? imageUrl;
  final DateTime addedAt;

  WishlistItem({
    required this.productId,
    required this.variantId,
    required this.productHandle,
    required this.mainHandle,
    required this.title,
    required this.price,
    this.discountedPrice,
    this.discountPercent,
    this.imageUrl,
    required this.addedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productHandle': productHandle,
      'mainHandle': mainHandle,
      'title': title,
      'price': price,
      'discountedPrice': discountedPrice,
      'discountPercent': discountPercent,
      'imageUrl': imageUrl,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? '',
      productHandle: json['productHandle'] ?? '',
      mainHandle: json['mainHandle'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? '0',
      discountedPrice: json['discountedPrice'] as String?,
      discountPercent: json['discountPercent'] as int?,
      imageUrl: json['imageUrl'] as String?,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  WishlistItem copyWith({
    String? productId,
    String? variantId,
    String? productHandle,
    String? mainHandle,
    String? title,
    String? price,
    String? discountedPrice,
    int? discountPercent,
    String? imageUrl,
    DateTime? addedAt,
  }) {
    return WishlistItem(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productHandle: productHandle ?? this.productHandle,
      mainHandle: mainHandle ?? this.mainHandle,
      title: title ?? this.title,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
