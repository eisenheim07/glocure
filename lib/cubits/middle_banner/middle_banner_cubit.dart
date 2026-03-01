import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/home_top_banner_model.dart';
import 'middle_banner_state.dart';

class MiddleBannerCubit extends Cubit<MiddleBannerState> {
  final ApiService _apiService = ApiService();

  MiddleBannerCubit() : super(MiddleBannerInitial());

  Future<void> fetchMiddleBanners() async {
    try {
      emit(MiddleBannerLoading());
      final response = await _apiService.getHomeMiddleBanners();
      emit(MiddleBannerSuccess(banners: response.banners));
    } catch (e) {
      emit(MiddleBannerError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
