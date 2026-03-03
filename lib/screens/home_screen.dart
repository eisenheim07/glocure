import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/screens/category_products.dart';
import 'package:glocure/screens/search_screen.dart';
import 'package:glocure/screens/custom_webview_screen.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../config/api_config.dart';
import '../cubits/home_banner/home_banner_cubit.dart';
import '../cubits/home_banner/home_banner_state.dart';
import '../cubits/middle_banner/middle_banner_cubit.dart';
import '../cubits/middle_banner/middle_banner_state.dart';
import '../cubits/skin_genius/skin_genius_cubit.dart';
import '../cubits/skin_genius/skin_genius_state.dart';
import '../cubits/top_products/top_products_cubit.dart';
import '../cubits/top_products/top_products_state.dart';
import '../cubits/browse_categories/browse_categories_cubit.dart';
import '../cubits/browse_categories/browse_categories_state.dart';
import '../cubits/discounted_products/discounted_products_cubit.dart';
import '../cubits/discounted_products/discounted_products_state.dart';
import '../cubits/brand_logos/brand_logos_cubit.dart';
import '../cubits/brand_logos/brand_logos_state.dart';
import '../cubits/bottom_banner/bottom_banner_cubit.dart';
import '../cubits/bottom_banner/bottom_banner_state.dart';
import '../models/home_top_banner_model.dart';
import '../models/top_products_model.dart';
import '../models/browse_category_model.dart';
import '../models/wishlist_item_model.dart';
import '../utils/format_utils.dart';
import '../utils/image_constant.dart';
import '../utils/wishlist_storage.dart';
import '../widgets/app_image.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import '../widgets/search_bar_widget.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<_TrendingTab> _trendingTabs = [
    _TrendingTab(label: 'Top Products', handle: 'top-products'),
    _TrendingTab(label: 'Recommended', handle: 'recommended'),
  ];

  int _selectedTrendingTabIndex = 0;
  List<String> handleWithMetaField = [];
  bool _isRefreshing = false;
  bool _isInitialLoad = true;
  int _wishlistRefreshKey = 0; // Key to force refresh of product cards

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    context.read<HomeBannerCubit>().fetchBanners();
    context.read<BrowseCategoriesCubit>().fetchCategories();
    context.read<SkinGeniusCubit>().fetchAnalyzes();
    context.read<TopProductsCubit>().fetchProductsForHandle(_trendingTabs[_selectedTrendingTabIndex].handle);
    context.read<MiddleBannerCubit>().fetchMiddleBanners();
    context.read<DiscountedProductsCubit>().fetchDiscountedProducts();
    context.read<BrandLogosCubit>().fetchBrandLogos();
    context.read<BottomBannerCubit>().fetchBottomBanners();

    // Wait for initial load to complete
    if (_isInitialLoad) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    context.read<HomeBannerCubit>().fetchBanners();
    context.read<BrowseCategoriesCubit>().fetchCategories();
    context.read<SkinGeniusCubit>().fetchAnalyzes();
    context.read<TopProductsCubit>().fetchProductsForHandle(_trendingTabs[_selectedTrendingTabIndex].handle);
    context.read<MiddleBannerCubit>().fetchMiddleBanners();
    context.read<DiscountedProductsCubit>().fetchDiscountedProducts();
    context.read<BrandLogosCubit>().fetchBrandLogos();
    context.read<BottomBannerCubit>().fetchBottomBanners();

    // Wait a bit for the shimmer effect to be visible
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Refresh wishlist status for all product cards
  void _refreshWishlistStatus() {
    setState(() {
      _wishlistRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        type: AppBarType.full,
        onWishlistReturn: _refreshWishlistStatus,
      ),
      body: Column(
        children: [
          // Action Buttons (Skin Analysis & Video Consult)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: (_isInitialLoad || _isRefreshing)
                ? Row(
                    children: [
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Start Skin Analysis Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Navigate to Skin Analysis screen
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B3A8B), Color(0xFFB84A9E)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  ImageConstant.icMedicalStaff,
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Start skin Analysis',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Derma Video Consult Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomWebViewScreen(
                                  title: 'Derma Video Consult',
                                  url: ApiConfig.consultUrl,
                                  requestCameraPermission: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E5BA8), Color(0xFF2B7BC9)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  ImageConstant.icDashboard,
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Derma Video Consult',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Sticky Search Bar with shimmer during initial load and refresh
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: (_isInitialLoad || _isRefreshing)
                ? const SearchBarShimmer()
                : BlocBuilder<DiscountedProductsCubit, DiscountedProductsState>(
                    builder: (context, state) {
                      return SearchBarWidget(
                        hintText: 'Search products',
                        onTap: () {
                          // Navigate to search screen with all products
                          if (state is DiscountedProductsSuccess) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(
                                  allProducts: state.allProducts,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  BlocBuilder<HomeBannerCubit, HomeBannerState>(
                    builder: (context, state) {
                      if (state is HomeBannerLoading || _isInitialLoad || _isRefreshing) return _BannerShimmerLayout();
                      if (state is HomeBannerError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                '${state.message}',
                                style: const TextStyle(fontSize: 14, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextButton(onPressed: () => context.read<HomeBannerCubit>().fetchBanners(), child: const Text('Retry')),
                            ],
                          ),
                        );
                      }
                      if (state is HomeBannerSuccess) {
                        final banners = state.banners;
                        if (banners.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No banners found', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ),
                          );
                        }
                        return _BannerColumn(banners: banners);
                      }
                      return _BannerShimmerLayout();
                    },
                  ),
                  const SizedBox(height: 28),
                  // Skin Genius Analyzes Header with shimmer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: (_isInitialLoad || _isRefreshing)
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 200,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          )
                        : Text(
                            'Skin Genius Analyzes',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SkinGeniusCubit, SkinGeniusState>(
                    builder: (context, state) {
                      if (state is SkinGeniusLoading || _isInitialLoad || _isRefreshing) return const _SkinGeniusShimmer();
                      if (state is SkinGeniusError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: const TextStyle(fontSize: 14, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              TextButton(onPressed: () => context.read<SkinGeniusCubit>().fetchAnalyzes(), child: const Text('Retry')),
                            ],
                          ),
                        );
                      }
                      if (state is SkinGeniusSuccess) {
                        final analyzes = state.analyzes;
                        if (analyzes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('No Skin Genius analyzes yet', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          );
                        }
                        return _SkinGeniusList(analyzes: analyzes);
                      }
                      return const _SkinGeniusShimmer();
                    },
                  ),
                  // Top products header + "View all" with shimmer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: (_isInitialLoad || _isRefreshing)
                        ? Row(
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 180,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 60,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Browse By Trending',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final handle = _trendingTabs[_selectedTrendingTabIndex].handle;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryProducts(handle: handle),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View all',
                                  style: TextStyle(color: Color(0xFFFF5C9A), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Trending tabs with shimmer
                  (_isInitialLoad || _isRefreshing)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: List.generate(_trendingTabs.length, (index) {
                              final tab = _trendingTabs[index];
                              final isSelected = index == _selectedTrendingTabIndex;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.h),
                                child: GestureDetector(
                                  onTap: () {
                                    if (!isSelected) {
                                      setState(() {
                                        _selectedTrendingTabIndex = index;
                                      });
                                      context.read<TopProductsCubit>().fetchProductsForHandle(tab.handle);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFFE9F0) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFE0E0E0)),
                                    ),
                                    child: Text(
                                      tab.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFF7A7A7A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                  const SizedBox(height: 16),
                  // Top products BlocBuilder with horizontal cards
                  BlocBuilder<TopProductsCubit, TopProductsState>(
                    builder: (context, state) {
                      if (state is TopProductsLoading || _isInitialLoad || _isRefreshing) {
                        return const _TopProductsShimmer();
                      }

                      if (state is TopProductsError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(state.message, style: const TextStyle(fontSize: 13, color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () {
                                  final handle = _trendingTabs[_selectedTrendingTabIndex].handle;
                                  context.read<TopProductsCubit>().fetchProductsForHandle(handle);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is TopProductsSuccess) {
                        final collection = state.collection;
                        final products = collection?.products ?? [];

                        if (products.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('No products found for this filter.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          );
                        }

                        return _TopProductsList(
                          products: products,
                          handle: _trendingTabs[_selectedTrendingTabIndex].handle,
                          refreshKey: _wishlistRefreshKey,
                          onNavigationReturn: () {
                            setState(() {
                              _wishlistRefreshKey++;
                            });
                          },
                        );
                      }

                      // Initial state
                      return const _TopProductsShimmer();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Browse by categories section
                  BlocBuilder<BrowseCategoriesCubit, BrowseCategoriesState>(
                    builder: (context, state) {
                      if (state is BrowseCategoriesLoading || _isInitialLoad || _isRefreshing) {
                        return const _BrowseCategoriesShimmer();
                      }

                      if (state is BrowseCategoriesError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: const TextStyle(fontSize: 13, color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.read<BrowseCategoriesCubit>().fetchCategories(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is BrowseCategoriesSuccess) {
                        final categories = state.categories;
                        if (categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('No categories found.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          );
                        }
                        return _BrowseCategoriesSection(categories: categories);
                      }

                      // Initial state
                      return const _BrowseCategoriesShimmer();
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<MiddleBannerCubit, MiddleBannerState>(
                    builder: (context, state) {
                      if (state is MiddleBannerLoading || _isInitialLoad || _isRefreshing) return _MiddleBannerShimmer();
                      if (state is MiddleBannerError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(state.message, style: const TextStyle(fontSize: 14, color: Colors.red), textAlign: TextAlign.center),
                              TextButton(onPressed: () => context.read<MiddleBannerCubit>().fetchMiddleBanners(), child: const Text('Retry')),
                            ],
                          ),
                        );
                      }
                      if (state is MiddleBannerSuccess) {
                        final banners = state.banners;
                        if (banners.isEmpty) return const SizedBox.shrink();
                        return _MiddleBannerSection(banners: banners);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Discounted Products section
                  BlocBuilder<DiscountedProductsCubit, DiscountedProductsState>(
                    builder: (context, state) {
                      if (state is DiscountedProductsLoading || _isInitialLoad || _isRefreshing) {
                        return const _DiscountedProductsShimmer();
                      }
                      if (state is DiscountedProductsError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(state.message, style: const TextStyle(fontSize: 13, color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () => context.read<DiscountedProductsCubit>().fetchDiscountedProducts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is DiscountedProductsSuccess) {
                        final products = state.products;
                        if (products.isEmpty) return const SizedBox.shrink();
                        return _DiscountedProductsSection(products: products);
                      }
                      return const _DiscountedProductsShimmer();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Brands section
                  BlocBuilder<BrandLogosCubit, BrandLogosState>(
                    builder: (context, state) {
                      if (state is BrandLogosLoading || _isInitialLoad || _isRefreshing) return const _BrandsShimmer();
                      if (state is BrandLogosError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(state.message, style: const TextStyle(fontSize: 13, color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () => context.read<BrandLogosCubit>().fetchBrandLogos(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is BrandLogosSuccess) {
                        final brands = state.brands;
                        if (brands.isEmpty) return const SizedBox.shrink();
                        return _BrandsSection(brands: brands);
                      }
                      return const _BrandsShimmer();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Bottom banners section (reuses _MiddleBannerSection / _MiddleBannerCard style)
                  BlocBuilder<BottomBannerCubit, BottomBannerState>(
                    builder: (context, state) {
                      if (state is BottomBannerLoading || _isInitialLoad || _isRefreshing) return _MiddleBannerShimmer();
                      if (state is BottomBannerError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(state.message, style: const TextStyle(fontSize: 14, color: Colors.red), textAlign: TextAlign.center),
                              TextButton(onPressed: () => context.read<BottomBannerCubit>().fetchBottomBanners(), child: const Text('Retry')),
                            ],
                          ),
                        );
                      }
                      if (state is BottomBannerSuccess) {
                        final banners = state.banners;
                        if (banners.isEmpty) return const SizedBox.shrink();
                        return _BottomBannerSection(banners: banners);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner cards as a column (for use inside a scrollable)
class _BannerColumn extends StatelessWidget {
  final List<HomeTopBannerModel> banners;

  const _BannerColumn({required this.banners});

  @override
  Widget build(BuildContext context) {
    final firstBanner = banners.isNotEmpty ? banners[0] : null;
    final secondBanner = banners.length > 1 ? banners[1] : null;
    final thirdBanner = banners.length > 2 ? banners[2] : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (firstBanner != null) _BannerCard(banner: firstBanner),
          if (firstBanner != null) const SizedBox(height: 16),
          if (secondBanner != null) _BannerCard(banner: secondBanner),
          if (secondBanner != null) const SizedBox(height: 16),
          if (thirdBanner != null) _BannerCard(banner: thirdBanner),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final HomeTopBannerModel banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;

    for (var field in banner.fields) {
      if (field.reference != null && field.reference!.image != null) {
        imageUrl = field.reference!.image!.url;
        break;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.h),
      child: imageUrl != null
          ? NetworkImageLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              borderRadius: BorderRadius.circular(8.h),
            )
          : Container(
              width: double.infinity,
              height: 175.h,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
            ),
    );
  }
}

class _BannerShimmerLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: const [
        _BannerShimmerCard(height: 292, width: double.infinity),
        SizedBox(height: 16),
        _BannerShimmerCard(height: 175, width: double.infinity),
        SizedBox(height: 16),
        _BannerShimmerCard(height: 175, width: double.infinity),
      ],
    );
  }
}

class _BannerShimmerCard extends StatelessWidget {
  final double height;
  final double width;

  const _BannerShimmerCard({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(width: width, height: height, color: Colors.white),
      ),
    );
  }
}

/// Middle banner section: image(s) with 15px corner radius
class _MiddleBannerSection extends StatelessWidget {
  final List<HomeTopBannerModel> banners;

  const _MiddleBannerSection({required this.banners});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < banners.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _MiddleBannerCard(banner: banners[i]),
          ],
        ],
      ),
    );
  }
}

class _MiddleBannerCard extends StatelessWidget {
  final HomeTopBannerModel banner;

  const _MiddleBannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    for (var field in banner.fields) {
      if (field.reference != null && field.reference!.image != null) {
        imageUrl = field.reference!.image!.url;
        break;
      }
    }

    const radius = 15.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImageLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              borderRadius: BorderRadius.circular(radius),
            )
          : Container(
              width: double.infinity,
              height: 175.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(radius),
              ),
              child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
            ),
    );
  }
}

class _MiddleBannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 175.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

/// Bottom banner section: vertical list of images that size naturally (no fixed height)
class _BottomBannerSection extends StatelessWidget {
  final List<HomeTopBannerModel> banners;

  const _BottomBannerSection({required this.banners});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < banners.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _BottomBannerCard(banner: banners[i]),
          ],
        ],
      ),
    );
  }
}

class _BottomBannerCard extends StatelessWidget {
  final HomeTopBannerModel banner;

  const _BottomBannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    for (var field in banner.fields) {
      if (field.reference != null && field.reference!.image != null) {
        imageUrl = field.reference!.image!.url;
        break;
      }
    }

    const radius = 15.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImageLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              borderRadius: BorderRadius.circular(radius),
            )
          : Container(
              width: double.infinity,
              height: 175.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(radius),
              ),
              child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
            ),
    );
  }
}

/// Skin Genius section: horizontal scrollable row of cards (image in pink frame + label)
class _SkinGeniusList extends StatelessWidget {
  final List<HomeTopBannerModel> analyzes;

  const _SkinGeniusList({required this.analyzes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: analyzes.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.h),
        itemBuilder: (context, index) {
          return _SkinGeniusCard(item: analyzes[index]);
        },
      ),
    );
  }
}

/// Single Skin Genius card: soft pink/purple rounded frame, rounded image, label below
class _SkinGeniusCard extends StatelessWidget {
  final HomeTopBannerModel item;

  const _SkinGeniusCard({required this.item});

  String? _imageUrl() {
    for (var field in item.fields) {
      if (field.reference != null && field.reference!.image != null) {
        return field.reference!.image!.url;
      }
    }
    return null;
  }

  String _label() {
    for (var field in item.fields) {
      if (field.key == 'title' || field.key == 'name') {
        if (field.value != null && field.value!.isNotEmpty) return field.value!;
      }
    }
    // Fallback: format handle (e.g. "fine-lines" -> "Fine lines")
    final parts = item.handle.split('-');
    return parts.map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final label = _label();
    const cardWidth = 110.0;
    const imageSize = 90.0;
    const cornerRadius = 16.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProducts(handle: item.handle),
          ),
        );
      },
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: cardWidth,
              height: cardWidth,
              decoration: BoxDecoration(color: const Color(0xFFF5E6EC), borderRadius: BorderRadius.circular(cornerRadius)),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? NetworkImageLoader(
                          imageUrl: imageUrl,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                        )
                      : _placeholderBox(imageSize),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
    );
  }
}

