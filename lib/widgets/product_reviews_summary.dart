import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/reviews/reviews_cubit.dart';
import '../models/judgeme_reviews_model.dart';
import '../screens/reviews_screen.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';

/// Product Reviews Summary Widget
/// Shows first 2 reviews and "View All" button on product details screen
class ProductReviewsSummary extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductReviewsSummary({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        if (state is ReviewsLoading) {
          return Container(
            padding: EdgeInsets.all(16.h),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (state is ReviewsLoaded && state.reviews.isNotEmpty) {
          final limitedReviews = state.reviews.take(2).toList();
          final hasMoreReviews = state.reviews.length > 2;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reviews header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Reviews',
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    if (hasMoreReviews)
                      GestureDetector(
                        onTap: () => _navigateToAllReviews(context),
                        child: Text(
                          'View All (${state.reviews.length})',
                          style: TextStyle(
                            fontSize: 13.fSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Review cards
                ...limitedReviews.map((review) => _ReviewSummaryCard(
                  review: review,
                )).toList(),
                
                // View all button (if more reviews exist)
                if (hasMoreReviews) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _navigateToAllReviews(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View All ${state.reviews.length} Reviews',
                        style: TextStyle(
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // No reviews or error state
        return const SizedBox.shrink();
      },
    );
  }

  void _navigateToAllReviews(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final JudgemeReview review;

  const _ReviewSummaryCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: AppColors.gray600,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info and rating
          Row(
            children: [
              // Reviewer avatar
              Container(
                width: 32.h,
                height: 32.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.reviewerInitials,
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 8.h),
              
              // Reviewer name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      review.formattedDate,
                      style: TextStyle(
                        fontSize: 10.fSize,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 12.h,
                    color: AppColors.warning,
                  );
                }),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // Review title (if exists)
          if (review.title.isNotEmpty) ...[
            Text(
              review.title,
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
          ],
          
          // Review body (truncated)
          if (review.body.isNotEmpty) ...[
            Text(
              review.body,
              style: TextStyle(
                fontSize: 11.fSize,
                color: AppColors.gray700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Verified buyer badge
          if (review.verifiedBuyer != null) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6.h,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.success,
                  width: 1,
                ),
              ),
              child: Text(
                'Verified Buyer',
                style: TextStyle(
                  fontSize: 8.fSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}