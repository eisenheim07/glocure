import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'bottom_banner_state.dart';

class BottomBannerCubit extends Cubit<BottomBannerState> {
  final ApiService _apiService = ApiService();

  BottomBannerCubit() : super(BottomBannerInitial());

  Future<void> fetchBottomBanners() async {
    try {
      emit(BottomBannerLoading());
      final response = await _apiService.getHomeBottomBanners();
      emit(BottomBannerSuccess(banners: response.banners));
    } catch (e) {
      emit(BottomBannerError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
