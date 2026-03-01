import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/top_products_model.dart';
import 'top_products_state.dart';

/// Cubit for the "top-products" collection
class TopProductsCubit extends Cubit<TopProductsState> {
  final ApiService _apiService = ApiService();

  TopProductsCubit() : super(TopProductsInitial());

  String _currentHandle = 'top-products';
  String get currentHandle => _currentHandle;

  Future<void> fetchProductsForHandle(String handle) async {
    try {
      _currentHandle = handle;
      emit(TopProductsLoading());

      final response = await _apiService.getCollectionByHandle(handle);

      emit(
        TopProductsSuccess(collection: response.collection),
      );
    } catch (e) {
      emit(
        TopProductsError(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}

