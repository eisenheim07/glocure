import 'package:flutter/material.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'main_navigation_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
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
        child: Text('Orders Screen - Coming Soon'),
      ),
    );
  }
}
