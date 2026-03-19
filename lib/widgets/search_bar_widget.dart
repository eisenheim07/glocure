import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';

/// Custom Search Bar Widget
/// A simple search bar with search icon and placeholder text
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search products',
    this.onTap,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.search,
                  color: AppColors.gray400,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer version of Search Bar Widget
/// Shows loading state during refresh
class SearchBarShimmer extends StatelessWidget {
  const SearchBarShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
