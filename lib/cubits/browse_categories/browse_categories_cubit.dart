import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/browse_category_model.dart';
import 'browse_categories_state.dart';

/// Cubit for \"Browse by categories\" collections
class BrowseCategoriesCubit extends Cubit<BrowseCategoriesState> {
  final ApiService _apiService = ApiService();

  BrowseCategoriesCubit() : super(BrowseCategoriesInitial());

  Future<void> fetchCategories() async {
    try {
      emit(BrowseCategoriesLoading());

      final response = await _apiService.getBrowseCategories();

      // Only show categories where metafield != null; max 3
      final filtered = response.categories
          .where((c) => c.hasMetafield)
          // .take(3)
          .toList();

      emit(BrowseCategoriesSuccess(categories: filtered));
    } catch (e) {
      emit(
        BrowseCategoriesError(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}

