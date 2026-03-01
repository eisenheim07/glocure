import '../../models/category_menu_model.dart';
import '../../models/home_top_banner_model.dart';

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesSuccess extends CategoriesState {
  final List<CategoryMenuItem> skinTypeItems;
  final List<CategoryMenuItem> skinConcernItems;
  final List<CategoryMenuItem> shopCategoryItems;
  final List<HomeTopBannerModel> brandLogos;
  final Map<String, String> collectionImages;
  final int selectedTabIndex;

  CategoriesSuccess({
    required this.skinTypeItems,
    required this.skinConcernItems,
    required this.shopCategoryItems,
    required this.brandLogos,
    required this.collectionImages,
    required this.selectedTabIndex,
  });

  CategoriesSuccess copyWith({int? selectedTabIndex}) {
    return CategoriesSuccess(
      skinTypeItems: skinTypeItems,
      skinConcernItems: skinConcernItems,
      shopCategoryItems: shopCategoryItems,
      brandLogos: brandLogos,
      collectionImages: collectionImages,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class CategoriesError extends CategoriesState {
  final String message;

  CategoriesError({required this.message});
}
