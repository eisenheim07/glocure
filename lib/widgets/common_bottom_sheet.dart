import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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
    // Get the bottom padding for system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
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
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),

          // Divider
          Divider(
            color: AppColors.borderSecondary,
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
              color: AppColors.textMuted,
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
                        color: secondaryButtonColor ?? AppColors.backgroundTertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          secondaryButtonText!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
                      color: primaryButtonColor ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        primaryButtonText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
