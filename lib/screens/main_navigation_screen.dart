import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glocure/screens/account_screen.dart';
import 'package:glocure/screens/categories_screen.dart';
import 'package:glocure/screens/home_screen.dart';
import 'package:glocure/screens/custom_webview_screen.dart';
import 'package:glocure/screens/order_screen.dart';
import '../config/api_config.dart';
import '../widgets/custom_bottom_nav_bar.dart';

/// Main Navigation Screen
/// Manages bottom navigation and screen switching
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const OrderScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
        statusBarColor: Colors.white,
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

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
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
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}
