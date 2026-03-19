import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'brand_logos_state.dart';

/// Cubit for fetching brand logos
class BrandLogosCubit extends Cubit<BrandLogosState> {
  final ApiService _apiService = ApiService();

  BrandLogosCubit() : super(BrandLogosInitial());

  Future<void> fetchBrandLogos() async {
    try {
      emit(BrandLogosLoading());

      final response = await _apiService.getBrandLogos();

      emit(BrandLogosSuccess(brands: response.banners));
    } catch (e) {
      emit(
        BrandLogosError(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
