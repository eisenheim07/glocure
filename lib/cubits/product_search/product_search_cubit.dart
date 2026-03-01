import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/top_products_model.dart';
import 'product_search_state.dart';

/// Cubit for product search functionality
class ProductSearchCubit extends Cubit<ProductSearchState> {
  final ApiService _apiService = ApiService();

  ProductSearchCubit() : super(ProductSearchInitial());

  List<TopProduct> _allProducts = [];
  String? _currentCursor;
  String _currentSearchTerm = '';

  /// Search products by term
  Future<void> searchProducts(String searchTerm) async {
    try {
      _currentSearchTerm = searchTerm;
      _allProducts = [];
      _currentCursor = null;

      emit(ProductSearchLoading());

      final response = await _apiService.searchProducts(searchTerm);

      _allProducts = response.products;
      _currentCursor = response.endCursor;

      emit(ProductSearchSuccess(
        products: _allProducts,
        hasNextPage: response.hasNextPage,
        endCursor: _currentCursor,
      ));
    } catch (e) {
      emit(ProductSearchError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_currentCursor == null || _currentSearchTerm.isEmpty) return;

    try {
      final response = await _apiService.searchProducts(
        _currentSearchTerm,
        cursor: _currentCursor,
      );

      _allProducts.addAll(response.products);
      _currentCursor = response.endCursor;

      emit(ProductSearchSuccess(
        products: _allProducts,
        hasNextPage: response.hasNextPage,
        endCursor: _currentCursor,
      ));
    } catch (e) {
      // Keep current state on pagination error
      emit(ProductSearchSuccess(
        products: _allProducts,
        hasNextPage: false,
        endCursor: _currentCursor,
      ));
    }
  }

  /// Clear search results
  void clearSearch() {
    _allProducts = [];
    _currentCursor = null;
    _currentSearchTerm = '';
    emit(ProductSearchInitial());
  }
}
