import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/screens/login_screen.dart';
import '../utils/image_constant.dart';
import '../utils/size_utils.dart';
import '../widgets/app_image.dart';
import '../utils/auth_storage.dart';
import '../services/api_service.dart';
import '../cubits/cart_indicator/cart_indicator_cubit.dart';
import 'main_navigation_screen.dart';

/// Splash Screen - Displays for 2 seconds then navigates to Login or Home
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Hide status bar on splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Initialize cart indicator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartIndicatorCubit>().initializeCartIndicator();
    });
    
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await AuthStorage.isLoggedIn();
    final isLanguageSelected = await AuthStorage.isLanguageSelected();

    // If user is logged in with valid token, ensure cart ID exists
    if (isLoggedIn) {
      await _ensureCartIdExists();
    }

    if (!mounted) return;

    // Navigate to appropriate screen
    if (isLoggedIn && isLanguageSelected) {
      // User is logged in and has selected language - go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      // User is not logged in or hasn't selected language - go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Ensure cart ID exists when user has valid token
  /// If cart ID is missing, create a new one
  Future<void> _ensureCartIdExists() async {
    try {
      final cartId = await AuthStorage.getCartId();

      if (cartId == null || cartId.isEmpty) {
        print('⚠️ Cart ID missing but token is valid. Creating new cart...');
        await ApiService().getOrCreateCartId();
        print('✅ Cart ID restored successfully');
      } else {
        print('✅ Cart ID exists: $cartId');
      }
    } catch (e) {
      print('⚠️ Failed to ensure cart ID exists: $e');
      // Don't block navigation if cart creation fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SmartImage(
              source: ImageConstant.icSplashBG,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Logo centered
          Center(
            child: SmartImage(
              source: ImageConstant.icMainLogo,
              width: 170.w,
              height: 170.h,
            ),
          ),
        ],
      ),
    );
  }
}
