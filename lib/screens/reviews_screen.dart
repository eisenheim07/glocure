import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/reviews/reviews_cubit.dart';
import '../models/judgeme_reviews_model.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch reviews when screen loads
    context.read<ReviewsCubit>().fetchReviews(widget.productId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more reviews when near bottom
      context.read<ReviewsCubit>().loadMoreReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Reviews',
      ),
      body: BlocBuilder<ReviewsCubit, ReviewsState>(
        builder: (context, state) {
          if (state is ReviewsLoading) {
            return _buildLoadingShimmer();
          }

          if (state is ReviewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 54.h,
                    color: AppColors.gray400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load reviews',
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: AppColors.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReviewsCubit>().refreshReviews();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.h,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ReviewsLoaded) {
            if (state.reviews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 54.h,
                      color: AppColors.gray400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Reviews Yet',
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Be the first to review this product',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<ReviewsCubit>().refreshReviews(),
              color: const Color(0xFFFF5C9A),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16.h),
                itemCount: state.reviews.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.reviews.length) {
                    // Loading indicator for pagination
                    return Padding(
                      padding: EdgeInsets.all(16.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5C9A),
                        ),
                      ),
                    );
                  }

                  final review = state.reviews[index];
                  return _ReviewCard(review: review);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Loading shimmer effect for reviews screen
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(16.h),
      itemCount: 6, // Show 6 shimmer cards
      itemBuilder: (context, index) {
        return _buildReviewShimmerCard();
      },
    );
  }

  /// Individual review shimmer card
  Widget _buildReviewShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info shimmer
          Row(
            children: [
              // Avatar shimmer
              Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(
                  width: 40.h,
                  height: 40.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              SizedBox(width: 12.h),
              
              // Name and date shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 120.h,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80.h,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stars shimmer
              Row(
                children: List.generate(5, (index) {
                  return Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(
                      width: 16.h,
                      height: 16.h,
                      margin: EdgeInsets.only(right: 2.w.h),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Review title shimmer
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              width: double.infinity,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // Review body shimmer (3 lines)
          Column(
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.only(bottom: 3.h.h),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: index == 2 ? 200.h : double.infinity, // Last line shorter
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: 12.h),
          
          // Review images shimmer
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.only(right: 7.w.h),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 60.h,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final JudgemeReview review;

  _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info and rating
          Row(
            children: [
              // Reviewer avatar
              Container(
                width: 40.h,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Color(0xFFFF5C9A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.reviewerInitials,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5C9A),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12.h),
              
              // Reviewer name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      review.formattedDate,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey.shade600,
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
                    size: 16.h,
                    color: const Color(0xFFFFA500),
                  );
                }),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Review title
          if (review.title.isNotEmpty) ...[
            Text(
              review.title,
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          
          // Review body
          if (review.body.isNotEmpty) ...[
            Text(
              review.body,
              style: TextStyle(
                fontSize: 13.fSize,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          
          // Review images
          if (review.pictures.isNotEmpty) ...[
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.pictures.length,
                itemBuilder: (context, index) {
                  final picture = review.pictures[index];
                  return Container(
                    width: 80.h,
                    height: 80.h,
                    margin: EdgeInsets.only(right: 7.w.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.r),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.w,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.r),
                      child: Image.network(
                        picture.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            color: Colors.grey.shade50,
                            child: Center(
                              child: SizedBox(
                                width: 20.h,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFFF5C9A),
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 24.h,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Verified buyer badge
          if (review.verifiedBuyer != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.h,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(3.r),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.w,
                ),
              ),
              child: Text(
                'Verified Buyer',
                style: TextStyle(
                  fontSize: 10.fSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}