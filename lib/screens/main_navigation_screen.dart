import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/screens/account_screen.dart';
import 'package:glocure/screens/categories_screen.dart';
import 'package:glocure/screens/home_screen.dart';
import 'package:glocure/screens/custom_webview_screen.dart';
import 'package:glocure/screens/order_screen.dart';
import 'package:glocure/cubits/orders/orders_cubit.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';

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

class MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late int _currentIndex;
  DateTime? _lastBackPressTime;
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

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

      // Trigger orders loading after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.read<OrdersCubit>().showPendingTab();
            print('MainNavigationScreen: Triggered showPendingTab() from navigateToOrders');
          } catch (e) {
            print('MainNavigationScreen: Error triggering orders from navigateToOrders: $e');
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

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
    _fabAnimationController.dispose();
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
      _toggleFabMenu();
      return;
    }

    // Close FAB menu if open
    if (_isFabExpanded) {
      _toggleFabMenu();
    }

    // If clicking on Orders tab (index 3), force refresh
    if (index == 3 && _currentIndex != 3) {
      // First set the state to show the Orders screen
      setState(() {
        _currentIndex = index;
      });

      // Then trigger the orders loading after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Find the OrderScreen in the widget tree and trigger data loading
        final context = this.context;
        if (context.mounted) {
          try {
            context.read<OrdersCubit>().showPendingTab();
            print('MainNavigationScreen: Triggered showPendingTab() for Orders tab');
          } catch (e) {
            print('MainNavigationScreen: Error triggering orders: $e');
          }
        }
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });

    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _openSkinAnalysis() {
    _toggleFabMenu(); // Close the menu
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomWebViewScreen(
          title: 'Skin Analysis',
          url: ApiConfig.skinAnalysisUrl,
          requestCameraPermission: true,
          showAppBar: false,
        ),
      ),
    );
  }

  void _openHairAnalysis() {
    _toggleFabMenu(); // Close the menu
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomWebViewScreen(
          title: 'Hair Analysis',
          url: ApiConfig.hairAnalysisUrl,
          requestCameraPermission: true,
          showAppBar: false,
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
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: adjustedIndex,
              children: screens,
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onNavItemTapped,
                isFabExpanded: _isFabExpanded,
              ),
            ),
          ),

          // Overlay when FAB menu is expanded
          if (_isFabExpanded)
            GestureDetector(
              onTap: _toggleFabMenu,
              child: AnimatedOpacity(
                opacity: _isFabExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

          // Floating Action Buttons
          if (_isFabExpanded)
            Positioned(
              bottom: 140,
              left: MediaQuery.of(context).size.width / 2 - 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skin Analysis Button
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: _buildFabOption(
                      icon: Icons.face_outlined,
                      label: 'Skin Analysis',
                      onTap: _openSkinAnalysis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hair Analysis Button
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: _buildFabOption(
                      icon: Icons.psychology_outlined,
                      label: 'Hair Analysis',
                      onTap: _openHairAnalysis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
