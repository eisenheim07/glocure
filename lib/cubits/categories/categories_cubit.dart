import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final ApiService _apiService = ApiService();

  // Shopify Admin menu IDs
  static const String _skinTypeMenuId = 'gid://shopify/Menu/233286009010';
  static const String _skinConcernMenuId = 'gid://shopify/Menu/233284468914';
  static const String _shopCategoryMenuId = 'gid://shopify/Menu/233287221426';

  CategoriesCubit() : super(CategoriesInitial());

  Future<void> fetchAll() async {
    try {
      emit(CategoriesLoading());

      // Fetch all data in parallel
      final skinTypeFuture = _apiService.getMenuById(_skinTypeMenuId);
      final skinConcernFuture = _apiService.getMenuById(_skinConcernMenuId);
      final shopCategoryFuture = _apiService.getMenuById(_shopCategoryMenuId);
      final brandLogosFuture = _apiService.getBrandLogos();
      final collectionImagesFuture = _apiService.getAllCollectionImages();

      final skinType = await skinTypeFuture;
      final skinConcern = await skinConcernFuture;
      final shopCategory = await shopCategoryFuture;
      final brandLogos = await brandLogosFuture;
      final collectionImages = await collectionImagesFuture;

      emit(CategoriesSuccess(
        skinTypeItems: skinType.menu?.items ?? [],
        skinConcernItems: skinConcern.menu?.items ?? [],
        shopCategoryItems: shopCategory.menu?.items ?? [],
        brandLogos: brandLogos.banners,
        collectionImages: collectionImages,
        selectedTabIndex: 0,
      ));
    } catch (e) {
      emit(CategoriesError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void selectTab(int index) {
    final current = state;
    if (current is CategoriesSuccess) {
      emit(current.copyWith(selectedTabIndex: index));
    }
  }
}
