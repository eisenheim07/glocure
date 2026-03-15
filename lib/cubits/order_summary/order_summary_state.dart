abstract class OrderSummaryState {
  const OrderSummaryState();
}

class OrderSummaryInitial extends OrderSummaryState {}

class OrderSummaryLoading extends OrderSummaryState {}

class OrderSummaryLoaded extends OrderSummaryState {
  final bool isRefreshing;
  final bool showAllProducts;
  final bool isLoadingRelatedProducts;
  final List<Map<String, dynamic>> relatedProducts;

  const OrderSummaryLoaded({
    this.isRefreshing = false,
    this.showAllProducts = false,
    this.isLoadingRelatedProducts = false,
    this.relatedProducts = const [],
  });

  OrderSummaryLoaded copyWith({
    bool? isRefreshing,
    bool? showAllProducts,
    bool? isLoadingRelatedProducts,
    List<Map<String, dynamic>>? relatedProducts,
  }) {
    return OrderSummaryLoaded(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      showAllProducts: showAllProducts ?? this.showAllProducts,
      isLoadingRelatedProducts: isLoadingRelatedProducts ?? this.isLoadingRelatedProducts,
      relatedProducts: relatedProducts ?? this.relatedProducts,
    );
  }
}

class OrderSummaryError extends OrderSummaryState {
  final String message;

  const OrderSummaryError(this.message);
}