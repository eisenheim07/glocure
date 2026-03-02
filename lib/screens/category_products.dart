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

  const _SortOption({required this.label, this.sortKey, this.reverse});
}

const List<_SortOption> _sortOptions = [
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
const List<_SortOption> _discountedSortOptions = [
  // _SortOption(label: 'Featured', sortKey: 'MANUAL', reverse: false),
  // _SortOption(label: 'Best Selling', sortKey: 'BEST_SELLING', reverse: false),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _SortBottomSheet(
          options: _activeSortOptions,
          selectedIndex: _selectedSortIndex,
          onSelected: (index) {
            Navigator.pop(sheetContext);
            _onSortSelected(index);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF777777),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
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
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${products.length} Products',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 16),
                          child: SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFFE9F0) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(tab.icon, style: const TextStyle(fontSize: 13)),
                                        const SizedBox(width: 4),
                                        Text(
                                          tab.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFF7A7A7A),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),

                      // Loading more indicator
                      if (isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF5C9A),
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
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _RadioCircle(isSelected: isSelected),
                              ],
                            ),
                          ),
                        ),
                        if (index < options.length - 1) const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFD0D0D0),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF5C9A),
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
        child: Row(
          children: [
            // Sort button (left)
            Expanded(
              child: InkWell(
                onTap: onSortTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_vert, size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Sort by',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSortApplied ? const Color(0xFFFF5C9A) : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            sortLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF777777),
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
            Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),

            // Filter button (right)
            Expanded(
              child: InkWell(
                onTap: onFilterTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tune, size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isFilterApplied ? const Color(0xFFFF5C9A) : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            filterLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF777777),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
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
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            originalPrice,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Color(0xFF999999),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (discount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-$discount%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 110,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
