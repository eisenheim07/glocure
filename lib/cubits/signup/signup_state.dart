abstract class SignupState {}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {
  final String message;
  
  SignupSuccess({required this.message});
}

class SignupError extends SignupState {
  final String message;
  
  SignupError({required this.message});
}