import '../../models/top_products_model.dart';

/// States for DiscountedProductsCubit
abstract class DiscountedProductsState {}

/// Initial state
class DiscountedProductsInitial extends DiscountedProductsState {}

/// Loading state
class DiscountedProductsLoading extends DiscountedProductsState {}

/// Success state with filtered discounted products and all products
class DiscountedProductsSuccess extends DiscountedProductsState {
  final List<TopProduct> products; // Discounted products only
  final List<TopProduct> allProducts; // All products for search

  DiscountedProductsSuccess({
    required this.products,
    required this.allProducts,
  });
}

/// Error state
class DiscountedProductsError extends DiscountedProductsState {
  final String message;

  DiscountedProductsError({required this.message});
}
