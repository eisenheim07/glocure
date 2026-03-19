import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/filter/filter_cubit.dart';
import '../cubits/filter/filter_state.dart';
import '../models/filter_model.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';

class FilterScreen extends StatelessWidget {
  final String collectionHandle;

  const FilterScreen({super.key, required this.collectionHandle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filters',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15.fSize,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<FilterCubit>().resetFilters(),
            icon: Icon(Icons.refresh, color: AppColors.textMuted, size: 15.h),
            label: Text(
              'Reset Filters',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.fSize, fontFamily: 'Inter'),
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
                  SizedBox(height: 12),
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
                Divider(height: 1.h, thickness: 0.5),
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
                          width: 1.w, color: AppColors.borderSecondary),
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
      color: AppColors.backgroundSecondary,
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
                color: isSelected ? AppColors.white : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 3.w,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 13.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 11.fSize,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: TextStyle(
                          fontSize: 9.fSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
          padding: EdgeInsets.all(10.h),
          child: TextField(
            onChanged: (query) =>
                context.read<FilterCubit>().updateSearch(query),
            decoration: InputDecoration(
              hintText: 'Search in ${currentFilter.label}',
              hintStyle: TextStyle(
                fontSize: 11.fSize,
                color: AppColors.textDisabled,
              ),
              prefixIcon: Icon(Icons.search,
                  size: 17.h, color: AppColors.textDisabled),
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: Color(0xFFFF5C9A)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(fontSize: 11.fSize, fontFamily: 'Inter'),
          ),
        ),

        // Values list
        Expanded(
          child: values.isEmpty
              ? Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(fontSize: 11.fSize, color: Color(0xFF999999), fontFamily: 'Inter'),
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
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.label,
                style: TextStyle(
                  fontSize: 12.fSize,
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
      width: 19.h,
      height: 19.h,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF5C9A) : Colors.transparent,
        borderRadius: BorderRadius.circular(3.r),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFD0D0D0),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 13.h, color: Colors.white)
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
      padding: EdgeInsets.fromLTRB(13.w, 10.h, 13.w, 10.h),
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
          height: 42.h,
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
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              count > 0 ? 'Apply $count filters' : 'Apply filters',
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
