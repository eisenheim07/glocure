import 'package:flutter/material.dart';

/// Application Color System
/// Defines all colors used throughout the app with light and dark theme support
class AppColors {
  AppColors._();

  // ============================================================================
  // MAIN BRAND COLORS (Primary Palette)
  // ============================================================================
  
  /// Primary brand color - Pink/Magenta
  static const Color primary = Color(0xFFFF5C9A);
  static const Color primaryLight = Color(0xFFFF8BB5);
  static const Color primaryDark = Color(0xFFE5407F);
  
  /// Secondary brand color - Light pink for backgrounds
  static const Color secondary = Color(0xFFFFE9F0);
  static const Color secondaryLight = Color(0xFFFFF2F7);
  static const Color secondaryDark = Color(0xFFFFD6E5);

  // ============================================================================
  // NEUTRAL COLORS (Grayscale Palette)
  // ============================================================================
  
  /// Pure black and white
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  /// Dark grays for text and primary content
  static const Color gray900 = Color(0xFF1A1A1A); // Primary text
  static const Color gray800 = Color(0xFF333333); // Secondary text
  static const Color gray700 = Color(0xFF4A4A4A); // Tertiary text
  static const Color gray600 = Color(0xFF666666); // Muted text
  
  /// Medium grays for borders and dividers
  static const Color gray500 = Color(0xFF808080); // Disabled text
  static const Color gray400 = Color(0xFF999999); // Placeholder text
  static const Color gray300 = Color(0xFFCCCCCC); // Borders
  static const Color gray200 = Color(0xFFE5E5E5); // Light borders
  static const Color gray100 = Color(0xFFF5F5F5); // Background
  static const Color gray50 = Color(0xFFFAFAFA);  // Light background

  // ============================================================================
  // SEMANTIC COLORS (Status & Feedback)
  // ============================================================================
  
  /// Success colors - Green
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF5EFC82);
  static const Color successDark = Color(0xFF009624);
  
  /// Error colors - Red
  static const Color error = Color(0xFFE53E3E);
  static const Color errorLight = Color(0xFFFC8181);
  static const Color errorDark = Color(0xFFC53030);
  
  /// Warning colors - Orange
  static const Color warning = Color(0xFFFF8C00);
  static const Color warningLight = Color(0xFFFBB040);
  static const Color warningDark = Color(0xFFE07B00);
  
  /// Info colors - Blue
  static const Color info = Color(0xFF3182CE);
  static const Color infoLight = Color(0xFF63B3ED);
  static const Color infoDark = Color(0xFF2C5282);

  // ============================================================================
  // THEME-SPECIFIC COLOR SCHEMES
  // ============================================================================
  
  /// Light Theme Colors
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: primary,
    primaryContainer: secondary,
    secondary: gray600,
    secondaryContainer: gray100,
    surface: white,
    surfaceContainerHighest: gray50,
    surfaceContainerHigh: gray100,
    surfaceContainer: gray200,
    onPrimary: white,
    onPrimaryContainer: primary,
    onSecondary: white,
    onSecondaryContainer: gray800,
    onSurface: gray900,
    onSurfaceVariant: gray600,
    outline: gray300,
    outlineVariant: gray200,
    error: error,
    onError: white,
    errorContainer: errorLight,
    onErrorContainer: errorDark,
  );
  
  /// Dark Theme Colors (same as light for now, as requested)
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primary,
    primaryContainer: secondary,
    secondary: gray600,
    secondaryContainer: gray100,
    surface: white,
    surfaceContainerHighest: gray50,
    surfaceContainerHigh: gray100,
    surfaceContainer: gray200,
    onPrimary: white,
    onPrimaryContainer: primary,
    onSecondary: white,
    onSecondaryContainer: gray800,
    onSurface: gray900,
    onSurfaceVariant: gray600,
    outline: gray300,
    outlineVariant: gray200,
    error: error,
    onError: white,
    errorContainer: errorLight,
    onErrorContainer: errorDark,
  );

  // ============================================================================
  // CONTEXT-AWARE COLOR GETTERS
  // ============================================================================
  
  /// Get colors based on current theme
  static ColorScheme of(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  
  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================================================
  // COMMON COLOR COMBINATIONS
  // ============================================================================
  
  /// Background colors
  static const Color backgroundPrimary = white;
  static const Color backgroundSecondary = gray50;
  static const Color backgroundTertiary = gray100;
  
  /// Text colors
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray800;
  static const Color textTertiary = gray600;
  static const Color textMuted = gray500;
  static const Color textDisabled = gray400;
  
  /// Border colors
  static const Color borderPrimary = gray300;
  static const Color borderSecondary = gray200;
  static const Color borderLight = gray100;
  
  /// Shadow colors
  static Color shadowLight = black.withValues(alpha: 0.1);
  static Color shadowMedium = black.withValues(alpha: 0.15);
  static Color shadowDark = black.withValues(alpha: 0.25);
  
  /// Overlay colors
  static Color overlayLight = black.withValues(alpha: 0.3);
  static Color overlayMedium = black.withValues(alpha: 0.5);
  static Color overlayDark = black.withValues(alpha: 0.7);

  // ============================================================================
  // COMPONENT-SPECIFIC COLORS
  // ============================================================================
  
  /// Button colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = gray100;
  static const Color buttonDisabled = gray300;
  
  /// Input field colors
  static const Color inputBackground = white;
  static const Color inputBorder = gray300;
  static const Color inputBorderFocused = primary;
  static const Color inputBorderError = error;
  
  /// Card colors
  static const Color cardBackground = white;
  static const Color cardBorder = gray200;
  
  /// Navigation colors
  static const Color navigationBackground = white;
  static const Color navigationBorder = gray200;
  static const Color navigationSelected = primary;
  static const Color navigationUnselected = gray500;
  
  /// Shimmer colors
  static const Color shimmerBase = gray300;
  static const Color shimmerHighlight = gray100;
}

/// Extension to easily access theme colors from context
extension AppColorsExtension on BuildContext {
  ColorScheme get colors => AppColors.of(this);
  bool get isDarkMode => AppColors.isDark(this);
}