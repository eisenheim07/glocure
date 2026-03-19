import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'skin_genius_state.dart';

/// Cubit for Skin Genius analyzes data
class SkinGeniusCubit extends Cubit<SkinGeniusState> {
  final ApiService _apiService = ApiService();

  SkinGeniusCubit() : super(SkinGeniusInitial());

  Future<void> fetchAnalyzes() async {
    try {
      emit(SkinGeniusLoading());

      final response = await _apiService.getSkinGeniusAnalyzes();

      emit(SkinGeniusSuccess(analyzes: response.banners));
    } catch (e) {
      emit(SkinGeniusError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
