import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/judgeme_product_model.dart';
import '../../models/judgeme_reviews_model.dart';
import '../../services/judgeme_service.dart';

/// Reviews Cubit State
abstract class ReviewsState {}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final JudgemeProduct? product;
  final List<JudgemeReview> reviews;
  final JudgemeReviewsMeta meta;
  final bool isLoadingMore;

  ReviewsLoaded({
    this.product,
    required this.reviews,
    required this.meta,
    this.isLoadingMore = false,
  });

  ReviewsLoaded copyWith({
    JudgemeProduct? product,
    List<JudgemeReview>? reviews,
    JudgemeReviewsMeta? meta,
    bool? isLoadingMore,
  }) {
    return ReviewsLoaded(
      product: product ?? this.product,
      reviews: reviews ?? this.reviews,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ReviewsError extends ReviewsState {
  final String message;

  ReviewsError(this.message);
}

/// Reviews Cubit
/// Manages product reviews state and pagination
class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit() : super(ReviewsInitial());

  final JudgemeService _judgemeService = JudgemeService();
  String? _currentExternalId;
  int? _currentJudgemeProductId;

  /// Fetch product reviews by external ID (Shopify product ID)
  Future<void> fetchReviews(String externalId) async {
    try {
      emit(ReviewsLoading());
      _currentExternalId = externalId;

      // Get product and reviews
      final productResponse = await _judgemeService.getProductByExternalId(externalId);
      
      if (productResponse.product == null) {
        // No reviews available for this product
        emit(ReviewsLoaded(
          product: null,
          reviews: [],
          meta: JudgemeReviewsMeta(
            currentPage: 1,
            totalPages: 1,
            totalCount: 0,
            perPage: 10,
          ),
        ));
        return;
      }

      _currentJudgemeProductId = productResponse.product!.id;

      // Get first page of reviews
      final reviewsResponse = await _judgemeService.getProductReviews(
        productId: productResponse.product!.id,
        page: 1,
        limit: 10,
      );

      emit(ReviewsLoaded(
        product: productResponse.product,
        reviews: reviewsResponse.reviews,
        meta: reviewsResponse.meta,
      ));
    } catch (e) {
      emit(ReviewsError('Failed to load reviews: $e'));
    }
  }

  /// Load more reviews (pagination)
  Future<void> loadMoreReviews() async {
    final currentState = state;
    if (currentState is! ReviewsLoaded || 
        currentState.isLoadingMore || 
        !currentState.meta.hasNextPage ||
        _currentJudgemeProductId == null) {
      return;
    }

    try {
      // Show loading indicator for pagination
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.meta.currentPage + 1;
      
      final reviewsResponse = await _judgemeService.getProductReviews(
        productId: _currentJudgemeProductId!,
        page: nextPage,
        limit: 10,
      );

      // Combine existing reviews with new ones
      final allReviews = [...currentState.reviews, ...reviewsResponse.reviews];

      emit(ReviewsLoaded(
        product: currentState.product,
        reviews: allReviews,
        meta: reviewsResponse.meta,
        isLoadingMore: false,
      ));
    } catch (e) {
      // Keep current state but remove loading indicator
      emit(currentState.copyWith(isLoadingMore: false));
      // Could emit error state or show snackbar here
    }
  }

  /// Refresh reviews (reload from first page)
  Future<void> refreshReviews() async {
    if (_currentExternalId != null) {
      await fetchReviews(_currentExternalId!);
    }
  }

  /// Get limited reviews for product details screen (first 2 reviews)
  List<JudgemeReview> getLimitedReviews() {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      return currentState.reviews.take(2).toList();
    }
    return [];
  }

  /// Get product rating info
  JudgemeProduct? getProductRating() {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      return currentState.product;
    }
    return null;
  }

  /// Check if there are more reviews to show
  bool hasMoreReviews() {
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      return currentState.reviews.length > 2;
    }
    return false;
  }
}