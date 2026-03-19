import '../../models/home_top_banner_model.dart';

abstract class MiddleBannerState {}

class MiddleBannerInitial extends MiddleBannerState {}

class MiddleBannerLoading extends MiddleBannerState {}

class MiddleBannerSuccess extends MiddleBannerState {
  final List<HomeTopBannerModel> banners;

  MiddleBannerSuccess({required this.banners});
}

class MiddleBannerError extends MiddleBannerState {
  final String message;

  MiddleBannerError({required this.message});
}
