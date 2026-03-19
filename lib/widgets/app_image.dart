import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SmartImage extends StatelessWidget {
  final String source;
  final double width;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const SmartImage({
    super.key,
    required this.source,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.onTap,
  });

  bool get _isNetwork => source.startsWith('http');
  bool get _isSvg => source.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (_isSvg) {
      image = _isNetwork
          ? SvgPicture.network(
        source,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) =>
            SizedBox(width: width, height: height, child: const Center(child: CircularProgressIndicator())),
      )
          : SvgPicture.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) =>
            SizedBox(width: width, height: height, child: const Center(child: CircularProgressIndicator())),
      );
    } else {
      image = _isNetwork
          ? Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            SizedBox(
              width: width,
              height: height,
              child: const Center(child: Icon(Icons.broken_image)),
            ),
      )
          : Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            SizedBox(
              width: width,
              height: height,
              child: const Center(child: Icon(Icons.broken_image)),
            ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: image,
    );
  }
}