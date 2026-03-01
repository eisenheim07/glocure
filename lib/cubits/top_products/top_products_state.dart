import '../../models/top_products_model.dart';

/// States for TopProductsCubit
abstract class TopProductsState {}

/// Initial state
class TopProductsInitial extends TopProductsState {}

/// Loading state
class TopProductsLoading extends TopProductsState {}

/// Success state with collection + products
class TopProductsSuccess extends TopProductsState {
  final TopProductsCollection? collection;

  TopProductsSuccess({required this.collection});
}

/// Error state
class TopProductsError extends TopProductsState {
  final String message;

  TopProductsError({required this.message});
}

