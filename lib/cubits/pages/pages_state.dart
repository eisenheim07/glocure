import '../../models/page_model.dart';

/// Base state for Pages
abstract class PagesState {}

/// Initial state
class PagesInitial extends PagesState {}

/// Loading state
class PagesLoading extends PagesState {}

/// Success state with pages data
class PagesSuccess extends PagesState {
  final List<PageModel> pages;
  final PageModel? privacyPolicy;
  final PageModel? termsConditions;
  final PageModel? refundReturns;

  PagesSuccess({
    required this.pages,
    this.privacyPolicy,
    this.termsConditions,
    this.refundReturns,
  });
}

/// Error state
class PagesError extends PagesState {
  final String message;

  PagesError(this.message);
}
