import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'discover_products_state.dart';

class DiscoverProductsCubit extends Cubit<DiscoverProductsState> {
  final ApiService _apiService = ApiService();

  DiscoverProductsCubit() : super(DiscoverProductsInitial());

  Future<void> fetchDiscoverProducts(String collectionId) async {
    if (collectionId.isEmpty) {
      emit(DiscoverProductsError('Collection ID is required'));
      return;
    }

    try {
      emit(DiscoverProductsLoading());
      
      final products = await _apiService.getCollectionProductsById(collectionId);
      
      emit(DiscoverProductsLoaded(products));
    } catch (e) {
      emit(DiscoverProductsError(e.toString()));
    }
  }
}
