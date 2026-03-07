import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/utils/size_utils.dart';
import '../cubits/product_search/product_search_cubit.dart';
import '../cubits/product_search/product_search_state.dart';
import '../models/top_products_model.dart';
import '../screens/product_details_screen.dart';
import '../screens/category_products.dart';
import '../utils/format_utils.dart';
import '../widgets/network_image_loader.dart';

/// Search Screen
/// Displays search bar, search history, recommendations, and search results
class SearchScreen extends StatelessWidget {
  final List<TopProduct> allProducts;

  const SearchScreen({
    super.key,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductSearchCubit(),
      child: _SearchScreenContent(allProducts: allProducts),
    );
  }
}

class _SearchScreenContent extends StatefulWidget {
  final List<TopProduct> allProducts;

  const _SearchScreenContent({required this.allProducts});

  @override
  State<_SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<_SearchScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<String> _searchHistory = [];
  List<String> _recommendations = [];
  bool _isSearchBarReadOnly = false;

  @override
  void initState() {
    super.initState();
    _extractRecommendations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final searchCubit = context.read<ProductSearchCubit>();
      final state = searchCubit.state;
      if (state is ProductSearchSuccess && state.hasNextPage) {
        searchCubit.loadMoreProducts();
      }
    }
  }

  /// Extract unique tags from all products for recommendations
  void _extractRecommendations() {
    final Set<String> uniqueTags = {};

    for (var product in widget.allProducts) {
      if (product.tags.isNotEmpty) {
        uniqueTags.addAll(product.tags);
      }
    }

    setState(() {
      _recommendations = uniqueTags.toList();
      if (_recommendations.length > 20) {
        _recommendations = _recommendations.sublist(0, 20);
      }
    });
  }

  /// Add search term to history
  void _addToSearchHistory(String term) {
    if (term.isEmpty) return;

    setState(() {
      _searchHistory.remove(term);
      _searchHistory.insert(0, term);
      if (_searchHistory.length > 9) {
        _searchHistory = _searchHistory.sublist(0, 9);
      }
    });
  }

  /// Clear all search history
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  /// Handle search term selection from chips
  void _onSearchTermSelected(String term) {
    setState(() {
      _searchController.text = term;
      _isSearchBarReadOnly = true;
    });
    _addToSearchHistory(term);
    _searchFocusNode.unfocus();
    // Trigger search API
    context.read<ProductSearchCubit>().searchProducts(term);
  }

  /// Handle manual search submission
  void _onSearchSubmitted(String value) {
    if (value.isEmpty) return;
    setState(() {
      _isSearchBarReadOnly = true;
    });
    _addToSearchHistory(value);
    _searchFocusNode.unfocus();
    // Trigger search API
    context.read<ProductSearchCubit>().searchProducts(value);
  }

  /// Clear search and reset
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearchBarReadOnly = false;
    });
    context.read<ProductSearchCubit>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _searchFocusNode.unfocus();
              Navigator.pop(context);
            },
          ),
          title: Container(
            height: 42.h,
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                readOnly: _isSearchBarReadOnly,
                autofocus: false,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products',
                  hintStyle: TextStyle(
                    fontSize: 13.fSize,
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9E9E9E),
                    size: 18,
                  ),
                  suffixIcon: _isSearchBarReadOnly
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF9E9E9E)),
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ),
        ),
        body: BlocBuilder<ProductSearchCubit, ProductSearchState>(
          builder: (context, searchState) {
            // Show search results if searching
            if (searchState is ProductSearchLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (searchState is ProductSearchError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(searchState.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          context.read<ProductSearchCubit>().searchProducts(_searchController.text);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (searchState is ProductSearchSuccess) {
              return _SearchResultsGrid(
                products: searchState.products,
                hasNextPage: searchState.hasNextPage,
                scrollController: _scrollController,
              );
            }

            // Show default discover view
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search History Section
                if (_searchHistory.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search history',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5C9A)),
                        onPressed: _clearSearchHistory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchHistory.map((term) {
                      return _SearchChip(
                        label: term,
                        onTap: () => _onSearchTermSelected(term),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recommendations Section
                if (_recommendations.isNotEmpty) ...[
                  const Text(
                    'Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recommendations.map((tag) {
                      return _SearchChip(
                        label: tag,
                        onTap: () => _onSearchTermSelected(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Discover Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryProducts(
                              isDiscounted: true,
                              showAllProducts: true,
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              color: Color(0xFFFF5C9A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Color(0xFFFF5C9A),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Products Horizontal Grid
                _ProductsHorizontalGrid(products: widget.allProducts),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Search Chip Widget
class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SearchChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Search Results Grid (Vertical 2-column grid)
class _SearchResultsGrid extends StatelessWidget {
  final List<TopProduct> products;
  final bool hasNextPage;
  final ScrollController scrollController;

  const _SearchResultsGrid({
    required this.products,
    required this.hasNextPage,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12.h,
          runSpacing: 16.h,
          children: products.map((product) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 44.h) / 2,
              child: _ProductCard(product: product),
            );
          }).toList(),
        ),
        if (hasNextPage)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// Products Horizontal Grid Widget (for discover section)
class _ProductsHorizontalGrid extends StatelessWidget {
  final List<TopProduct> products;

  const _ProductsHorizontalGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No products found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 580.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, columnIndex) {
          final firstProductIndex = columnIndex * 2;
          final secondProductIndex = firstProductIndex + 1;

          return Padding(
            padding: EdgeInsets.only(right: 12.h),
            child: Column(
              children: [
                SizedBox(
                  width: 165.h,
                  child: _ProductCard(product: products[firstProductIndex]),
                ),
                SizedBox(height: 12.h),
                if (secondProductIndex < products.length)
                  SizedBox(
                    width: 165.h,
                    child: _ProductCard(product: products[secondProductIndex]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Product Card Widget
class _ProductCard extends StatelessWidget {
  final TopProduct product;

  const _ProductCard({required this.product});

  String? _imageUrl() {
    if (product.images.isNotEmpty) {
      return product.images.first.originalSrc;
    }
    return null;
  }

  String _priceText() {
    if (product.variants.isNotEmpty) {
      final price = product.variants.first.priceV2;
      return formatIndianCurrency(price.amount);
    }
    return '';
  }

  String? _compareAtPriceText() {
    if (product.variants.isNotEmpty) {
      final compareAtPrice = product.variants.first.compareAtPriceV2;
      if (compareAtPrice != null) {
        return formatIndianCurrency(compareAtPrice.amount);
      }
    }
    return null;
  }

  int? _discountPercentage() {
    if (product.variants.isNotEmpty) {
      final variant = product.variants.first;
      if (variant.compareAtPriceV2 != null) {
        final price = double.tryParse(variant.priceV2.amount) ?? 0;
        final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
        if (compareAt > 0) {
          final discount = ((compareAt - price) / compareAt * 100).round();
          return discount;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final price = _priceText();
    final compareAtPrice = _compareAtPriceText();
    final discount = _discountPercentage();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 140.h,
                  width: double.infinity,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImageLoader(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 140.h,
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
              if (discount != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Container(
            height: 1,
            color: const Color(0xFFF0F0F0),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (compareAtPrice != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          compareAtPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey[500],
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
