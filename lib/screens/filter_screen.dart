import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/filter/filter_cubit.dart';
import '../cubits/filter/filter_state.dart';
import '../models/filter_model.dart';

class FilterScreen extends StatelessWidget {
  final String collectionHandle;

  const FilterScreen({super.key, required this.collectionHandle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<FilterCubit>().resetFilters(),
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 18),
            label: const Text(
              'Reset Filters',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FilterCubit, FilterState>(
        builder: (context, state) {
          if (state is FilterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FilterError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<FilterCubit>()
                        .loadFilters(collectionHandle),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FilterLoaded) {
            if (state.availableFilters.isEmpty) {
              return const Center(child: Text('No filters available'));
            }

            return Column(
              children: [
                const Divider(height: 1, thickness: 0.5),
                Expanded(
                  child: Row(
                    children: [
                      // Left sidebar
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.30,
                        child: _FilterCategorySidebar(state: state),
                      ),
                      // Vertical divider
                      Container(
                          width: 1, color: const Color(0xFFEEEEEE)),
                      // Right panel
                      Expanded(
                        child: _FilterValuePanel(state: state),
                      ),
                    ],
                  ),
                ),
                // Apply button
                _ApplyButton(count: state.totalSelectedCount),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left sidebar — filter categories
// ---------------------------------------------------------------------------

class _FilterCategorySidebar extends StatelessWidget {
  final FilterLoaded state;

  const _FilterCategorySidebar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: state.availableFilters.length,
        itemBuilder: (context, index) {
          final filter = state.availableFilters[index];
          final isSelected = index == state.selectedCategoryIndex;
          final selectedCount = state.selectedCountForFilter(filter.id);

          return GestureDetector(
            onTap: () => context.read<FilterCubit>().selectCategory(index),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF5C9A)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFFFF5C9A)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5C9A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right panel — filter values with search
// ---------------------------------------------------------------------------

class _FilterValuePanel extends StatelessWidget {
  final FilterLoaded state;

  const _FilterValuePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final currentFilter = state.currentFilter;
    final values = state.filteredValues;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (query) =>
                context.read<FilterCubit>().updateSearch(query),
            decoration: InputDecoration(
              hintText: 'Search in ${currentFilter.label}',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFAAAAAA),
              ),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: Color(0xFFAAAAAA)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF5C9A)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),

        // Values list
        Expanded(
          child: values.isEmpty
              ? const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final value = values[index];
                    final isSelected = state.isValueSelected(
                        currentFilter.id, value.id);

                    return _FilterValueRow(
                      value: value,
                      isSelected: isSelected,
                      onTap: () => context.read<FilterCubit>().toggleValue(
                            currentFilter.id,
                            value.id,
                          ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single filter value row
// ---------------------------------------------------------------------------

class _FilterValueRow extends StatelessWidget {
  final ShopifyFilterValue value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterValueRow({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? const Color(0xFFFFE9F0) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            _FilterCheckbox(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom checkbox matching reference (rounded square, pink when selected)
// ---------------------------------------------------------------------------

class _FilterCheckbox extends StatelessWidget {
  final bool isSelected;

  const _FilterCheckbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF5C9A) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFD0D0D0),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Apply filters button
// ---------------------------------------------------------------------------

class _ApplyButton extends StatelessWidget {
  final int count;

  const _ApplyButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final cubit = context.read<FilterCubit>();
              cubit.saveSelections();
              final filters = cubit.getApiFilters();
              Navigator.pop(context, filters);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C9A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              count > 0 ? 'Apply $count filters' : 'Apply filters',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
