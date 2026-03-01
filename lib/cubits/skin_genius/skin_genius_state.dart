import '../../models/home_top_banner_model.dart';

/// States for Skin Genius Cubit
abstract class SkinGeniusState {}

/// Initial state
class SkinGeniusInitial extends SkinGeniusState {}

/// Loading state
class SkinGeniusLoading extends SkinGeniusState {}

/// Success state with list of analyzes
class SkinGeniusSuccess extends SkinGeniusState {
  final List<HomeTopBannerModel> analyzes;

  SkinGeniusSuccess({required this.analyzes});
}

/// Error state
class SkinGeniusError extends SkinGeniusState {
  final String message;

  SkinGeniusError({required this.message});
}
