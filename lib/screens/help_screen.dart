import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/custom_app_bar.dart';
import 'faq_screen.dart';
import 'customer_support_screen.dart';
import 'delivery_policy_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: "Help Center",
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(12.w),
          children: [
            _AccountMenuItem(
              icon: Icons.question_answer,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              onTap: () => _navigateToFAQs(context),
            ),
            SizedBox(height: 8.h),

            _AccountMenuItem(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Policy',
              subtitle: 'Shipping and delivery information',
              onTap: () => _navigateToDeliveryPolicy(context),
            ),
            SizedBox(height: 8.h),

            _AccountMenuItem(
              icon: Icons.support_agent,
              title: 'Customer Support',
              subtitle: 'Contact our support team',
              onTap: () => _showContactOptions(context),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _navigateToFAQs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQScreen()),
    );
  }

  void _navigateToDeliveryPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryPolicyScreen()),
    );
  }

  void _navigateToReturnPolicy(BuildContext context) {
    // Navigate to return policy screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return policy screen coming soon')),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    // Navigate to privacy policy screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy screen coming soon')),
    );
  }

  void _navigateToTerms(BuildContext context) {
    // Navigate to terms screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms & conditions screen coming soon')),
    );
  }

  void _showContactOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerSupportScreen()),
    );
  }

  void _startLiveChat(BuildContext context) {
    // Implement live chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live chat feature coming soon')),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Account Menu Item Widget
class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF5C9A),
                size: 22,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.fSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
