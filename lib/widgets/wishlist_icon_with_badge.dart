import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/wishlist_storage.dart';
import '../utils/image_constant.dart';
import '../widgets/app_image.dart';
import '../screens/wishlist_screen.dart';

/// Wishlist Icon with Badge
/// Shows a red dot indicator when there are items in the wishlist
class WishlistIconWithBadge extends StatefulWidget {
  final VoidCallback? onWishlistReturn;
  final double width;
  final double height;

  const WishlistIconWithBadge({
    super.key,
    this.onWishlistReturn,
    this.width = 60,
    this.height = 34,
  });

  @override
  State<WishlistIconWithBadge> createState() => _WishlistIconWithBadgeState();
}

class _WishlistIconWithBadgeState extends State<WishlistIconWithBadge> {
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWishlistCount();
    // Register this widget to receive wishlist updates
    WishlistNotifier.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    // Unregister listener
    WishlistNotifier.removeListener(_onWishlistChanged);
    super.dispose();
  }

  /// Handle wishlist changes from other parts of the app
  void _onWishlistChanged() {
    _loadWishlistCount();
  }

  /// Load wishlist count from storage
  Future<void> _loadWishlistCount() async {
    final count = await WishlistStorage.getWishlistCount();
    if (mounted) {
      setState(() {
        _wishlistCount = count;
      });
    }
  }

  /// Handle wishlist icon tap
  Future<void> _onWishlistTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WishlistScreen(),
      ),
    );

    // Reload wishlist count after returning
    await _loadWishlistCount();

    // Notify parent that we returned from wishlist
    widget.onWishlistReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Wishlist Icon
        SmartImage(
          source: ImageConstant.icWishlist,
          width: widget.width,
          height: widget.height,
          onTap: _onWishlistTap,
        ),

        // Badge Dot (only show if wishlist has items)
        if (_wishlistCount > 0)
          Positioned(
            top: 4,
            right: 8,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Wishlist Notifier
/// Simple notifier to update wishlist badge across the app
class WishlistNotifier {
  static final List<VoidCallback> _listeners = [];

  /// Add listener for wishlist changes
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners that wishlist has changed
  static void notifyWishlistChanged() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
