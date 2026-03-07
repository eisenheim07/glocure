import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/categories/categories_cubit.dart';
import '../cubits/categories/categories_state.dart';
import '../models/category_menu_model.dart';
import '../models/home_top_banner_model.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/network_image_loader.dart';
import 'category_products.dart';
import 'main_navigation_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
        onBackPressed: () {
          // Navigate to home tab in MainNavigationScreen
          MainNavigationScreen.navigateToHome(context);
        },
      ),
      body: SafeArea(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading) return const _CategoriesShimmer();
            if (state is CategoriesError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text(state.message, style: const TextStyle(color: AppColors.error, fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<CategoriesCubit>().fetchAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is CategoriesSuccess) {
              return Row(
                children: [
                  _VerticalTabBar(
                    selectedIndex: state.selectedTabIndex,
                    onTabSelected: (index) {
                      context.read<CategoriesCubit>().selectTab(index);
                    },
                  ),
                  Container(width: 1, color: AppColors.borderSecondary),
                  Expanded(child: _TabContent(state: state)),
                ],
              );
            }
            return const _CategoriesShimmer();
          },
        ),
      ),
    );
  }
}

// ─── Vertical Tab Bar ────────────────────────────────────────────────────────

class _CategoryTab {
  final String label;
  final IconData icon;

  const _CategoryTab({required this.label, required this.icon});
}

const List<_CategoryTab> _tabs = [
  _CategoryTab(label: 'Skin\nType', icon: Icons.face_outlined),
  _CategoryTab(label: 'Skin\nConcern', icon: Icons.healing_outlined),
  _CategoryTab(label: 'Shop\nCategories', icon: Icons.shopping_bag_outlined),
  _CategoryTab(label: 'Brands', icon: Icons.store_outlined),
];

class _VerticalTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _VerticalTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70.w,
      color: AppColors.backgroundSecondary,
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34.w,
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.backgroundTertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tab.icon,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.fSize,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Tab Content Switcher ────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final CategoriesSuccess state;

  const _TabContent({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.selectedTabIndex) {
      case 0:
        return _SkinTypeGrid(
          items: state.skinTypeItems,
          collectionImages: state.collectionImages,
        );
      case 1:
        return _SkinConcernGrid(
          items: state.skinConcernItems,
          collectionImages: state.collectionImages,
        );
      case 2:
        return _ShopCategoriesGrid(
          items: state.shopCategoryItems,
          collectionImages: state.collectionImages,
        );
      case 3:
        return _BrandsGrid(brands: state.brandLogos);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Tab 0: Skin Type — banner + 3-col circular images with golden ring ─────

class _SkinTypeGrid extends StatelessWidget {
  final List<CategoryMenuItem> items;
  final Map<String, String> collectionImages;

  const _SkinTypeGrid({required this.items, required this.collectionImages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12.w),
      children: [
        Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: const LinearGradient(
              colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'ALL SKIN TYPES',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _CircularCategoryItem(
              title: item.title,
              imageUrl: collectionImages[item.collectionHandle],
            );
          },
        ),
      ],
    );
  }
}

class _CircularCategoryItem extends StatelessWidget {
  final String title;
  final String? imageUrl;

  const _CircularCategoryItem({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const imageSize = 64.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryProducts(handle: "skin-type"),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8C9A0), width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImageLoader(
                      imageUrl: imageUrl!,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFF5E6EC),
                      child: const Icon(Icons.spa_outlined, color: Color(0xFFCC8899), size: 26),
                    ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.fSize, fontWeight: FontWeight.w500, color: AppColors.textPrimary, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Skin Concern — 3-col grid of square rounded images, no text ─────

class _SkinConcernGrid extends StatelessWidget {
  final List<CategoryMenuItem> items;
  final Map<String, String> collectionImages;

  const _SkinConcernGrid({required this.items, required this.collectionImages});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(8.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6.w,
        mainAxisSpacing: 6.h,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = collectionImages[item.collectionHandle];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryProducts(handle: "skin-concern"),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImageLoader(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: const Color(0xFFF0E0E8),
                    child: const Icon(Icons.spa_outlined, color: Color(0xFFCC8899), size: 26),
                  ),
          ),
        );
      },
    );
  }
}

// ─── Tab 2: Shop Categories — 2-col cards with pastel bg + title + image ────

const List<Color> _pastelColors = [
  Color(0xFFFCE4EC), // pink
  Color(0xFFFFF9C4), // yellow
  Color(0xFFE8F5E9), // green
  Color(0xFFE3F2FD), // blue
  Color(0xFFF3E5F5), // purple
  Color(0xFFFFF3E0), // orange
];

class _ShopCategoriesGrid extends StatelessWidget {
  final List<CategoryMenuItem> items;
  final Map<String, String> collectionImages;

  const _ShopCategoriesGrid({required this.items, required this.collectionImages});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(10.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = collectionImages[item.collectionHandle];
        final bgColor = _pastelColors[index % _pastelColors.length];

        return _ShopCategoryCard(
          title: item.title,
          imageUrl: imageUrl,
          bgColor: bgColor,
        );
      },
    );
  }
}

class _ShopCategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Color bgColor;

  const _ShopCategoryCard({
    required this.title,
    required this.imageUrl,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryProducts(handle: "skin-concern"),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: NetworkImageLoader(
                      imageUrl: imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else
              const Expanded(
                flex: 3,
                child: Center(
                  child: Icon(Icons.shopping_bag_outlined, size: 34, color: Colors.black26),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Brands — 3-col grid of brand logos directly, no circles ─────────
class _BrandsGrid extends StatelessWidget {
  final List<HomeTopBannerModel> brands;

  const _BrandsGrid({required this.brands});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: EdgeInsets.all(10.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 6.h,
          childAspectRatio: 1.3,
        ),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          return _BrandLogoItem(brand: brands[index]);
        },
      ),
    );
  }
}

class _BrandLogoItem extends StatelessWidget {
  final HomeTopBannerModel brand;

  const _BrandLogoItem({required this.brand});

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

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImageLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            )
          : const Icon(Icons.business, color: Colors.grey, size: 24),
    );
  }
}

// ─── Shimmer Loading ─────────────────────────────────────────────────────────

class _CategoriesShimmer extends StatelessWidget {
  const _CategoriesShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 70.w, color: Colors.white),
        ),
        Container(width: 1, color: const Color(0xFFEEEEEE)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(width: 45, height: 10, color: Colors.white),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
