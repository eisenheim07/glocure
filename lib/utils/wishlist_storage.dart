/// Wishlist Storage
/// Manages local storage of wishlist items using shared_preferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/wishlist_item_model.dart';
import 'app_logger.dart';

class WishlistStorage {
  static const String _wishlistKey = 'user_wishlist';

  /// Add item to wishlist
  static Future<bool> addToWishlist(WishlistItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = await getWishlist();

      // Check if item already exists
      final existingIndex = wishlist.indexWhere(
        (w) => w.productId == item.productId,
      );

      if (existingIndex != -1) {
        // Item already in wishlist, update it
        wishlist[existingIndex] = item;
        AppLogger.success('Updated item in wishlist: ${item.productId}');
      } else {
        // Add new item
        wishlist.add(item);
        AppLogger.success('Added item to wishlist: ${item.productId}');
      }

      // Save to storage
      final jsonList = wishlist.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_wishlistKey, jsonString);

      AppLogger.info('Wishlist saved. Total items: ${wishlist.length}');
      return true;
    } catch (e) {
      AppLogger.error('Error adding to wishlist: $e');
      return false;
    }
  }

  /// Remove item from wishlist
  static Future<bool> removeFromWishlist(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = await getWishlist();

      // Remove item
      wishlist.removeWhere((item) => item.productId == productId);

      // Save to storage
      final jsonList = wishlist.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_wishlistKey, jsonString);

      AppLogger.success('Removed item from wishlist: $productId');
      AppLogger.info('Wishlist saved. Total items: ${wishlist.length}');
      return true;
    } catch (e) {
      AppLogger.error('Error removing from wishlist: $e');
      return false;
    }
  }

  /// Get all wishlist items
  static Future<List<WishlistItem>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_wishlistKey);

      if (jsonString == null || jsonString.isEmpty) {
        AppLogger.info('Wishlist is empty');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final wishlist = jsonList
          .map((json) => WishlistItem.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by addedAt (newest first)
      wishlist.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      AppLogger.info('Loaded wishlist. Total items: ${wishlist.length}');
      return wishlist;
    } catch (e) {
      AppLogger.error('Error loading wishlist: $e');
      return [];
    }
  }

  /// Check if product is in wishlist
  static Future<bool> isInWishlist(String productId) async {
    try {
      final wishlist = await getWishlist();
      final isInWishlist = wishlist.any((item) => item.productId == productId);
      AppLogger.info('Product $productId in wishlist: $isInWishlist');
      return isInWishlist;
    } catch (e) {
      AppLogger.error('Error checking wishlist: $e');
      return false;
    }
  }

  /// Get wishlist item by product ID
  static Future<WishlistItem?> getWishlistItem(String productId) async {
    try {
      final wishlist = await getWishlist();
      return wishlist.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );
    } catch (e) {
      AppLogger.warning('Item not found in wishlist: $productId');
      return null;
    }
  }

  /// Clear entire wishlist
  static Future<bool> clearWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wishlistKey);
      AppLogger.success('Wishlist cleared');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing wishlist: $e');
      return false;
    }
  }

  /// Get wishlist count
  static Future<int> getWishlistCount() async {
    try {
      final wishlist = await getWishlist();
      return wishlist.length;
    } catch (e) {
      AppLogger.error('Error getting wishlist count: $e');
      return 0;
    }
  }
}
