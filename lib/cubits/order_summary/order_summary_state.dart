abstract class OrderSummaryState {
  const OrderSummaryState();
}

class OrderSummaryInitial extends OrderSummaryState {}

class OrderSummaryLoading extends OrderSummaryState {}

class OrderSummaryLoaded extends OrderSummaryState {
  final bool isRefreshing;
  final bool showAllProducts;
  final bool isLoadingRelatedProducts;
  final bool isAddingProductToCart; // Full-screen loading for add-to-cart
  final bool justAddedToCart; // Flag to track when we just completed add-to-cart
  final List<Map<String, dynamic>> relatedProducts;
  final Set<String> addingToCartProductIds; // Track which products are being added to cart

  const OrderSummaryLoaded({
    this.isRefreshing = false,
    this.showAllProducts = false,
    this.isLoadingRelatedProducts = false,
    this.isAddingProductToCart = false,
    this.justAddedToCart = false,
    this.relatedProducts = const [],
    this.addingToCartProductIds = const {},
  });

  OrderSummaryLoaded copyWith({
    bool? isRefreshing,
    bool? showAllProducts,
    bool? isLoadingRelatedProducts,
    bool? isAddingProductToCart,
    bool? justAddedToCart,
    List<Map<String, dynamic>>? relatedProducts,
    Set<String>? addingToCartProductIds,
  }) {
    return OrderSummaryLoaded(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      showAllProducts: showAllProducts ?? this.showAllProducts,
      isLoadingRelatedProducts: isLoadingRelatedProducts ?? this.isLoadingRelatedProducts,
      isAddingProductToCart: isAddingProductToCart ?? this.isAddingProductToCart,
      justAddedToCart: justAddedToCart ?? this.justAddedToCart,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      addingToCartProductIds: addingToCartProductIds ?? this.addingToCartProductIds,
    );
  }

  /// Check if a product is being added to cart
  bool isAddingToCart(String productId) {
    return addingToCartProductIds.contains(productId);
  }
}

class OrderSummaryError extends OrderSummaryState {
  final String message;

  const OrderSummaryError(this.message);
}