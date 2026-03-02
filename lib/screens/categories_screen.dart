import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/categories/categories_cubit.dart';
import '../cubits/categories/categories_state.dart';
import '../models/category_menu_model.dart';
import '../models/home_top_banner_model.dart';
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
      backgroundColor: Colors.white,
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.message, style: const TextStyle(color: Colors.red)),
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
                  Container(width: 1, color: const Color(0xFFEEEEEE)),
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
      width: 82,
      color: const Color(0xFFFCF5F7),
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFE0EB) : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isSelected ? const Color(0xFFFF5C9A) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF5C9A).withOpacity(0.1) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tab.icon,
                      size: 20,
                      color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFF555555),
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
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          width: double.infinity,
          height: 150.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'ALL SKIN TYPES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
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
    const imageSize = 76.0;

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
                      child: const Icon(Icons.spa_outlined, color: Color(0xFFCC8899), size: 30),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
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
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.h,
        mainAxisSpacing: 8.h,
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
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImageLoader(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: const Color(0xFFF0E0E8),
                    child: const Icon(Icons.spa_outlined, color: Color(0xFFCC8899), size: 30),
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
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.h,
        mainAxisSpacing: 10.h,
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
              Expanded(
                flex: 3,
                child: Center(
                  child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.black26),
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
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.h,
          mainAxisSpacing: 8.h,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImageLoader(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            )
          : const Icon(Icons.business, color: Colors.grey, size: 28),
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
          child: Container(width: 82, color: Colors.white),
        ),
        Container(width: 1, color: const Color(0xFFEEEEEE)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
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
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(width: 50, height: 12, color: Colors.white),
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
