import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit() : super(SignupInitial());

  Future<void> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    emit(SignupLoading());

    try {
      final result = await ApiService().createCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        emit(SignupSuccess(message: 'Account created successfully! Please login to continue.'));
      } else {
        final errors = result['errors'] as List<String>? ?? [];
        final errorMessage = errors.isNotEmpty 
            ? errors.join(', ') 
            : 'Failed to create account. Please try again.';
        emit(SignupError(message: errorMessage));
      }
    } catch (e) {
      emit(SignupError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}