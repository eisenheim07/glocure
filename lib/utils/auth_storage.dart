import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Authentication storage helper
/// Manages storing and retrieving authentication tokens and user preferences
class AuthStorage {
  static const String _accessTokenKey = 'customer_access_token';
  static const String _expiresAtKey = 'token_expires_at';
  static const String _languageSelectedKey = 'language_selected';
  static const String _cartIdKey = 'cart_id';

  /// Save access token and expiry date
  static Future<void> saveToken(String accessToken, String expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_expiresAtKey, expiresAt);
  }

  /// Get access token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get token expiry date
  static Future<String?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expiresAtKey);
  }

  /// Check if user is logged in and token is valid
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    AppLogger.info("CUSTOMER_ACCESS_TOKEN ===> $token");
    if (token == null) return false;

    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return false;

    // Check if token is expired
    final expiryDate = DateTime.parse(expiresAt);
    return DateTime.now().isBefore(expiryDate);
  }

  /// Check if token is expired (returns true if expired)
  static Future<bool> isTokenExpired() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return true;

    try {
      final expiryDate = DateTime.parse(expiresAt);
      final isExpired = DateTime.now().isAfter(expiryDate);
      
      if (isExpired) {
        AppLogger.warning("Token expired at: $expiresAt");
      }
      
      return isExpired;
    } catch (e) {
      AppLogger.error("Error parsing expiry date: $e");
      return true;
    }
  }

  /// Save language selection status
  static Future<void> setLanguageSelected(bool selected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageSelectedKey, selected);
  }

  /// Check if language has been selected
  static Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  /// Clear all authentication data (including language selection and cart ID)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppLogger.info("All user data cleared (including cart ID)");
  }

  /// Clear only authentication data (keep language selection)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_expiresAtKey);
    AppLogger.info("Authentication data cleared");
  }

  /// Save cart ID
  static Future<void> saveCartId(String cartId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartIdKey, cartId);
    AppLogger.info("Cart ID saved: $cartId");
  }

  /// Get cart ID
  static Future<String?> getCartId() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString(_cartIdKey);
    AppLogger.info("Cart ID retrieved: $cartId");
    return cartId;
  }

  /// Clear cart ID
  static Future<void> clearCartId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartIdKey);
    AppLogger.info("Cart ID cleared");
  }
}
