import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/image_constant.dart';
import '../widgets/app_image.dart';
import '../models/country_code_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import 'language_selection_screen.dart';
import 'main_navigation_screen.dart';

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
          if (isLanguageSelected) {
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

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFE9F0) : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                country.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              country.dialCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFFF5C9A),
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                                const SizedBox(height: 40),
                                SizedBox(
                                  height: constraints.maxHeight * 0.25,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: SmartImage(
                                      key: ValueKey(_currentPage % _bannerImages.length),
                                      source: _bannerImages[_currentPage % _bannerImages.length],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Column(
                                  children: [
                                    Text(
                                      _bannerTexts[_currentPage % _bannerTexts.length]['title']!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _bannerTexts[_currentPage % _bannerTexts.length]['subtitle']!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Page Indicators
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _bannerImages.length,
                                    (i) {
                                      final isActive = (_currentPage % _bannerImages.length) == i;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: isActive ? 24 : 8,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFFFB3D9) : Colors.white.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // White Card with Login/OTP
                      Container(
                        decoration: const BoxDecoration(
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
                              const SizedBox(height: 24),

                              // Tab Switcher
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
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
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _loginMode == LoginMode.email ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
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
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _loginMode == LoginMode.email ? const Color(0xFFFF5C9A) : const Color(0xFF999999),
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
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _loginMode == LoginMode.otp ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
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
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _loginMode == LoginMode.otp ? const Color(0xFFFF5C9A) : const Color(0xFF999999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login/OTP Content with Slide Animation
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
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
    return Column(
      key: const ValueKey('phone_form'),
      children: [
        const SizedBox(height: 20),
        _buildPhoneInput(),
        const SizedBox(height: 24),
        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C9A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Terms and Conditions
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
            children: [
              TextSpan(text: 'By continuing you agree to our\n'),
              TextSpan(
                text: 'terms and conditions',
                style: TextStyle(color: Color(0xFFFF5C9A)),
              ),
              TextSpan(text: ' and our '),
              TextSpan(
                text: 'Privacy policy',
                style: TextStyle(color: Color(0xFFFF5C9A)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Explore Now
        TextButton(
          onPressed: () {},
          child: const Text(
            'Explore Now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOtpVerificationForm() {
    return Column(
      key: const ValueKey('otp_form'),
      children: [
        const Text(
          'Verify your Phone Number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 32),

        _buildOtpInput(),

        const SizedBox(height: 16),

        // Timer
        Text(
          '00:${_resendCountdown.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),

        const SizedBox(height: 8),

        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive the code? ",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _canResend ? const Color(0xFFFF5C9A) : const Color(0xFFCCCCCC),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C9A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Country Code Selector
          InkWell(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCountry.dialCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE0E0E0),
          ),

          // Phone Number Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: _selectedCountry.maxLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '893 456 789',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                counterText: '',
              ),
              style: const TextStyle(
                fontSize: 16,
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
    return Column(
      key: const ValueKey('email_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
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
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFFCCCCCC),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              counterText: '',
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _emailController.clear();
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF999999),
                        size: 20,
                      ),
                    )
                  : null,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFFCCCCCC),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                  size: 20,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C9A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SIGN IN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _otpControllers[index].text.isNotEmpty ? const Color(0xFFFF5C9A) : const Color(0xFFE0E0E0),
              width: 2,
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
            style: const TextStyle(
              fontSize: 32,
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
