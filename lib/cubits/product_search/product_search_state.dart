import '../../models/top_products_model.dart';

/// States for ProductSearchCubit
abstract class ProductSearchState {}

/// Initial state
class ProductSearchInitial extends ProductSearchState {}

/// Loading state
class ProductSearchLoading extends ProductSearchState {}

/// Success state with search results
class ProductSearchSuccess extends ProductSearchState {
  final List<TopProduct> products;
  final bool hasNextPage;
  final String? endCursor;

  ProductSearchSuccess({
    required this.products,
    required this.hasNextPage,
    this.endCursor,
  });
}

/// Error state
class ProductSearchError extends ProductSearchState {
  final String message;

  ProductSearchError({required this.message});
}
