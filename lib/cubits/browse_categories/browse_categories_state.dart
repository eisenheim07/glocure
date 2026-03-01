import '../../models/browse_category_model.dart';

/// States for BrowseCategoriesCubit
abstract class BrowseCategoriesState {}

class BrowseCategoriesInitial extends BrowseCategoriesState {}

class BrowseCategoriesLoading extends BrowseCategoriesState {}

class BrowseCategoriesSuccess extends BrowseCategoriesState {
  final List<BrowseCategory> categories;

  BrowseCategoriesSuccess({required this.categories});
}

class BrowseCategoriesError extends BrowseCategoriesState {
  final String message;

  BrowseCategoriesError({required this.message});
}

