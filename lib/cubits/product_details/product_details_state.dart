import '../../models/top_products_model.dart';

abstract class ProductDetailsState {
  const ProductDetailsState();
}

class ProductDetailsInitial extends ProductDetailsState {}

class ProductDetailsLoading extends ProductDetailsState {}

class ProductDetailsLoaded extends ProductDetailsState {
  final TopProduct product;
  final Map<String, dynamic>? specifications;
  final bool isInWishlist;
  final bool isCheckingWishlist;
  final int currentImageIndex;
  final int selectedVariantIndex;

  const ProductDetailsLoaded({
    required this.product,
    this.specifications,
    required this.isInWishlist,
    required this.isCheckingWishlist,
    required this.currentImageIndex,
    required this.selectedVariantIndex,
  });

  ProductDetailsLoaded copyWith({
    TopProduct? product,
    Map<String, dynamic>? specifications,
    bool? isInWishlist,
    bool? isCheckingWishlist,
    int? currentImageIndex,
    int? selectedVariantIndex,
  }) {
    return ProductDetailsLoaded(
      product: product ?? this.product,
      specifications: specifications ?? this.specifications,
      isInWishlist: isInWishlist ?? this.isInWishlist,
      isCheckingWishlist: isCheckingWishlist ?? this.isCheckingWishlist,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      selectedVariantIndex: selectedVariantIndex ?? this.selectedVariantIndex,
    );
  }
}

class ProductDetailsError extends ProductDetailsState {
  final String message;
  final bool hasProductFallback;

  const ProductDetailsError({
    required this.message,
    required this.hasProductFallback,
  });
}