import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:glocure/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? expandedIndex;

  final List<FAQItem> faqItems = [
    FAQItem(
      question: "How does the AI face scanner work?",
      answer: "Upload a selfie or use our camera. AI analyzes your skin and generates a detailed report in seconds.",
    ),
    FAQItem(
      question: "Can I return a product if I don't like it?",
      answer: "Yes, 30-day return policy for unopened products in original packaging.",
    ),
    FAQItem(
      question: "How fast is delivery?",
      answer: "Instant Delivery: 1-2 hours in select cities\nNormal Delivery: 2-3 business days nationwide",
    ),
    FAQItem(
      question: "Can I get personalized bundles?",
      answer: "Yes! AI skin analysis creates personalized recommendations. Contact experts for custom bundles.",
    ),
    FAQItem(
      question: "What is Elite Glo Premium Membership?",
      answer: "Premium benefits: Free delivery, early product access, member discounts, priority support.",
    ),
    FAQItem(
      question: "Is my data secure?",
      answer: "Yes! Industry-standard encryption protects your data. Skin analysis never shared with third parties.",
    ),
    FAQItem(
      question: "How can I contact customer support?",
      answer: "Email: info@glocure.com\nWhatsApp & Live Chat: 24/7 available",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: "Frequently Asked Questions",
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          final faqItem = faqItems[index];
          final isExpanded = expandedIndex == index;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faqItem.question,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textTertiary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Container(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                          child: Text(
                            faqItem.answer,
                            style: TextStyle(
                              fontSize: 13.fSize,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}