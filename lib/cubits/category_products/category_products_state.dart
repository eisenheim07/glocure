import '../../models/top_products_model.dart';

/// States for CategoryProductsCubit
abstract class CategoryProductsState {}

/// Initial state
class CategoryProductsInitial extends CategoryProductsState {}

/// Loading state (first fetch)
class CategoryProductsLoading extends CategoryProductsState {}

/// Success state with products and pagination info
class CategoryProductsSuccess extends CategoryProductsState {
  final String title;
  final List<TopProduct> products;
  final bool hasNextPage;

  CategoryProductsSuccess({
    required this.title,
    required this.products,
    required this.hasNextPage,
  });
}

/// Loading more products (pagination)
class CategoryProductsLoadingMore extends CategoryProductsState {
  final String title;
  final List<TopProduct> products;

  CategoryProductsLoadingMore({
    required this.title,
    required this.products,
  });
}

/// Error state
class CategoryProductsError extends CategoryProductsState {
  final String message;

  CategoryProductsError({required this.message});
}
