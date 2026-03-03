import 'package:flutter/material.dart';
import '../models/judgeme_product_model.dart';
import '../utils/size_utils.dart';

/// Product Rating Widget
/// Shows star rating and review count below product price
class ProductRatingWidget extends StatelessWidget {
  final JudgemeProduct? product;
  final VoidCallback? onTap;

  const ProductRatingWidget({
    super.key,
    this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (product == null || product!.reviewsCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        child: Row(
          children: [
            // Star rating
            Row(
              children: List.generate(5, (index) {
                final rating = product!.averageRating;
                if (index < rating.floor()) {
                  // Full star
                  return Icon(
                    Icons.star,
                    size: 16.h,
                    color: const Color(0xFFFFA500),
                  );
                } else if (index < rating) {
                  // Half star
                  return Icon(
                    Icons.star_half,
                    size: 16.h,
                    color: const Color(0xFFFFA500),
                  );
                } else {
                  // Empty star
                  return Icon(
                    Icons.star_border,
                    size: 16.h,
                    color: Colors.grey.shade300,
                  );
                }
              }),
            ),
            
            SizedBox(width: 8.h),
            
            // Rating text
            Text(
              '${product!.averageRating.toStringAsFixed(1)} (${product!.reviewsCount} review${product!.reviewsCount > 1 ? 's' : ''})',
              style: TextStyle(
                fontSize: 13.fSize,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(width: 4.h),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 12.h,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}