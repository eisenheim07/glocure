import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/signup/signup_cubit.dart';
import '../cubits/signup/signup_state.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

// Custom input formatter to allow only alphabetic characters with auto-capitalization
class AlphabeticInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only alphabetic characters (a-z, A-Z)
    final alphabetRegex = RegExp(r'^[a-zA-Z]*$');

    if (!alphabetRegex.hasMatch(newValue.text)) {
      // If the new value contains non-alphabetic characters, return the old value
      return oldValue;
    }

    // Auto-capitalize first character and make rest lowercase
    String formattedText = newValue.text;
    if (formattedText.isNotEmpty) {
      formattedText = formattedText[0].toUpperCase() + 
                     (formattedText.length > 1 ? formattedText.substring(1).toLowerCase() : '');
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFormValid = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Initial validation check
    _validateForm();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _validateAllFields();
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool _validateAllFields() {
    // Check if all fields are not empty
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      return false;
    }

    // Check field lengths
    if (_firstNameController.text.trim().length < 2 || _lastNameController.text.trim().length < 2) {
      return false;
    }

    // Check max lengths
    if (_firstNameController.text.length > 30 ||
        _lastNameController.text.length > 30 ||
        _emailController.text.length > 30 ||
        _passwordController.text.length > 30 ||
        _confirmPasswordController.text.length > 30) {
      return false;
    }

    // Check first name and last name contain only alphabets with first character capitalized
    final alphabetRegex = RegExp(r'^[A-Z][a-z]*$');
    if (!alphabetRegex.hasMatch(_firstNameController.text.trim()) || !alphabetRegex.hasMatch(_lastNameController.text.trim())) {
      return false;
    }

    // Email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return false;
    }

    // Password validation
    if (!_isPasswordValid(_passwordController.text)) {
      return false;
    }

    // Confirm password match
    if (_passwordController.text != _confirmPasswordController.text) {
      return false;
    }

    return true;
  }

  bool _isPasswordValid(String password) {
    if (password.length <= 15) return false;

    int upperCount = 0;
    int lowerCount = 0;
    int digitCount = 0;
    int specialCount = 0;

    final specialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

    for (int i = 0; i < password.length; i++) {
      final char = password[i];
      if (char.contains(RegExp(r'[A-Z]'))) {
        upperCount++;
      } else if (char.contains(RegExp(r'[a-z]'))) {
        lowerCount++;
      } else if (char.contains(RegExp(r'[0-9]'))) {
        digitCount++;
      } else if (specialChars.hasMatch(char)) {
        specialCount++;
      }
    }

    return upperCount >= 2 && lowerCount >= 2 && digitCount >= 2 && specialCount >= 2;
  }

  void _handleSignup() {
    // Show validation errors when button is clicked
    setState(() {
      _showValidationErrors = true;
    });

    // If form is valid, proceed with signup
    if (_isFormValid) {
      context.read<SignupCubit>().createCustomer(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _getFirstNameError() {
    if (!_showValidationErrors) return null;

    // Hide error if user has started typing (field is not empty)
    if (_firstNameController.text.isNotEmpty) {
      // Only show error if there's still an issue after typing
      final alphabetRegex = RegExp(r'^[A-Z][a-z]*$');
      if (_firstNameController.text.trim().length >= 2 &&
          _firstNameController.text.length <= 30 &&
          alphabetRegex.hasMatch(_firstNameController.text.trim())) {
        return null;
      }
    }

    if (_firstNameController.text.trim().isEmpty) {
      return 'First name is required';
    }
    if (_firstNameController.text.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (_firstNameController.text.length > 30) {
      return 'First name must not exceed 30 characters';
    }

    final alphabetRegex = RegExp(r'^[A-Z][a-z]*$');
    if (!alphabetRegex.hasMatch(_firstNameController.text.trim())) {
      return 'First name must start with capital letter and contain only letters';
    }
    return null;
  }

  String? _getLastNameError() {
    if (!_showValidationErrors) return null;

    // Hide error if user has started typing (field is not empty)
    if (_lastNameController.text.isNotEmpty) {
      // Only show error if there's still an issue after typing
      final alphabetRegex = RegExp(r'^[A-Z][a-z]*$');
      if (_lastNameController.text.trim().length >= 2 &&
          _lastNameController.text.length <= 30 &&
          alphabetRegex.hasMatch(_lastNameController.text.trim())) {
        return null;
      }
    }

    if (_lastNameController.text.trim().isEmpty) {
      return 'Last name is required';
    }
    if (_lastNameController.text.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (_lastNameController.text.length > 30) {
      return 'Last name must not exceed 30 characters';
    }

    final alphabetRegex = RegExp(r'^[A-Z][a-z]*$');
    if (!alphabetRegex.hasMatch(_lastNameController.text.trim())) {
      return 'Last name must start with capital letter and contain only letters';
    }
    return null;
  }

  String? _getEmailError() {
    if (!_showValidationErrors) return null;

    // Hide error if user has started typing (field is not empty)
    if (_emailController.text.isNotEmpty) {
      // Only show error if there's still an issue after typing
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (emailRegex.hasMatch(_emailController.text.trim()) && _emailController.text.length <= 30) {
        return null;
      }
    }

    if (_emailController.text.trim().isEmpty) {
      return 'Email is required';
    }
    if (_emailController.text.length > 30) {
      return 'Email must not exceed 30 characters';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _getPasswordError() {
    if (!_showValidationErrors) return null;

    // Hide error if user has started typing (field is not empty)
    if (_passwordController.text.isNotEmpty) {
      // Only show error if there's still an issue after typing
      if (_isPasswordValid(_passwordController.text) && _passwordController.text.length <= 30) {
        return null;
      }
    }

    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    if (_passwordController.text.length > 30) {
      return 'Password must not exceed 30 characters';
    }
    if (!_isPasswordValid(_passwordController.text)) {
      return 'Password must meet all requirements';
    }
    return null;
  }

  String? _getConfirmPasswordError() {
    if (!_showValidationErrors) return null;

    // Hide error if user has started typing (field is not empty)
    if (_confirmPasswordController.text.isNotEmpty) {
      // Only show error if there's still an issue after typing
      if (_passwordController.text == _confirmPasswordController.text && _confirmPasswordController.text.length <= 30) {
        return null;
      }
    }

    if (_confirmPasswordController.text.isEmpty) {
      return 'Confirm password is required';
    }
    if (_confirmPasswordController.text.length > 30) {
      return 'Confirm password must not exceed 30 characters';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: const CustomAppBar(
          type: AppBarType.simple,
          title: 'Create Account',
        ),
        body: BlocListener<SignupCubit, SignupState>(
          listener: (context, state) {
            if (state is SignupSuccess) {
              _showSnackBar(state.message);
              // Navigate back to login screen after successful signup
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            } else if (state is SignupError) {
              _showSnackBar(state.message, isError: true);
            }
          },
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),

                        // Welcome text
                        Text(
                          'Join GloCure',
                          style: TextStyle(
                            fontSize: 24.fSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Create your account to get started',
                          style: TextStyle(
                            fontSize: 14.fSize,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // First Name
                        _buildInputField(
                          label: 'First Name',
                          controller: _firstNameController,
                          hintText: 'Enter your first name',
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          errorText: _getFirstNameError(),
                          inputFormatters: [AlphabeticInputFormatter()],
                          onChanged: (value) {
                            setState(() {
                              _validateForm();
                            });
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Last Name
                        _buildInputField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          hintText: 'Enter your last name',
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          errorText: _getLastNameError(),
                          inputFormatters: [AlphabeticInputFormatter()],
                          onChanged: (value) {
                            setState(() {
                              _validateForm();
                            });
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Email
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          hintText: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _getEmailError(),
                          onChanged: (value) {
                            setState(() {
                              _validateForm();
                            });
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Password
                        _buildInputField(
                          label: 'Password',
                          controller: _passwordController,
                          hintText: 'Enter your password',
                          obscureText: _obscurePassword,
                          errorText: _getPasswordError(),
                          onChanged: (value) {
                            // Trigger validation and UI rebuild on every character change
                            setState(() {
                              _validateForm();
                            });
                          },
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                              size: 20.h,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Password requirements
                        _buildPasswordRequirements(),
                        SizedBox(height: 16.h),

                        // Confirm Password
                        _buildInputField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          hintText: 'Confirm your password',
                          obscureText: _obscureConfirmPassword,
                          errorText: _getConfirmPasswordError(),
                          onChanged: (value) {
                            // Trigger validation and UI rebuild for password match check
                            setState(() {
                              _validateForm();
                            });
                          },
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                              size: 20.h,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Terms and conditions
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12.fSize,
                                color: AppColors.textMuted,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                const TextSpan(text: 'By creating an account, you agree to our\n'),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(color: AppColors.primary, fontFamily: 'Inter'),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(color: AppColors.primary, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),

              // Fixed bottom button
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: BlocBuilder<SignupCubit, SignupState>(
                    builder: (context, state) {
                      final isLoading = state is SignupLoading;

                      return SizedBox(
                        width: double.infinity,
                        height: 40.h,
                        child: ElevatedButton(
                          onPressed: !isLoading ? _handleSignup : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_isFormValid && !isLoading) ? AppColors.primary : AppColors.buttonDisabled,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 14.fSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    letterSpacing: 1,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.fSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(10.r),
            border: errorText != null ? Border.all(color: AppColors.error, width: 1) : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            obscureText: obscureText,
            maxLength: 30,
            onChanged: onChanged ??
                (value) {
                  // Default behavior: trigger validation on every character change
                  _validateForm();
                },
            inputFormatters: [
              LengthLimitingTextInputFormatter(30),
              ...?inputFormatters, // Add custom input formatters
            ],
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14.fSize,
                color: AppColors.textDisabled,
                fontFamily: 'Inter',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
              counterText: '',
              suffixIcon: suffixIcon,
            ),
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 11.fSize,
              color: AppColors.error,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasMinLength = password.length > 15;

    // Count character types in real-time
    int upperCount = 0;
    int lowerCount = 0;
    int digitCount = 0;
    int specialCount = 0;

    final specialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

    for (int i = 0; i < password.length; i++) {
      final char = password[i];
      if (char.contains(RegExp(r'[A-Z]'))) {
        upperCount++;
      } else if (char.contains(RegExp(r'[a-z]'))) {
        lowerCount++;
      } else if (char.contains(RegExp(r'[0-9]'))) {
        digitCount++;
      } else if (specialChars.hasMatch(char)) {
        specialCount++;
      }
    }

    final hasUpperCase = upperCount >= 2;
    final hasLowerCase = lowerCount >= 2;
    final hasDigits = digitCount >= 2;
    final hasSpecialChars = specialCount >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password must contain:',
          style: TextStyle(
            fontSize: 11.fSize,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4.h),
        _buildRequirement('More than 15 characters', hasMinLength),
        _buildRequirement('At least 2 uppercase letters (${upperCount}/2)', hasUpperCase),
        _buildRequirement('At least 2 lowercase letters (${lowerCount}/2)', hasLowerCase),
        _buildRequirement('At least 2 numbers (${digitCount}/2)', hasDigits),
        _buildRequirement('At least 2 special characters (${specialCount}/2)', hasSpecialChars),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12.h,
            color: isValid ? AppColors.success : AppColors.textDisabled,
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.fSize,
              color: isValid ? AppColors.success : AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
