import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/category_products/category_products_cubit.dart';
import '../cubits/category_products/category_products_state.dart';
import '../cubits/filter/filter_cubit.dart';
import '../cubits/top_products/top_products_cubit.dart';
import '../models/top_products_model.dart';
import '../utils/format_utils.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import 'filter_screen.dart';
import 'product_details_screen.dart';

// ---------------------------------------------------------------------------
// Sort option model
// ---------------------------------------------------------------------------

class _SortOption {
  final String label;
  final String? sortKey;
  final bool? reverse;

  _SortOption({required this.label, this.sortKey, this.reverse});
}

final List<_SortOption> _sortOptions = [
  _SortOption(label: 'Featured', sortKey: 'MANUAL', reverse: false),
  _SortOption(label: 'Best Selling', sortKey: 'BEST_SELLING', reverse: false),
  _SortOption(label: 'Price: Low to High', sortKey: 'PRICE', reverse: false),
  _SortOption(label: 'Price: High to Low', sortKey: 'PRICE', reverse: true),
  _SortOption(label: 'Name: A-Z', sortKey: 'TITLE', reverse: false),
  _SortOption(label: 'Name: Z-A', sortKey: 'TITLE', reverse: true),
  _SortOption(label: 'Date: New to Old', sortKey: 'CREATED_AT', reverse: true),
  _SortOption(label: 'Date: Old to New', sortKey: 'CREATED_AT', reverse: false),
];

