import 'package:flutter/material.dart';
import 'dart:math' as math;

// These are the Viewport values of your Figma Design.
// These are used in the code as a reference to create your UI Responsively.
const num FIGMA_DESIGN_WIDTH = 393;
const num FIGMA_DESIGN_HEIGHT = 852;
const num FIGMA_DESIGN_STATUS_BAR = 0;

extension ResponsiveExtension on num {
  /// Get responsive width
  double get w => SizeUtils.getResponsiveWidth(this);
  
  /// Get responsive height
  double get h => SizeUtils.getResponsiveHeight(this);
  
  /// Get responsive font size
  double get fSize => SizeUtils.getResponsiveFontSize(this);
  
  /// Get responsive radius
  double get r => SizeUtils.getResponsiveRadius(this);
}

extension FormatExtension on double {
  double toDoubleValue({int fractionDigits = 2}) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}

extension DoubleExtensions on double {
  double isNonZero({num defaultValue = 0.0}) {
    return this > 0 ? this : defaultValue.toDouble();
  }
}

enum DeviceType { mobile, tablet, desktop }

class Sizer extends StatelessWidget {
  const Sizer({Key? key, required this.builder}) : super(key: key);

  final Widget Function(BuildContext context, BoxConstraints constraints, Orientation orientation) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            SizeUtils.setScreenSize(constraints, orientation);
            return builder(context, constraints, orientation);
          },
        );
      },
    );
  }
}

class SizeUtils {
  static late BoxConstraints boxConstraints;
  static late Orientation orientation;
  static late DeviceType deviceType;
  static late double height;
  static late double width;
  static late double _scaleWidth;
  static late double _scaleHeight;
  static late double _scaleFactor;

  static void setScreenSize(
    BoxConstraints constraints,
    Orientation currentOrientation,
  ) {
    boxConstraints = constraints;
    orientation = currentOrientation;

    if (orientation == Orientation.portrait) {
      width = boxConstraints.maxWidth.isNonZero(defaultValue: FIGMA_DESIGN_WIDTH);
      height = boxConstraints.maxHeight.isNonZero(defaultValue: FIGMA_DESIGN_HEIGHT);
    } else {
      width = boxConstraints.maxHeight.isNonZero(defaultValue: FIGMA_DESIGN_WIDTH);
      height = boxConstraints.maxWidth.isNonZero(defaultValue: FIGMA_DESIGN_HEIGHT);
    }

    // Calculate scale factors
    _scaleWidth = width / FIGMA_DESIGN_WIDTH;
    _scaleHeight = height / FIGMA_DESIGN_HEIGHT;
    
    // Use the minimum scale factor to maintain aspect ratio
    _scaleFactor = math.min(_scaleWidth, _scaleHeight);

    // Device type detection
    if (width > 600) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.mobile;
    }
  }

  /// Get responsive width based on Figma design
  static double getResponsiveWidth(num figmaWidth) {
    return (figmaWidth * _scaleWidth).clamp(0.0, width);
  }

  /// Get responsive height based on Figma design
  static double getResponsiveHeight(num figmaHeight) {
    return (figmaHeight * _scaleHeight).clamp(0.0, height);
  }

  /// Get responsive font size with better scaling
  static double getResponsiveFontSize(num figmaFontSize) {
    // Use scale factor but with limits to prevent too small or too large text
    double scaledSize = figmaFontSize * _scaleFactor;
    
    // Apply min/max constraints for readability
    if (figmaFontSize <= 12) {
      return scaledSize.clamp(10.0, 14.0);
    } else if (figmaFontSize <= 16) {
      return scaledSize.clamp(12.0, 18.0);
    } else if (figmaFontSize <= 20) {
      return scaledSize.clamp(14.0, 24.0);
    } else {
      return scaledSize.clamp(16.0, 32.0);
    }
  }

  /// Get responsive radius for rounded corners
  static double getResponsiveRadius(num figmaRadius) {
    return (figmaRadius * _scaleFactor).clamp(0.0, figmaRadius * 1.5);
  }
}
