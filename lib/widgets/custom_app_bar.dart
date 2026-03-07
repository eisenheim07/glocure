import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';
import '../utils/image_constant.dart';
import '../widgets/app_image.dart';
import '../widgets/wishlist_icon_with_badge.dart';
import '../screens/cart_screen.dart';

/// Custom App Bar with two predefined types:
/// Type 1 (Full): Logo + Elite Glow GIF + Notifications + Wishlist + Cart
/// Type 2 (Simple): Back arrow + Title
enum AppBarType { full, simple }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.type = AppBarType.full,
    this.title,
    this.onBackPressed,
    this.showBackButton = false, // Show back arrow in full type
    this.backgroundColor = Colors.white,
    this.toolbarHeight,
    this.onWishlistReturn, // Callback when returning from wishlist
  });

  final AppBarType type;
  final String? title; // Used only for simple type
  final VoidCallback? onBackPressed; // Custom back action
  final bool showBackButton; // Show back arrow in full type (except home)
  final Color? backgroundColor;
  final double? toolbarHeight;
  final VoidCallback? onWishlistReturn; // Callback when returning from wishlist

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: type == AppBarType.full ? _buildFullAppBar(context) : _buildSimpleAppBar(context),
      ),
    );
  }

  /// Type 1: Full AppBar with logo and action icons
  Widget _buildFullAppBar(BuildContext context) {
    return AppBar(
      leadingWidth: showBackButton ? 56.h : 140.h,
      toolbarHeight: toolbarHeight ?? 60.h,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0.0,
      elevation: 0,
      titleSpacing: showBackButton ? 0 : 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : Container(
              margin: EdgeInsets.only(left: 16.h),
              child: Image(
                image: AssetImage(ImageConstant.imgGlocureLogo),
                fit: BoxFit.contain,
              ),
            ),
      title: showBackButton
          ? Image.asset(
              ImageConstant.imgGlocureLogo,
              height: 40,
              fit: BoxFit.contain,
            )
          : null,
      automaticallyImplyLeading: false,
      actions: [
        SmartImage(
          source: ImageConstant.imgGlocureGif,
          width: 60,
          height: 28,
          onTap: () {
            // Elite Glow GIF tap action (currently no action)
          },
        ),
        const SizedBox(width: 4),
        SmartImage(
          source: ImageConstant.icNotifications,
          width: 60,
          height: 34,
          onTap: () {
            // Notifications tap action (currently no action)
          },
        ),
        const SizedBox(width: 12),
        WishlistIconWithBadge(
          width: 60,
          height: 34,
          onWishlistReturn: onWishlistReturn,
        ),
        const SizedBox(width: 12),
        SmartImage(
          source: ImageConstant.icCart,
          width: 60,
          height: 34,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CartScreen(),
              ),
            );
          },
        ),
        SizedBox(width: 16.h),
      ],
    );
  }

  /// Type 2: Simple AppBar with back arrow and title
  Widget _buildSimpleAppBar(BuildContext context) {
    return AppBar(
      leadingWidth: 56.h,
      toolbarHeight: toolbarHeight ?? 60.h,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0.0,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: Text(
        title ?? '',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? 60.h);
}
