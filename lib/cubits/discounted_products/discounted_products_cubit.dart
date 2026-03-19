import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'discounted_products_state.dart';

/// Cubit for fetching products and filtering to only discounted ones
/// (where compareAtPriceV2 != null on the first variant)
class DiscountedProductsCubit extends Cubit<DiscountedProductsState> {
  final ApiService _apiService = ApiService();

  DiscountedProductsCubit() : super(DiscountedProductsInitial());

  Future<void> fetchDiscountedProducts() async {
    try {
      emit(DiscountedProductsLoading());

      final response = await _apiService.getDiscountedProducts();

      // Filter: only keep products whose first variant has a compareAtPriceV2
      final discounted = response.products.where((product) {
        if (product.variants.isEmpty) return false;
        return product.variants.first.compareAtPriceV2 != null;
      }).toList();

      // Emit success with both all products and filtered discounted products
      emit(DiscountedProductsSuccess(
        products: discounted,
        allProducts: response.products,
      ));
    } catch (e) {
      emit(
        DiscountedProductsError(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
