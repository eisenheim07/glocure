import '../../models/home_top_banner_model.dart';

/// States for Home Banner Cubit
/// States represent the current condition of the data
/// Think of states as "what is the current situation"

/// Base class for all home banner states
abstract class HomeBannerState {}

/// Initial state - nothing has happened yet
class HomeBannerInitial extends HomeBannerState {}

/// Loading state - API call is in progress
class HomeBannerLoading extends HomeBannerState {}

/// Success state - data loaded successfully
class HomeBannerSuccess extends HomeBannerState {
  /// List of banners loaded from API
  final List<HomeTopBannerModel> banners;

  HomeBannerSuccess({required this.banners});
}

/// Error state - something went wrong
class HomeBannerError extends HomeBannerState {
  /// Error message to display to user
  final String message;

  HomeBannerError({required this.message});
}
