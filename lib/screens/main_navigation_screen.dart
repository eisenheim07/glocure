import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glocure/screens/account_screen.dart';
import 'package:glocure/screens/categories_screen.dart';
import 'package:glocure/screens/home_screen.dart';
import 'package:glocure/screens/custom_webview_screen.dart';
import 'package:glocure/screens/order_screen.dart';
import '../config/api_config.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../utils/app_colors.dart';

/// Main Navigation Screen
/// Manages bottom navigation and screen switching
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();

  /// Static method to navigate to home from anywhere in the widget tree
  static void navigateToHome(BuildContext context) {
    final state = context.findAncestorStateOfType<MainNavigationScreenState>();
    state?.navigateToHome();
  }

  /// Static method to navigate to orders from anywhere in the widget tree
  static void navigateToOrders(BuildContext context) {
    final state = context.findAncestorStateOfType<MainNavigationScreenState>();
    state?.navigateToOrders();
  }
}

class MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  late int _currentIndex;
  DateTime? _lastBackPressTime;
  
  /// Public method to navigate to home tab
  void navigateToHome() {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  /// Public method to navigate to orders tab
  void navigateToOrders() {
    if (_currentIndex != 3) {
      setState(() {
        _currentIndex = 3;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addObserver(this);
    // Show status bar on home screen with multiple attempts
    _showStatusBar();

    // Try again after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _showStatusBar();
    });

    // And once more after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStatusBar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Show status bar when app comes to foreground
      _showStatusBar();
    }
  }

  void _showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    // Handle Scan button separately (index 2)
    if (index == 2) {
      _openSkinAnalysis();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _openSkinAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomWebViewScreen(
          title: 'Skin Analysis',
          url: ApiConfig.skinAnalysisUrl,
          requestCameraPermission: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adjust index for IndexedStack (since Scan is not in the list)
    final adjustedIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;

    // Create screens with visibility state
    final screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      OrderScreen(isVisible: _currentIndex == 3),
      const AccountScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        // If not on Home tab, navigate to Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // On Home tab: Double tap to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;

          // Show snackbar message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
              ),
            );
          }
          return;
        }

        // Second tap within 2 seconds: Exit app
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: adjustedIndex,
          children: screens,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
          ),
        ),
      ),
    );
  }
}
