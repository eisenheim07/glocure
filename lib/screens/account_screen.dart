import 'package:flutter/material.dart';
import 'package:glocure/screens/wishlist_screen.dart';
import 'package:glocure/utils/size_utils.dart';

import '../utils/image_constant.dart';
import '../widgets/app_image.dart';
import '../widgets/custom_app_bar.dart';
import 'cart_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showDefaultLogo: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Image.asset(ImageConstant.imgGlocureLogo, height: 40, fit: BoxFit.contain),
        actions: [
          SmartImage(source: ImageConstant.imgGlocureGif, width: 60, height: 28, onTap: () {}),
          const SizedBox(width: 4),
          SmartImage(source: ImageConstant.icNotifications, width: 60, height: 28, onTap: () {}),
          const SizedBox(width: 12),
          SmartImage(
              source: ImageConstant.icWishlist,
              width: 60,
              height: 28,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WishlistScreen(),
                  ),
                );
              }),
          const SizedBox(width: 12),
          SmartImage(
              source: ImageConstant.icCart,
              width: 60,
              height: 28,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
