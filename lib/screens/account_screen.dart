import 'package:flutter/material.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/widgets/common_bottom_sheet.dart';
import '../utils/auth_storage.dart';
import '../utils/wishlist_storage.dart';
import 'address_list_screen.dart';
import 'disclaimer_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoggingOut = false;

  /// Handle logout
  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Clear all local storage data
      await AuthStorage.clearAllData();
      await WishlistStorage.clearWishlist();

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show logout confirmation bottom sheet
  Future<void> _showLogoutBottomSheet() async {
    final confirmed = await CommonBottomSheet.show(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to log out?',
      primaryButtonText: 'Yes, Logout',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () => Navigator.pop(context, true),
      onSecondaryPressed: () => Navigator.pop(context, false),
    );

    if (confirmed == true) {
      await _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
        onBackPressed: () {
          MainNavigationScreen.navigateToHome(context);
        },
      ),
      body: _isLoggingOut
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF5C9A),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // My Profile
                _AccountMenuItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Order
                _AccountMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order',
                  onTap: () {
                    // TODO: Navigate to orders screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Orders - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Scan your progress
                _AccountMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Scan your progress',
                  onTap: () {
                    // TODO: Navigate to scan progress screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scan Progress - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Saved reports
                _AccountMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Saved reports',
                  onTap: () {
                    // TODO: Navigate to saved reports screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved Reports - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Address
                _AccountMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Notifications
                _AccountMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // TODO: Navigate to notifications screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Help Center
                _AccountMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    // TODO: Navigate to help center screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help Center - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // GloCure Disclaimer
                _AccountMenuItem(
                  icon: Icons.lock_outline,
                  title: 'GloCure Disclaimer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DisclaimerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Log Out
                GestureDetector(
                  onTap: _showLogoutBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: const Color(0xFFFF5C9A),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Log Out',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF5C9A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Account Menu Item Widget
class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
