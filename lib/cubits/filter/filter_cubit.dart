import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/filter_model.dart';
import '../../models/top_products_model.dart';
import '../../services/api_service.dart';
import 'filter_state.dart';

/// Cubit for the full-screen filter UI
class FilterCubit extends Cubit<FilterState> {
  final ApiService _apiService = ApiService();

  FilterCubit() : super(FilterInitial());

  /// Persisted selections so they survive a reload
  Map<String, Set<String>> _savedSelections = {};

  /// Save current selections (called when user applies filters)
  void saveSelections() {
    final current = state;
    if (current is FilterLoaded) {
      _savedSelections = Map<String, Set<String>>.from(
        current.selectedValueIds
            .map((k, v) => MapEntry(k, Set<String>.from(v))),
      );
    }
  }

  /// Clear saved selections (called when user applies with 0 filters)
  void clearSavedSelections() {
    _savedSelections = {};
  }

  /// Fetch available filters for a collection, restoring previous selections
  Future<void> loadFilters(String collectionHandle) async {
    try {
      emit(FilterLoading());

      final response = await _apiService.getCollectionFilters(
        handle: collectionHandle,
      );

      // Keep only LIST type filters (checkbox UI)
      final listFilters =
          response.filters.where((f) => f.type == 'LIST').toList();

      emit(FilterLoaded(
        availableFilters: listFilters,
        selectedCategoryIndex: 0,
        selectedValueIds: _savedSelections,
      ));
    } catch (e) {
      emit(FilterError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Build filter categories from product data (for discounted mode)
  void loadFiltersFromProducts(List<TopProduct> products) {
    final filters = <ShopifyFilter>[];

    // Brand filter (from product.vendor)
    final vendorCounts = <String, int>{};
    for (final p in products) {
      if (p.vendor.isNotEmpty) {
        vendorCounts[p.vendor] = (vendorCounts[p.vendor] ?? 0) + 1;
      }
    }
    if (vendorCounts.isNotEmpty) {
      filters.add(ShopifyFilter(
        id: 'filter.p.vendor',
        label: 'Brand',
        type: 'LIST',
        values: vendorCounts.entries
            .map((e) => ShopifyFilterValue(
                  id: 'filter.p.vendor.${e.key}',
                  label: e.key,
                  count: e.value,
                  input: jsonEncode({'productVendor': e.key}),
                ))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label)),
      ));
    }

    // Product Type filter
    final typeCounts = <String, int>{};
    for (final p in products) {
      if (p.productType.isNotEmpty) {
        typeCounts[p.productType] = (typeCounts[p.productType] ?? 0) + 1;
      }
    }
    if (typeCounts.isNotEmpty) {
      filters.add(ShopifyFilter(
        id: 'filter.p.product_type',
        label: 'Category',
        type: 'LIST',
        values: typeCounts.entries
            .map((e) => ShopifyFilterValue(
                  id: 'filter.p.product_type.${e.key}',
                  label: e.key,
                  count: e.value,
                  input: jsonEncode({'productType': e.key}),
                ))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label)),
      ));
    }

    // Tags filter
    final tagCounts = <String, int>{};
    for (final p in products) {
      for (final tag in p.tags) {
        if (tag.isNotEmpty) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }
    if (tagCounts.isNotEmpty) {
      filters.add(ShopifyFilter(
        id: 'filter.p.tag',
        label: 'Tags',
        type: 'LIST',
        values: tagCounts.entries
            .map((e) => ShopifyFilterValue(
                  id: 'filter.p.tag.${e.key}',
                  label: e.key,
                  count: e.value,
                  input: jsonEncode({'tag': e.key}),
                ))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label)),
      ));
    }

    emit(FilterLoaded(
      availableFilters: filters,
      selectedCategoryIndex: 0,
      selectedValueIds: _savedSelections,
    ));
  }

  /// Select a filter category in the left sidebar
  void selectCategory(int index) {
    final current = state;
    if (current is FilterLoaded) {
      emit(current.copyWith(
        selectedCategoryIndex: index,
        searchQuery: '',
      ));
    }
  }

  /// Toggle a filter value on/off
  void toggleValue(String filterId, String valueId) {
    final current = state;
    if (current is FilterLoaded) {
      final newMap = Map<String, Set<String>>.from(
        current.selectedValueIds
            .map((k, v) => MapEntry(k, Set<String>.from(v))),
      );

      final valueSet = newMap.putIfAbsent(filterId, () => <String>{});
      if (valueSet.contains(valueId)) {
        valueSet.remove(valueId);
        if (valueSet.isEmpty) newMap.remove(filterId);
      } else {
        valueSet.add(valueId);
      }

      emit(current.copyWith(selectedValueIds: newMap));
    }
  }

  /// Update search query within the current filter category
  void updateSearch(String query) {
    final current = state;
    if (current is FilterLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  /// Reset all selected filters
  void resetFilters() {
    final current = state;
    if (current is FilterLoaded) {
      _savedSelections = {};
      emit(current.copyWith(
        selectedValueIds: {},
        searchQuery: '',
        selectedCategoryIndex: 0,
      ));
    }
  }

  /// Get the API-ready filters list
  List<Map<String, dynamic>> getApiFilters() {
    final current = state;
    if (current is FilterLoaded) {
      return current.buildApiFilters();
    }
    return [];
  }
}
