import 'dart:async';
import 'package:glocure/screens/home_screen.dart';

import '../config/api_config.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/image_constant.dart';
import '../widgets/app_image.dart';
import '../models/country_code_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import 'language_selection_screen.dart';
import 'main_navigation_screen.dart';
import 'signup_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/signup/signup_cubit.dart';
import '../cubits/cart_indicator/cart_indicator_cubit.dart';

/// Login Screen with sliding backgrounds and phone/OTP or email/password authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginMode { email, otp }

class _LoginScreenState extends State<LoginScreen> {
  late PageController _pageController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _currentPage = 0;
  Timer? _sliderTimer;
  Timer? _resendTimer;

  LoginMode _loginMode = LoginMode.email; // Default to email
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _resendCountdown = 30;
  bool _canResend = false;

  CountryCode _selectedCountry = countryCodes[0]; // Default to India

  final List<String> _bannerImages = [
    ImageConstant.icLoginBanner1,
    ImageConstant.icLoginBanner2,
    ImageConstant.icLoginBanner3,
  ];

  final List<String> _backgroundImages = [
    ImageConstant.icLoginScreenBG1,
    ImageConstant.icLoginScreenBG2,
    ImageConstant.icLoginScreenBG3,
  ];

  final List<Map<String, String>> _bannerTexts = [
    {
      'title': 'Get Your Face',
      'subtitle': 'AI-Scanned & Analysed',
    },
    {
      'title': 'Instant Analysis',
      'subtitle': 'Get Your Report',
    },
    {
      'title': 'Fast Delivery',
      'subtitle': '100% Original Products',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Hide status bar on login
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Start at a high number to allow infinite backward scrolling if needed
    _pageController = PageController(initialPage: 1000);
    _currentPage = 1000;
    _startAutoSlide();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _resendTimer?.cancel();
    _pageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _loginWithEmail() async {
    // Unfocus keyboard and dismiss focus
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Email validation
    if (email.isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    // Email regex validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().customerLogin(
        email: email,
        password: password,
      );

      // Save token with actual expiry from API
      await AuthStorage.saveToken(
        result['accessToken'],
        result['expiresAt'],
      );

      // Create or get cart ID after successful login
      try {
        await ApiService().getOrCreateCartId();

        // Clear cart indicator for new session
        if (mounted) {
          context.read<CartIndicatorCubit>().clearCartIndicator();
        }

        print('✅ Cart ID initialized successfully');
      } catch (cartError) {
        print('⚠️ Failed to initialize cart ID: $cartError');
        // Don't block login flow if cart creation fails
      }

      if (mounted) {
        _showSnackBar('Login successful!');

        // Check if language has been selected before
        final isLanguageSelected = await AuthStorage.isLanguageSelected();

        // Navigate to appropriate screen
        Future.delayed(const Duration(milliseconds: 500), () {
          // SKIPING LANGUAGE SCREEN FOR NOW
          if (true || isLanguageSelected) {
            // Language already selected, go directly to Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          } else {
            // First time login, go to Language Selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Login failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number');
      return;
    }

    if (phone.length != _selectedCountry.maxLength) {
      _showSnackBar('Please enter a valid ${_selectedCountry.maxLength}-digit phone number');
      return;
    }

    setState(() {
      _isOtpSent = true;
    });
    _startResendTimer();
    _showSnackBar('OTP sent to ${_selectedCountry.dialCode} $phone');
  }

  void _resendOtp() {
    if (!_canResend) return;

    _startResendTimer();
    _showSnackBar('OTP resent successfully');
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 4) {
      _showSnackBar('Please enter complete OTP');
      return;
    }

    _showSnackBar('OTP verified successfully');
    ApiConfig.IS_GUEST_LOGIN = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      // SKIPING LANGUAGE SCREEN FOR NOW
      if (true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      }
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 10.h, bottom: 14.h),
                  width: 34.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 7.h),
                  child: Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 15.fSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: countryCodes.length,
                    itemBuilder: (context, index) {
                      final country = countryCodes[index];
                      final isSelected = country.code == _selectedCountry.code;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _phoneController.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary : AppColors.white,
                          ),
                          child: Row(
                            children: [
                              Text(
                                country.flag,
                                style: TextStyle(fontSize: 24),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  country.name,
                                  style: TextStyle(
                                    fontSize: 14.fSize,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              Text(
                                country.dialCode,
                                style: TextStyle(
                                  fontSize: 14.fSize,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: AppColors.gray600,
                                ),
                              ),
                              if (isSelected) ...[
                                SizedBox(width: 12),
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 17.h,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Sliding Background
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imageIndex = index % _backgroundImages.length;
                  return SmartImage(
                    source: _backgroundImages[imageIndex],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Top Section with Image and Text (synced with background)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight * 0.4,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 40),
                                SizedBox(
                                  height: constraints.maxHeight * 0.25,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 34.w),
                                    child: SmartImage(
                                      key: ValueKey(_currentPage % _bannerImages.length),
                                      source: _bannerImages[_currentPage % _bannerImages.length],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32),
                                Column(
                                  children: [
                                    Text(
                                      _bannerTexts[_currentPage % _bannerTexts.length]['title']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20.fSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _bannerTexts[_currentPage % _bannerTexts.length]['subtitle']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20.fSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),

                                // Page Indicators
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _bannerImages.length,
                                    (i) {
                                      final isActive = (_currentPage % _bannerImages.length) == i;
                                      return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                                        width: isActive ? 24 : 8,
                                        height: 3.h,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.primaryLight : AppColors.white.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(2.r),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // White Card with Login/OTP
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 24),

                              // Tab Switcher
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 20.w),
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _loginMode = LoginMode.email;
                                            _isOtpSent = false;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                          decoration: BoxDecoration(
                                            color: _loginMode == LoginMode.email ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(9.r),
                                            boxShadow: _loginMode == LoginMode.email
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.05),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'Login with Email',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.fSize,
                                              fontWeight: FontWeight.w600,
                                              color: _loginMode == LoginMode.email ? AppColors.primary : AppColors.gray400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _loginMode = LoginMode.otp;
                                            _isOtpSent = false;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                          decoration: BoxDecoration(
                                            color: _loginMode == LoginMode.otp ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(9.r),
                                            boxShadow: _loginMode == LoginMode.otp
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.05),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'Login with OTP',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.fSize,
                                              fontWeight: FontWeight.w600,
                                              color: _loginMode == LoginMode.otp ? AppColors.primary : AppColors.gray400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SizedBox(height: 24),

                              // Login/OTP Content with Slide Animation
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.35, // 35% of screen height
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeInOut,
                                    switchOutCurve: Curves.easeInOut,
                                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          ...previousChildren,
                                          if (currentChild != null) currentChild,
                                        ],
                                      );
                                    },
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      // Determine if this is the entering or exiting widget
                                      final isEntering = child.key ==
                                          ValueKey(_loginMode == LoginMode.email ? 'email_form' : (_isOtpSent ? 'otp_form' : 'phone_form'));

                                      Offset beginOffset;
                                      Offset endOffset;

                                      if (isEntering) {
                                        // Entering screen
                                        if (_loginMode == LoginMode.otp) {
                                          // OTP screen slides in from right to left
                                          beginOffset = const Offset(1.0, 0.0);
                                          endOffset = Offset.zero;
                                        } else {
                                          // Email screen slides in from left to right
                                          beginOffset = const Offset(-1.0, 0.0);
                                          endOffset = Offset.zero;
                                        }
                                      } else {
                                        // Exiting screen
                                        beginOffset = Offset.zero;
                                        if (_loginMode == LoginMode.otp) {
                                          // When switching to OTP, current screen slides out to the right
                                          endOffset = const Offset(1.0, 0.0);
                                        } else {
                                          // When switching to Email, current screen slides out to the left
                                          endOffset = const Offset(-1.0, 0.0);
                                        }
                                      }

                                      final offsetAnimation = Tween<Offset>(
                                        begin: beginOffset,
                                        end: endOffset,
                                      ).animate(animation);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                    child: _loginMode == LoginMode.email
                                        ? _buildEmailPasswordForm()
                                        : (!_isOtpSent ? _buildPhoneNumberForm() : _buildOtpVerificationForm()),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberForm() {
    return SingleChildScrollView(
      key: const ValueKey('phone_form'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          _buildPhoneInput(),
          SizedBox(height: 24),
          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'SIGN IN',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Terms and Conditions
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 10.fSize,
                color: AppColors.gray400,
              ),
              children: [
                TextSpan(text: 'By continuing you agree to our\n'),
                TextSpan(
                  text: 'terms and conditions',
                  style: TextStyle(color: AppColors.primary),
                ),
                TextSpan(text: ' and our '),
                TextSpan(
                  text: 'Privacy policy',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Explore Now
          GestureDetector(
            onTap: () {
              ApiConfig.IS_GUEST_LOGIN = true;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.gray200, width: 1),
              ),
              child: Text(
                'Explore Now',
                style: TextStyle(
                  fontSize: 10.fSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationForm() {
    return SingleChildScrollView(
      key: const ValueKey('otp_form'),
      child: Column(
        children: [
          Text(
            'Verify your Phone Number',
            style: TextStyle(
              fontSize: 15.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          SizedBox(height: 32),

          _buildOtpInput(),

          SizedBox(height: 16),

          // Timer
          Text(
            '00:${_resendCountdown.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),

          SizedBox(height: 8),

          // Resend OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: AppColors.gray400,
                ),
              ),
              TextButton(
                onPressed: _canResend ? _resendOtp : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w600,
                    color: _canResend ? AppColors.primary : AppColors.gray300,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'SIGN IN',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // Country Code Selector
          InkWell(
            onTap: _showCountryPicker,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
              child: Row(
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _selectedCountry.dialCode,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 17.h, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),

          // Vertical Divider
          Container(
            width: 1.w,
            height: 27.h,
            color: const Color(0xFFE0E0E0),
          ),

          // Phone Number Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: _selectedCountry.maxLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '893 456 789',
                hintStyle: TextStyle(
                  fontSize: 14.fSize,
                  color: Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
                counterText: '',
              ),
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPasswordForm() {
    return SingleChildScrollView(
      key: const ValueKey('email_form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              maxLength: 30,
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear icon
              },
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(
                  fontSize: 14.fSize,
                  color: Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
                counterText: '',
                suffixIcon: _emailController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _emailController.clear();
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: Color(0xFF999999),
                          size: 17.h,
                        ),
                      )
                    : null,
              ),
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Password',
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(
                  fontSize: 14.fSize,
                  color: Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
                counterText: '',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF999999),
                    size: 17.h,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16.h),

          // Signup navigation link
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have account? ",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: AppColors.gray400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<SignupCubit>(),
                            child: const SignupScreen(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Sign-up here',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // SizedBox(width: 16.h),
                  // GestureDetector(
                  //   onTap: () {
                  //     ApiConfig.IS_GUEST_LOGIN = true;
                  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
                  //   },
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey.shade200,
                  //       borderRadius: BorderRadius.circular(8.r),
                  //       border: Border.all(color: AppColors.gray200, width: 1),
                  //     ),
                  //     child: Text(
                  //       'Explore Now',
                  //       style: TextStyle(
                  //         fontSize: 10.fSize,
                  //         fontWeight: FontWeight.w500,
                  //         color: Colors.grey,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  ApiConfig.IS_GUEST_LOGIN = true;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.gray200, width: 1),
                  ),
                  child: Text(
                    'Explore Now',
                    style: TextStyle(
                      fontSize: 10.fSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 54.w,
          height: 54.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: _otpControllers[index].text.isNotEmpty ? const Color(0xFFFF5C9A) : const Color(0xFFE0E0E0),
              width: 2.w,
            ),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: 27.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && index < 3) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
