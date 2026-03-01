import '../../models/home_top_banner_model.dart';

/// States for BrandLogosCubit
abstract class BrandLogosState {}

/// Initial state
class BrandLogosInitial extends BrandLogosState {}

/// Loading state
class BrandLogosLoading extends BrandLogosState {}

/// Success state with brand logos
class BrandLogosSuccess extends BrandLogosState {
  final List<HomeTopBannerModel> brands;

  BrandLogosSuccess({required this.brands});
}

/// Error state
class BrandLogosError extends BrandLogosState {
  final String message;

  BrandLogosError({required this.message});
}
