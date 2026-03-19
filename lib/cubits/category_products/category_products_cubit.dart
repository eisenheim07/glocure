import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/top_products_model.dart';
import 'category_products_state.dart';

/// Cubit for category products screen with pagination, sorting, and filtering.
/// Supports two modes: collection-based (handle) and discounted products.
class CategoryProductsCubit extends Cubit<CategoryProductsState> {
  final ApiService _apiService = ApiService();

  CategoryProductsCubit() : super(CategoryProductsInitial());

  String _handle = '';
  String _originalHandle = ''; // Track the original category handle
  String _title = '';
  List<TopProduct> _products = [];
  bool _hasNextPage = false;
  String? _endCursor;
  String? _sortKey;
  bool? _reverse;
  List<Map<String, dynamic>>? _filters;
  bool _isDiscountedMode = false;

  /// Full list of discounted products before client-side sort/filter
  List<TopProduct> _allDiscountedProducts = [];

  /// Expose all discounted products so the filter screen can build options
  List<TopProduct> get allDiscountedProducts => _allDiscountedProducts;

  // -------------------------------------------------------------------------
  // Filter tab mode (for Best sellers, New at GloCure, etc.)
  // -------------------------------------------------------------------------

  /// Fetch products for filter tab by collection handle
  Future<void> fetchFilterTabProducts(String handle) async {
    try {
      _handle = handle;
      _sortKey = null;
      _reverse = null;
      _filters = null;
      _isDiscountedMode = false;
      _products = [];
      _hasNextPage = false;
      _endCursor = null;

      emit(CategoryProductsLoading());

      final response = await _apiService.getCollectionByHandle(handle);

      _title = response.collection?.title ?? '';
      _products = response.collection?.products ?? [];
      _hasNextPage = response.collection?.hasNextPage ?? false;
      _endCursor = response.collection?.endCursor;

      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    } catch (e) {
      emit(CategoryProductsError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Collection mode
  // -------------------------------------------------------------------------

  /// Fetch first page of products for a given collection handle
  Future<void> fetchProducts(
    String handle, {
    String? sortKey,
    bool? reverse,
    List<Map<String, dynamic>>? filters,
  }) async {
    try {
      _handle = handle;
      _originalHandle = handle; // Store the original category handle
      _sortKey = sortKey;
      _reverse = reverse;
      _filters = filters;
      _isDiscountedMode = false;
      _products = [];
      _hasNextPage = false;
      _endCursor = null;

      emit(CategoryProductsLoading());

      final response = await _apiService.getCollectionProducts(
        handle: handle,
        first: 20,
        sortKey: sortKey,
        reverse: reverse,
        filters: filters,
      );

      _title = response.collection?.title ?? '';
      _products = response.collection?.products ?? [];
      _hasNextPage = response.collection?.hasNextPage ?? false;
      _endCursor = response.collection?.endCursor;

      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    } catch (e) {
      emit(CategoryProductsError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Reset to original category products (used by refresh)
  Future<void> resetToOriginalProducts() async {
    if (_originalHandle.isNotEmpty) {
      await fetchProducts(_originalHandle);
    } else {
      // Fallback: emit current state to complete the refresh
      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Discounted mode
  // -------------------------------------------------------------------------

  /// Fetch discounted products (products with compareAtPriceV2 != null)
  /// Set applyDiscountFilter to false to get all products without filtering
  Future<void> fetchDiscountedProducts({bool applyDiscountFilter = true}) async {
    try {
      _isDiscountedMode = true;
      _title = applyDiscountFilter ? 'Discounted Products' : 'All Products';
      _products = [];
      _allDiscountedProducts = [];
      _hasNextPage = false;
      _endCursor = null;

      emit(CategoryProductsLoading());

      final response = await _apiService.getAllProducts(first: 100);

      List<TopProduct> filteredProducts;
      
      if (applyDiscountFilter) {
        // Filter only discounted products
        filteredProducts = response.products.where((product) {
          if (product.variants.isEmpty) return false;
          return product.variants.first.compareAtPriceV2 != null;
        }).toList();
      } else {
        // Get all products without filter
        filteredProducts = response.products;
      }

      _allDiscountedProducts = filteredProducts;
      _products = filteredProducts;
      _hasNextPage = response.hasNextPage;
      _endCursor = response.endCursor;

      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    } catch (e) {
      emit(CategoryProductsError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Apply client-side sorting and filtering on discounted products
  void applyDiscountedSortAndFilter({
    String? sortKey,
    bool? reverse,
    List<Map<String, dynamic>>? filters,
  }) {
    _sortKey = sortKey;
    _reverse = reverse;
    _filters = filters;

    _products = _applySortAndFilter(_allDiscountedProducts);

    emit(CategoryProductsSuccess(
      title: _title,
      products: _products,
      hasNextPage: _hasNextPage,
    ));
  }

  /// Sort and filter a list of products client-side
  List<TopProduct> _applySortAndFilter(List<TopProduct> source) {
    var result = List<TopProduct>.from(source);

    // Apply filters
    if (_filters != null && _filters!.isNotEmpty) {
      result = _applyClientFilters(result, _filters!);
    }

    // Apply sort
    if (_sortKey != null) {
      result = _applyClientSort(result, _sortKey!, _reverse ?? false);
    }

    return result;
  }

  /// Filter products by vendor, productType, or tag
  List<TopProduct> _applyClientFilters(
    List<TopProduct> products,
    List<Map<String, dynamic>> filters,
  ) {
    // Group filter values by type
    final vendors = <String>{};
    final types = <String>{};
    final tags = <String>{};

    for (final filter in filters) {
      if (filter.containsKey('productVendor')) {
        vendors.add(filter['productVendor'] as String);
      } else if (filter.containsKey('productType')) {
        types.add(filter['productType'] as String);
      } else if (filter.containsKey('tag')) {
        tags.add(filter['tag'] as String);
      }
    }

    return products.where((product) {
      if (vendors.isNotEmpty && !vendors.contains(product.vendor)) {
        return false;
      }
      if (types.isNotEmpty && !types.contains(product.productType)) {
        return false;
      }
      if (tags.isNotEmpty && !product.tags.any((t) => tags.contains(t))) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Sort products by price, title, or date
  List<TopProduct> _applyClientSort(
    List<TopProduct> products,
    String sortKey,
    bool reverse,
  ) {
    final sorted = List<TopProduct>.from(products);

    switch (sortKey) {
      case 'PRICE':
        sorted.sort((a, b) {
          final priceA =
              double.tryParse(a.variants.first.priceV2.amount) ?? 0;
          final priceB =
              double.tryParse(b.variants.first.priceV2.amount) ?? 0;
          return reverse
              ? priceB.compareTo(priceA)
              : priceA.compareTo(priceB);
        });
      case 'TITLE':
        sorted.sort((a, b) => reverse
            ? b.title.compareTo(a.title)
            : a.title.compareTo(b.title));
      case 'CREATED_AT':
        sorted.sort((a, b) => reverse
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
      // MANUAL, BEST_SELLING — keep original order
    }

    return sorted;
  }

  // -------------------------------------------------------------------------
  // Pagination
  // -------------------------------------------------------------------------

  /// Load next page of products using cursor-based pagination
  Future<void> loadMore() async {
    if (!_hasNextPage || _endCursor == null) return;

    try {
      emit(CategoryProductsLoadingMore(
        title: _title,
        products: _products,
      ));

      if (_isDiscountedMode) {
        final response =
            await _apiService.getAllProducts(first: 100, after: _endCursor);

        final discounted = response.products.where((product) {
          if (product.variants.isEmpty) return false;
          return product.variants.first.compareAtPriceV2 != null;
        }).toList();

        _allDiscountedProducts = [..._allDiscountedProducts, ...discounted];
        _hasNextPage = response.hasNextPage;
        _endCursor = response.endCursor;

        // Re-apply current sort and filter on the full list
        _products = _applySortAndFilter(_allDiscountedProducts);
      } else {
        final response = await _apiService.getCollectionProducts(
          handle: _handle,
          first: 20,
          after: _endCursor,
          sortKey: _sortKey,
          reverse: _reverse,
          filters: _filters,
        );

        final newProducts = response.collection?.products ?? [];
        _products = [..._products, ...newProducts];
        _hasNextPage = response.collection?.hasNextPage ?? false;
        _endCursor = response.collection?.endCursor;
      }

      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    } catch (e) {
      // On load more error, still show existing products
      emit(CategoryProductsSuccess(
        title: _title,
        products: _products,
        hasNextPage: _hasNextPage,
      ));
    }
  }
}
