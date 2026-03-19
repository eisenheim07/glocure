import '../../models/home_top_banner_model.dart';

abstract class BottomBannerState {}

class BottomBannerInitial extends BottomBannerState {}

class BottomBannerLoading extends BottomBannerState {}

class BottomBannerSuccess extends BottomBannerState {
  final List<HomeTopBannerModel> banners;

  BottomBannerSuccess({required this.banners});
}

class BottomBannerError extends BottomBannerState {
  final String message;

  BottomBannerError({required this.message});
}
