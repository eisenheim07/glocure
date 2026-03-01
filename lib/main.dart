import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/screens/splash_screen.dart';
import 'package:glocure/screens/login_screen.dart';
import 'package:glocure/cubits/home_banner/home_banner_cubit.dart';
import 'package:glocure/cubits/middle_banner/middle_banner_cubit.dart';
import 'package:glocure/cubits/skin_genius/skin_genius_cubit.dart';
import 'package:glocure/cubits/top_products/top_products_cubit.dart';
import 'package:glocure/cubits/browse_categories/browse_categories_cubit.dart';
import 'package:glocure/cubits/discounted_products/discounted_products_cubit.dart';
import 'package:glocure/cubits/brand_logos/brand_logos_cubit.dart';
import 'package:glocure/cubits/bottom_banner/bottom_banner_cubit.dart';
import 'package:glocure/cubits/categories/categories_cubit.dart';
import 'package:glocure/cubits/category_products/category_products_cubit.dart';
import 'package:glocure/cubits/filter/filter_cubit.dart';
import 'package:glocure/cubits/cart/cart_cubit.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:glocure/services/api_service.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Set up token expiration callback
  ApiService.onTokenExpired = () {
    // Show session expired dialog
    _showSessionExpiredDialog();
  };

  runApp(const MyApp());
}

/// Show non-cancelable session expired dialog
void _showSessionExpiredDialog() {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissal by tapping outside
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your session has expired. Please login again to continue.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Close dialog
                  Navigator.of(dialogContext).pop();
                  
                  // Navigate to login screen
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Login Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => HomeBannerCubit()),
          BlocProvider(create: (_) => MiddleBannerCubit()),
          BlocProvider(create: (_) => SkinGeniusCubit()),
          BlocProvider(create: (_) => TopProductsCubit()),
          BlocProvider(create: (_) => BrowseCategoriesCubit()),
          BlocProvider(create: (_) => DiscountedProductsCubit()),
          BlocProvider(create: (_) => BrandLogosCubit()),
          BlocProvider(create: (_) => BottomBannerCubit()),
          BlocProvider(create: (_) => CategoriesCubit()),
          BlocProvider(create: (_) => CategoryProductsCubit()),
          BlocProvider(create: (_) => FilterCubit()),
          BlocProvider(create: (_) => CartCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
          builder: (context, child) {
            // Disable system text scaling to maintain consistent UI
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 1.01,
              ),
              child: child!,
            );
          },
        ),
      );
    });
  }
}
