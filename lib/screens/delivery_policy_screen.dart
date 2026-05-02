import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:glocure/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class DeliveryPolicyScreen extends StatelessWidget {
  const DeliveryPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: "Delivery Policy",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            
            _buildSectionTitle("Delivery Options:"),
            SizedBox(height: 16.h),
            
            _buildSubSection(
              title: "Instant Delivery:",
              content: "Products will be delivered within 1-2 hours of placing the order.",
            ),
            SizedBox(height: 16.h),
            
            _buildSubSection(
              title: "Normal Delivery:",
              content: "Products will be delivered within 2 days.",
            ),
            SizedBox(height: 24.h),
            
            _buildSectionTitle("Refund Eligibility:"),
            SizedBox(height: 12.h),
            _buildContentText(
              "Currently available in select cities. Coverage will expand as per our operational capabilities.",
            ),
            SizedBox(height: 24.h),
            
            _buildSectionTitle("Delivery Partners:"),
            SizedBox(height: 12.h),
            _buildContentText(
              "GloCure partners with verified delivery vendors to ensure safe and timely delivery.",
            ),
            SizedBox(height: 24.h),
            
            _buildSectionTitle("Customer Responsibilities:"),
            SizedBox(height: 16.h),
            
            _buildBulletPoint("Provide accurate delivery information."),
            SizedBox(height: 8.h),
            _buildBulletPoint("Accept delivery at the provided address."),
            SizedBox(height: 24.h),
            
            _buildInfoCard(),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSubSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h, right: 8.w),
              width: 4.w,
              height: 4.h,
              decoration: const BoxDecoration(
                color: AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13.fSize,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.fSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 8.h, right: 8.w),
          width: 4.w,
          height: 4.h,
          decoration: const BoxDecoration(
            color: AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.fSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8.w),
              Text(
                "Important Note",
                style: TextStyle(
                  fontSize: 15.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "Delivery times may vary based on location, weather conditions, and product availability. We'll keep you updated with real-time tracking information.",
            style: TextStyle(
              fontSize: 13.fSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}