/// Sort options for discounted products (Featured & Best Selling excluded)
final List<_SortOption> _discountedSortOptions = [
  _SortOption(label: 'Price: Low to High', sortKey: 'PRICE', reverse: false),
  _SortOption(label: 'Price: High to Low', sortKey: 'PRICE', reverse: true),
  _SortOption(label: 'Name: A-Z', sortKey: 'TITLE', reverse: false),
  _SortOption(label: 'Name: Z-A', sortKey: 'TITLE', reverse: true),
  _SortOption(label: 'Date: New to Old', sortKey: 'CREATED_AT', reverse: true),
  _SortOption(label: 'Date: Old to New', sortKey: 'CREATED_AT', reverse: false),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CategoryProducts extends StatefulWidget {
  final String? handle;
  final bool isDiscounted;
  final bool showAllProducts;

  const CategoryProducts({
    super.key,
    this.handle,
    this.isDiscounted = false,
    this.showAllProducts = false,
  });

  @override
  State<CategoryProducts> createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  final ScrollController _scrollController = ScrollController();
  int _selectedFilterIndex = 0;

  /// -1 means no sort applied (default). 0+ is the index into _sortOptions.
  int _selectedSortIndex = -1;

  /// Applied filters from the filter screen
  List<Map<String, dynamic>> _appliedFilters = [];

  static const List<_FilterTab> _filterTabs = [
    _FilterTab(label: 'Best sellers', icon: '✨'),
    _FilterTab(label: 'New at GloCure', icon: '🔥'),
    _FilterTab(label: 'Price Drop', icon: '💰'),
    _FilterTab(label: 'Gifts & Offers', icon: '🎁'),
    _FilterTab(label: 'Top Rated', icon: '⭐'),
  ];

  /// Active sort options list based on mode
  List<_SortOption> get _activeSortOptions => widget.isDiscounted ? _discountedSortOptions : _sortOptions;

  bool get _isSortApplied => _selectedSortIndex >= 0;

  bool get _isFilterApplied => _appliedFilters.isNotEmpty;

  String get _sortLabel => _isSortApplied ? _activeSortOptions[_selectedSortIndex].label : 'No filter applied';

  String get _filterLabel =>
      _isFilterApplied ? '${_appliedFilters.length} filter${_appliedFilters.length > 1 ? 's' : ''} applied' : 'No filter applied';

  @override
  void initState() {
    super.initState();
    if (widget.isDiscounted) {
      // Pass showAllProducts parameter to control filtering
      context.read<CategoryProductsCubit>().fetchDiscountedProducts(
            applyDiscountFilter: !widget.showAllProducts,
          );
    } else {
      context.read<CategoryProductsCubit>().fetchProducts(widget.handle!);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<CategoryProductsCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() {
    setState(() {
      _selectedSortIndex = -1;
      _appliedFilters = [];
      _selectedFilterIndex = 0;
    });
    context.read<FilterCubit>().clearSavedSelections();

    if (widget.isDiscounted) {
      return context.read<CategoryProductsCubit>().fetchDiscountedProducts(
            applyDiscountFilter: !widget.showAllProducts,
          );
    } else {
      return context.read<CategoryProductsCubit>().fetchProducts(widget.handle!);
    }
  }

  void _onSortSelected(int index) {
    setState(() {
      _selectedSortIndex = index;
    });

    final option = _activeSortOptions[index];

    if (widget.isDiscounted) {
      context.read<CategoryProductsCubit>().applyDiscountedSortAndFilter(
            sortKey: option.sortKey,
            reverse: option.reverse,
            filters: _isFilterApplied ? _appliedFilters : null,
          );
    } else {
      context.read<CategoryProductsCubit>().fetchProducts(
            widget.handle!,
            sortKey: option.sortKey,
            reverse: option.reverse,
            filters: _isFilterApplied ? _appliedFilters : null,
          );
    }
  }

  void _openFilterScreen() async {
    if (widget.isDiscounted) {
      final cubit = context.read<CategoryProductsCubit>();
      context.read<FilterCubit>().loadFiltersFromProducts(cubit.allDiscountedProducts);
    } else {
      context.read<FilterCubit>().loadFilters(widget.handle!);
    }

    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FilterCubit>(),
          child: FilterScreen(collectionHandle: widget.handle ?? ''),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _appliedFilters = result;
      });

      if (widget.isDiscounted) {
        context.read<CategoryProductsCubit>().applyDiscountedSortAndFilter(
              sortKey: _isSortApplied ? _activeSortOptions[_selectedSortIndex].sortKey : null,
              reverse: _isSortApplied ? _activeSortOptions[_selectedSortIndex].reverse : null,
              filters: result.isNotEmpty ? result : null,
            );
      } else {
        context.read<CategoryProductsCubit>().fetchProducts(
              widget.handle!,
              sortKey: _isSortApplied ? _activeSortOptions[_selectedSortIndex].sortKey : null,
              reverse: _isSortApplied ? _activeSortOptions[_selectedSortIndex].reverse : null,
              filters: result.isNotEmpty ? result : null,
            );
      }
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).padding.bottom),
          child: _SortBottomSheet(
            options: _activeSortOptions,
            selectedIndex: _selectedSortIndex,
            onSelected: (index) {
              Navigator.pop(sheetContext);
              _onSortSelected(index);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
      ),
      body: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
        builder: (context, state) {
          if (state is CategoryProductsLoading) {
            return const _FullPageShimmer();
          }

          if (state is CategoryProductsError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 41.h, color: AppColors.error),
                    SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(fontSize: 12.fSize, color: AppColors.error, fontFamily: 'Inter'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.read<CategoryProductsCubit>().fetchProducts(widget.handle.toString()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Extract data from success or loading-more states
          String title = '';
          List<TopProduct> products = [];
          bool isLoadingMore = false;

          if (state is CategoryProductsSuccess) {
            title = state.title;
            products = state.products;
          } else if (state is CategoryProductsLoadingMore) {
            title = state.title;
            products = state.products;
            isLoadingMore = true;
          }

          // Handle empty response
          if (!isLoadingMore && products.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: [
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 19.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54.h, color: AppColors.borderPrimary),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 11.fSize,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Content area
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Header: title + product count
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 19.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${products.length} Products',
                                style: TextStyle(
                                  fontSize: 12.fSize,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10.h, bottom: 14.h),
                          child: SizedBox(
                            height: 32.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              itemCount: _filterTabs.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final tab = _filterTabs[index];
                                final isSelected = index == _selectedFilterIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilterIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.secondary : AppColors.white,
                                      borderRadius: BorderRadius.circular(17.r),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.borderSecondary,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(tab.icon, style: const TextStyle(fontSize: 13, fontFamily: 'Inter')),
                                        SizedBox(width: 4),
                                        Text(
                                          tab.label,
                                          style: TextStyle(
                                            fontSize: 11.fSize,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Product grid
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final leftIndex = index * 2;
                              final rightIndex = leftIndex + 1;

                              return Padding(
                                padding: EdgeInsets.only(bottom: 14.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _ProductCard(
                                        product: products[leftIndex],
                                        handle: widget.handle,
                                      ),
                                    ),

                                    SizedBox(width: 12.w),

                                    if (rightIndex < products.length)
                                      Expanded(
                                        child: _ProductCard(
                                          product: products[rightIndex],
                                          handle: widget.handle,
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                  ],
                                ),
                              );
                            },
                            childCount: (products.length / 2).ceil(),
                          ),
                        ),
                      ),
                      /*OLD-CODE*/
                      /*SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.h,
                            mainAxisSpacing: 14.h,
                            childAspectRatio: 0.70,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _ProductCard(
                                product: products[index],
                                handle: widget.handle,
                              );
                            },
                            childCount: products.length,
                          ),
                        ),
                      ),*/

                      // Loading more indicator
                      if (isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Center(
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bottom spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom sort/filter bar
              _BottomSortBar(
                sortLabel: _sortLabel,
                isSortApplied: _isSortApplied,
                onSortTap: _showSortBottomSheet,
                filterLabel: _filterLabel,
                isFilterApplied: _isFilterApplied,
                onFilterTap: _openFilterScreen,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort bottom sheet
// ---------------------------------------------------------------------------

class _SortBottomSheet extends StatelessWidget {
  final List<_SortOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SortBottomSheet({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 14.h),
              width: 34.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: AppColors.borderPrimary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Sort By',
              style: TextStyle(
                fontSize: 15.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),

          // Sort options list (scrollable for smaller screens)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(options.length, (index) {
                    final option = options[index];
                    final isSelected = index == selectedIndex;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 13.fSize,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                                _RadioCircle(isSelected: isSelected),
                              ],
                            ),
                          ),
                        ),
                        if (index < options.length - 1) Divider(height: 1.h, thickness: 0.5, indent: 20, endIndent: 20),
                      ],
                    );
                  }),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom radio circle matching reference UI
// ---------------------------------------------------------------------------

class _RadioCircle extends StatelessWidget {
  final bool isSelected;

  const _RadioCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      height: 20.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.gray300,
          width: 2.w,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10.w,
                height: 10.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sort bar
// ---------------------------------------------------------------------------

class _BottomSortBar extends StatelessWidget {
  final String sortLabel;
  final bool isSortApplied;
  final VoidCallback onSortTap;
  final String filterLabel;
  final bool isFilterApplied;
  final VoidCallback onFilterTap;

  const _BottomSortBar({
    required this.sortLabel,
    required this.isSortApplied,
    required this.onSortTap,
    required this.filterLabel,
    required this.isFilterApplied,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Sort button (left)
            Expanded(
              child: InkWell(
                onTap: onSortTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_vert, size: 17.h, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Sort by',
                                style: TextStyle(
                                  fontSize: 11.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                width: 5.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: isSortApplied ? AppColors.primary : AppColors.textDisabled,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            sortLabel,
                            style: TextStyle(
                              fontSize: 9.fSize,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Divider
            Container(width: 1.w, height: 34.h, color: AppColors.borderSecondary),

            // Filter button (right)
            Expanded(
              child: InkWell(
                onTap: onFilterTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 17.h, color: AppColors.black),
                      SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 11.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                width: 5.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: isFilterApplied ? AppColors.primary : AppColors.gray400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            filterLabel,
                            style: TextStyle(
                              fontSize: 9.fSize,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product card
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  final TopProduct product;
  final String? handle;

  const _ProductCard({
    required this.product,
    this.handle,
  });

  String? _imageUrl() {
    if (product.images.isNotEmpty) {
      return product.images.first.originalSrc;
    }
    return null;
  }

  int _discountPercent() {
    if (product.variants.isEmpty) return 0;
    final variant = product.variants.first;
    if (variant.compareAtPriceV2 == null) return 0;
    final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
    final price = double.tryParse(variant.priceV2.amount) ?? 0;
    if (compareAt <= 0) return 0;
    return ((compareAt - price) / compareAt * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final discount = _discountPercent();
    final currentPrice = product.variants.isNotEmpty ? formatIndianCurrency(product.variants.first.priceV2.amount) : '';
    final originalPrice = product.variants.isNotEmpty && product.variants.first.compareAtPriceV2 != null
        ? formatIndianCurrency(product.variants.first.compareAtPriceV2!.amount)
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              handle: handle,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: AppColors.gray300,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImageLoader(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.gray200,
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: AppColors.gray500),
                              ),
                            ),
                    ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '-$discount%',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 9.fSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Divider between image and text
            Container(
              height: 1,
              color: AppColors.gray300,
            ),

            // Product info
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.fSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.fSize,
                      color: AppColors.gray500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentPrice,
                          style: TextStyle(
                            fontSize: 12.fSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 9.fSize,
                              color: AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.gray500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (discount > 0) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            '-$discount%',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 8.fSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _FullPageShimmer extends StatelessWidget {
  const _FullPageShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 153.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 85.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 32.h,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 7.w),
                    child: Container(
                      width: 94.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(17.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.h,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 0.68,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tab model
// ---------------------------------------------------------------------------

class _FilterTab {
  final String label;
  final String icon;

  const _FilterTab({required this.label, required this.icon});
}
