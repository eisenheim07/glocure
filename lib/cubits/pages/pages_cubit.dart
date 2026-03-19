import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/page_model.dart';
import '../../services/api_service.dart';
import 'pages_state.dart';

class PagesCubit extends Cubit<PagesState> {
  PagesCubit() : super(PagesInitial());

  /// Fetch pages from API
  Future<void> fetchPages() async {
    emit(PagesLoading());

    try {
      final response = await ApiService().getPages(first: 50);
      final pages = response.pages;

      // Filter pages by handle
      final privacyPolicy = pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('privacy'),
        orElse: () => PageModel(
          id: '',
          title: 'Privacy Policy',
          handle: 'privacy-policy',
          body: '<p>Privacy Policy content not available.</p>',
          bodySummary: '',
        ),
      );

      final termsConditions = pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('terms') || 
                  page.handle.toLowerCase().contains('condition'),
        orElse: () => PageModel(
          id: '',
          title: 'Terms & Conditions',
          handle: 'terms-conditions',
          body: '<p>Terms & Conditions content not available.</p>',
          bodySummary: '',
        ),
      );

      final refundReturns = pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('refund') || 
                  page.handle.toLowerCase().contains('return'),
        orElse: () => PageModel(
          id: '',
          title: 'Refund and Returns Policy',
          handle: 'refund-returns',
          body: '<p>Refund and Returns Policy content not available.</p>',
          bodySummary: '',
        ),
      );

      emit(PagesSuccess(
        pages: pages,
        privacyPolicy: privacyPolicy,
        termsConditions: termsConditions,
        refundReturns: refundReturns,
      ));
    } catch (e) {
      emit(PagesError('Error: ${e.toString()}'));
    }
  }

  /// Refresh pages
  Future<void> refreshPages() async {
    await fetchPages();
  }
}
