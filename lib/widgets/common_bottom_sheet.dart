import 'package:flutter/material.dart';

/// Common Bottom Sheet Widget
/// Reusable bottom sheet with consistent styling across the app
class CommonBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final Widget? icon;
  final bool isIconEnabled;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool isDismissible;
  final Color? primaryButtonColor;
  final Color? secondaryButtonColor;

  const CommonBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.isIconEnabled = false,
    required this.primaryButtonText,
    this.secondaryButtonText,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.isDismissible = true,
    this.primaryButtonColor,
    this.secondaryButtonColor,
  });

  /// Show the bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    Widget? icon,
    bool isIconEnabled = false,
    required String primaryButtonText,
    String? secondaryButtonText,
    required VoidCallback onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool isDismissible = true,
    Color? primaryButtonColor,
    Color? secondaryButtonColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      builder: (context) => CommonBottomSheet(
        title: title,
        message: message,
        icon: icon,
        isIconEnabled: isIconEnabled,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        isDismissible: isDismissible,
        primaryButtonColor: primaryButtonColor,
        secondaryButtonColor: secondaryButtonColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Icon (if enabled and provided)
          if (isIconEnabled && icon != null) ...[
            icon!,
            const SizedBox(height: 12),
          ],

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),

          // Divider
          Divider(
            color: Colors.grey.shade200,
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              // Secondary button (if provided)
              if (secondaryButtonText != null) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: onSecondaryPressed ?? () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: secondaryButtonColor ?? Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          secondaryButtonText!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Primary button
              Expanded(
                child: GestureDetector(
                  onTap: onPrimaryPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: primaryButtonColor ?? const Color(0xFFFF5C9A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        primaryButtonText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
