import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/home_top_banner_model.dart';
import 'home_banner_event.dart';
import 'home_banner_state.dart';

/// Home Banner Cubit
/// This class manages the state of home banner data
/// It listens to events and updates the state accordingly
class HomeBannerCubit extends Cubit<HomeBannerState> {
  /// API service instance
  final ApiService _apiService = ApiService();

  /// Constructor - starts with initial state
  HomeBannerCubit() : super(HomeBannerInitial());

  /// Handle events
  /// This method is called whenever an event is dispatched
  void handleEvent(HomeBannerEvent event) {
    if (event is FetchHomeBannersEvent) {
      _fetchBanners();
    } else if (event is RefreshHomeBannersEvent) {
      _fetchBanners();
    }
  }

  /// Fetch banners from API
  /// This is a private method that does the actual API call
  Future<void> _fetchBanners() async {
    try {
      // Emit loading state - UI will show loading indicator
      emit(HomeBannerLoading());

      // Call API service to get banners
      final response = await _apiService.getHomeTopBanners();

      // Emit success state with the data - UI will display the banners
      emit(HomeBannerSuccess(banners: response.banners));
    } catch (e) {
      // Emit error state - UI will show error message
      emit(HomeBannerError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Public method to fetch banners
  /// This can be called directly from the UI
  Future<void> fetchBanners() async {
    await _fetchBanners();
  }
}
