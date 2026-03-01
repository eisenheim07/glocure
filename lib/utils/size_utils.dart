import 'package:flutter/material.dart';

// These are the Viewport values of your Figma Design.

// These are used in the code as a reference to create your UI Responsively.
const num FIGMA_DESIGN_WIDTH = 393;
const num FIGMA_DESIGN_HEIGHT = 852;
const num FIGMA_DESIGN_STATUS_BAR = 0;

extension ResponsiveExtension on num {
  double get _width => SizeUtils.width;
  double get h => ((this * _width) / FIGMA_DESIGN_WIDTH);
  double get fSize => ((this * _width) / FIGMA_DESIGN_WIDTH);
}

extension FormatExtension on double {
  double toDoubleValue({int fractionDigits = 2}) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}

extension DoubleExtensions on double {
  // Fixed method to check if double is non-zero and return default if zero or less
  double isNonZero({num defaultValue = 0.0}) {
    return this > 0 ? this : defaultValue.toDouble();
  }
}

enum DeviceType { mobile, tablet, desktop }

class Sizer extends StatelessWidget {
  const Sizer({Key? key, required this.builder}) : super(key: key);

  // Fixed builder signature: 3 arguments expected, not 1 or 2
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

// ignore_for_file: must_be_immutable
class SizeUtils {
  static late BoxConstraints boxConstraints;

  /// Device's Orientation
  static late Orientation orientation;

  /// Type of Device
  static late DeviceType deviceType;

  /// Device's Height
  static late double height;

  /// Device's Width
  static late double width;

  static void setScreenSize(
    BoxConstraints constraints,
    Orientation currentOrientation,
  ) {
    boxConstraints = constraints;
    orientation = currentOrientation;

    if (orientation == Orientation.portrait) {
      width = boxConstraints.maxWidth.isNonZero(
        defaultValue: FIGMA_DESIGN_WIDTH,
      );
      height = boxConstraints.maxHeight.isNonZero();
    } else {
      height = boxConstraints.maxWidth.isNonZero();
      width = boxConstraints.maxHeight.isNonZero();
    }

    // Basic device type detection based on width (can be customized)
    if (width > 600) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.mobile;
    }
  }
}