/// Shimmer placeholder for Skin Genius horizontal row
class _SkinGeniusShimmer extends StatelessWidget {
  const _SkinGeniusShimmer();

  @override
  Widget build(BuildContext context) {
    const cardWidth = 110.0;
    return SizedBox(
      height: 140.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(width: 14.h),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: cardWidth,
                  height: cardWidth,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                ),
                const SizedBox(height: 8),
                Container(width: 60, height: 12, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Simple holder for trending tab label + handle
class _TrendingTab {
  final String label;
  final String handle;

  const _TrendingTab({required this.label, required this.handle});
}

/// Horizontal list of product cards for the current tab
class _TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  final String handle;
  final int refreshKey;
  final VoidCallback onNavigationReturn;

  const _TopProductsList({
    required this.products,
    required this.handle,
    required this.refreshKey,
    required this.onNavigationReturn,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252.h,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.h),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryProducts(handle: handle),
                ),
              );
              // Refresh wishlist status after returning from navigation
              onNavigationReturn();
            },
            child: _TopProductCard(
              key: ValueKey('${products[index].id}_$refreshKey'),
              product: products[index],
            ),
          );
        },
      ),
    );
  }
}

class _TopProductCard extends StatefulWidget {
  final TopProduct product;

  const _TopProductCard({super.key, required this.product});

