import '../../models/top_products_model.dart';

abstract class DiscoverProductsState {}

class DiscoverProductsInitial extends DiscoverProductsState {}

class DiscoverProductsLoading extends DiscoverProductsState {}

class DiscoverProductsLoaded extends DiscoverProductsState {
  final List<TopProduct> products;

  DiscoverProductsLoaded(this.products);
}

class DiscoverProductsError extends DiscoverProductsState {
  final String message;

  DiscoverProductsError(this.message);
}
