import 'package:flutter/material.dart';
import '../utils/auth_storage.dart';
import '../utils/wishlist_storage.dart';
import '../screens/login_screen.dart';
import '../widgets/common_bottom_sheet.dart';

/// API Configuration Template
/// Copy this file to api_config.dart and fill in your actual credentials
/// 
/// IMPORTANT: Never commit api_config.dart to version control
/// This file should be added to .gitignore
class ApiConfig {
  // Shopify Admin Access Token
  // Get this from your Shopify admin panel
  static const String shopifyAdminAccessToken = 'YOUR_SHOPIFY_ADMIN_ACCESS_TOKEN_HERE';

  // Access token for authentication
  static const String accessToken = 'YOUR_SHOPIFY_STOREFRONT_ACCESS_TOKEN_HERE';

  // Base URL for the GraphQL API
  static const String baseUrl = 'https://your-store.myshopify.com/api/2025-01/graphql.json';

  // Admin API (used for menu queries)
  static const String adminBaseUrl = 'https://your-store.myshopify.com/admin/api/2023-01/graphql.json';

  // Admin URL alias for orders API
  static const String adminUrl = adminBaseUrl;

  // Video consultation url
  static const String consultUrl = "https://www.your-domain.com/pages/dermatologist-video-consultation";

  // Skin analysis url
  static const String skinAnalysisUrl = "https://www.your-domain.com/pages/skin-analysis";

  // Hair analysis url
  static const String hairAnalysisUrl = "https://www.your-domain.com/pages/hair-analysis";

  // Order tracking Url
  static const String orderTrackingUrl = "https://www.delhivery.com/tracking";

  // Delhivery API Configuration
  static const String delhiveryBaseUrl = 'https://track.delhivery.com';
  static const String delhiveryApiToken = 'YOUR_DELHIVERY_API_TOKEN_HERE';

  // PayU Payment Gateway Configuration
  static const String payuMerchantKey = 'YOUR_PAYU_MERCHANT_KEY';
  static const String payuMerchantSalt = 'YOUR_PAYU_MERCHANT_SALT';
  static const bool payuIsProduction = true; // Set to true for production

  static bool getUserType() => IS_GUEST_LOGIN;
  static bool IS_GUEST_LOGIN = false;

  /// Handle logout - Clear all data and navigate to login
  static Future<void> handleLogout(BuildContext context) async {
    try {
      // Clear all local storage data
      await AuthStorage.clearAllData();
      await WishlistStorage.clearWishlist();
      
      // Clear guest login flag
      IS_GUEST_LOGIN = false;

      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// Show logout confirmation bottom sheet
  static Future<void> showLogoutBottomSheet(
    BuildContext context, {
    String? title,
    String? message,
    String? primaryButtonText,
    String? secondaryButtonText,
  }) async {
    final confirmed = await CommonBottomSheet.show(
      context: context,
      title: title ?? 'Logout',
      message: message ?? 'Are you sure you want to log out?',
      primaryButtonText: primaryButtonText ?? 'Yes, Logout',
      secondaryButtonText: secondaryButtonText ?? 'Cancel',
      onPrimaryPressed: () => Navigator.pop(context, true),
      onSecondaryPressed: () => Navigator.pop(context, false),
    );

    if (confirmed == true) {
      await handleLogout(context);
    }
  }
}