  @override
  State<_TopProductCard> createState() => _TopProductCardState();
}

class _TopProductCardState extends State<_TopProductCard> with SingleTickerProviderStateMixin {
  bool _isInWishlist = false;
  bool _isCheckingWishlist = true;

  // Animation controller for heart icon
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();

    // Initialize heart animation
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartAnimationController);
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  /// Check if product is in wishlist
  Future<void> _checkWishlistStatus() async {
    setState(() => _isCheckingWishlist = true);

    try {
      final isInWishlist = await WishlistStorage.isInWishlist(widget.product.id);
      if (mounted) {
        setState(() {
          _isInWishlist = isInWishlist;
          _isCheckingWishlist = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
      if (mounted) {
        setState(() => _isCheckingWishlist = false);
      }
    }
  }

  /// Toggle wishlist status
  Future<void> _toggleWishlist() async {
    // Trigger animation
    _heartAnimationController.forward(from: 0.0);

    try {
      if (_isInWishlist) {
        // Remove from wishlist
        final success = await WishlistStorage.removeFromWishlist(widget.product.id);
        if (success && mounted) {
          setState(() => _isInWishlist = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from wishlist'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add to wishlist
        final variant = widget.product.variants.isNotEmpty ? widget.product.variants.first : null;

        if (variant == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product variant not available'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Calculate discount
        int? discountPercent;
        if (variant.compareAtPriceV2 != null) {
          final compareAt = double.tryParse(variant.compareAtPriceV2!.amount) ?? 0;
          final price = double.tryParse(variant.priceV2.amount) ?? 0;
          if (compareAt > 0 && price < compareAt) {
            discountPercent = ((compareAt - price) / compareAt * 100).round();
          }
        }

        final wishlistItem = WishlistItem(
          productId: widget.product.id,
          variantId: variant.id,
          productHandle: widget.product.handle,
          mainHandle: 'top-products', // Default handle for home screen products
          title: widget.product.title,
          price: variant.priceV2.amount,
          discountedPrice: variant.compareAtPriceV2?.amount,
          discountPercent: discountPercent,
          imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first.originalSrc : null,
          addedAt: DateTime.now(),
        );

        final success = await WishlistStorage.addToWishlist(wishlistItem);
        if (success && mounted) {
          setState(() => _isInWishlist = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to wishlist'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String? _imageUrl() {
    if (widget.product.images.isNotEmpty) {
      return widget.product.images.first.originalSrc;
    }
    return null;
  }

  String _priceText() {
    if (widget.product.variants.isNotEmpty) {
      final price = widget.product.variants.first.priceV2;
      return formatIndianCurrency(price.amount);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final price = _priceText();

    final cardWidth = 220.h;

    return Container(
      width: cardWidth,
      clipBehavior: Clip.antiAlias,
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
          // Image with rounded corners + favorite icon
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                child: Container(
                  height: 138.h,
                  width: cardWidth,
                  color: Colors.grey[50],
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImageLoader(
                          imageUrl: imageUrl,
                          width: cardWidth,
                          height: 138.h,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: _toggleWishlist,
                    icon: ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: Icon(
                        _isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF5C9A),
                        size: 22,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          // Separator line between image and text
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),

          // Product info section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF777777), height: 1.3),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        price,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFFF5C9A), shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for horizontal product cards
class _TopProductsShimmer extends StatelessWidget {
  const _TopProductsShimmer();

  @override
  Widget build(BuildContext context) {
    final cardWidth = 220.h;

    return SizedBox(
      height: 252.h,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 14.h),
        itemCount: 3,
      ),
    );
  }
}

/// Browse by categories section container + list
class _BrowseCategoriesSection extends StatelessWidget {
  final List<BrowseCategory> categories;

  const _BrowseCategoriesSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5F0),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Browse by categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
            const SizedBox(height: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final category = categories[index];
                return _BrowseCategoryCard(
                  category: category,
                  isHighlighted: false,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseCategoryCard extends StatelessWidget {
  final BrowseCategory category;
  final bool isHighlighted;

  const _BrowseCategoryCard({
    required this.category,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = category.imageSrc;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProducts(handle: category.handle),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isHighlighted ? Border.all(color: const Color(0xFF2F80ED), width: 2) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 110.h,
                height: 92.h,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImageLoader(
                        imageUrl: imageUrl,
                        width: 110.h,
                        height: 92.h,
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
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Browse by categories
class _BrowseCategoriesShimmer extends StatelessWidget {
  const _BrowseCategoriesShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5F0),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 18,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Column(
                children: List.generate(3, (index) {
                  return Container(
                    height: 92.h,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Discounted Products section: header + 2-column grid
class _DiscountedProductsSection extends StatelessWidget {
  final List<TopProduct> products;

  const _DiscountedProductsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Discounted Products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryProducts(isDiscounted: true),
                    ),
                  );
                },
                child: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  iconSize: 22,
                  color: Colors.black,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryProducts(isDiscounted: true),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.h,
              mainAxisSpacing: 14.h,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _DiscountedProductCard(product: products[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _DiscountedProductCard extends StatelessWidget {
  final TopProduct product;

  const _DiscountedProductCard({required this.product});

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
    if (compareAt <= 0 || price >= compareAt) return 0;
    return ((compareAt - price) / compareAt * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final discount = _discountPercent();
    final variant = product.variants.first;
    final currentPrice = formatIndianCurrency(variant.priceV2.amount);
    final originalPrice = discount > 0 && variant.compareAtPriceV2 != null ? formatIndianCurrency(variant.compareAtPriceV2!.amount) : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryProducts(isDiscounted: true),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with discount badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: SizedBox(
                      width: double.infinity,
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

            // Separator line between image and text
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        currentPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (originalPrice.isNotEmpty)
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFF999999),
                          ),
                        ),
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

/// Brands section: background image + "Brands" title + horizontally scrollable brand logos
class _BrandsSection extends StatelessWidget {
  final List<HomeTopBannerModel> brands;

  const _BrandsSection({required this.brands});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              ImageConstant.icBrandBG,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Brands',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: brands.length,
                    separatorBuilder: (_, __) => SizedBox(width: 14.h),
                    itemBuilder: (context, index) {
                      return _BrandLogoCard(brand: brands[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoCard extends StatelessWidget {
  final HomeTopBannerModel brand;

  const _BrandLogoCard({required this.brand});

  String? _imageUrl() {
    for (var field in brand.fields) {
      if (field.reference != null && field.reference!.image != null) {
        return field.reference!.image!.url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    const size = 72.0;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImageLoader(
                  imageUrl: imageUrl,
                  width: size - 24,
                  height: size - 24,
                  fit: BoxFit.contain,
                )
              : const Icon(Icons.business, color: Colors.grey, size: 28),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Brands section
class _BrandsShimmer extends StatelessWidget {
  const _BrandsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 140.h,
        color: Colors.white,
      ),
    );
  }
}

/// Shimmer placeholder for Discounted Products grid
class _DiscountedProductsShimmer extends StatelessWidget {
  const _DiscountedProductsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 180, height: 22, color: Colors.white),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.h,
              mainAxisSpacing: 14.h,
              childAspectRatio: 0.68,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
