import 'dart:convert';

import '../../models/filter_model.dart';

/// States for FilterCubit
abstract class FilterState {}

/// Initial state
class FilterInitial extends FilterState {}

/// Loading available filters from API
class FilterLoading extends FilterState {}

/// Filters loaded — user is interacting
class FilterLoaded extends FilterState {
  final List<ShopifyFilter> availableFilters;
  final int selectedCategoryIndex;
  final Map<String, Set<String>> selectedValueIds; // filterId → set of valueIds
  final String searchQuery;

  FilterLoaded({
    required this.availableFilters,
    required this.selectedCategoryIndex,
    required this.selectedValueIds,
    this.searchQuery = '',
  });

  /// Total count of all selected filter values across all categories
  int get totalSelectedCount {
    int count = 0;
    for (final entry in selectedValueIds.values) {
      count += entry.length;
    }
    return count;
  }

  /// Count of selected values for a specific filter category
  int selectedCountForFilter(String filterId) {
    return selectedValueIds[filterId]?.length ?? 0;
  }

  /// The currently active filter category
  ShopifyFilter get currentFilter => availableFilters[selectedCategoryIndex];

  /// Filtered values based on search query
  List<ShopifyFilterValue> get filteredValues {
    final values = currentFilter.values;
    if (searchQuery.isEmpty) return values;
    return values
        .where(
            (v) => v.label.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  /// Whether a specific value is selected
  bool isValueSelected(String filterId, String valueId) {
    return selectedValueIds[filterId]?.contains(valueId) ?? false;
  }

  /// Build the filters list to send to the Shopify API
  List<Map<String, dynamic>> buildApiFilters() {
    final apiFilters = <Map<String, dynamic>>[];
    for (final filter in availableFilters) {
      final selectedIds = selectedValueIds[filter.id];
      if (selectedIds == null || selectedIds.isEmpty) continue;
      for (final value in filter.values) {
        if (selectedIds.contains(value.id)) {
          final parsed = jsonDecode(value.input) as Map<String, dynamic>;
          apiFilters.add(parsed);
        }
      }
    }
    return apiFilters;
  }

  /// Create a copy with modified fields
  FilterLoaded copyWith({
    List<ShopifyFilter>? availableFilters,
    int? selectedCategoryIndex,
    Map<String, Set<String>>? selectedValueIds,
    String? searchQuery,
  }) {
    return FilterLoaded(
      availableFilters: availableFilters ?? this.availableFilters,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedValueIds: selectedValueIds ?? this.selectedValueIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Error loading filters
class FilterError extends FilterState {
  final String message;

  FilterError({required this.message});
}
