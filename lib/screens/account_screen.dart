import 'package:flutter/material.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'main_navigation_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
        onBackPressed: () {
          // Navigate to home tab in MainNavigationScreen
          MainNavigationScreen.navigateToHome(context);
        },
      ),
      body: const Center(
        child: Text('Account Screen - Coming Soon'),
      ),
    );
  }
}
