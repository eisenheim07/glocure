/// Judge.me Reviews Model
/// This model represents the reviews data from Judge.me API
class JudgemeReviewsResponse {
  final List<JudgemeReview> reviews;
  final JudgemeReviewsMeta meta;

  JudgemeReviewsResponse({
    required this.reviews,
    required this.meta,
  });

  factory JudgemeReviewsResponse.fromJson(Map<String, dynamic> json) {
    return JudgemeReviewsResponse(
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((review) => JudgemeReview.fromJson(review))
          .toList(),
      meta: JudgemeReviewsMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class JudgemeReview {
  final int id;
  final String title;
  final String body;
  final int rating;
  final String reviewerName;
  final String reviewerEmail;
  final String? verifiedBuyer;
  final DateTime createdAt;
  final List<JudgemeReviewImage> pictures;

  JudgemeReview({
    required this.id,
    required this.title,
    required this.body,
    required this.rating,
    required this.reviewerName,
    required this.reviewerEmail,
    this.verifiedBuyer,
    required this.createdAt,
    required this.pictures,
  });

  factory JudgemeReview.fromJson(Map<String, dynamic> json) {
    return JudgemeReview(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      rating: json['rating'] ?? 0,
      reviewerName: json['reviewer']['name'] ?? 'Anonymous',
      reviewerEmail: json['reviewer']['email'] ?? '',
      verifiedBuyer: json['verified_buyer'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      pictures: (json['pictures'] as List<dynamic>? ?? [])
          .map((picture) => JudgemeReviewImage.fromJson(picture))
          .toList(),
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get reviewer initials for avatar
  String get reviewerInitials {
    final names = reviewerName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'A';
  }
}

class JudgemeReviewImage {
  final String url;
  final String? altText;

  JudgemeReviewImage({
    required this.url,
    this.altText,
  });

  factory JudgemeReviewImage.fromJson(Map<String, dynamic> json) {
    return JudgemeReviewImage(
      url: json['url'] ?? '',
      altText: json['alt_text'],
    );
  }
}

class JudgemeReviewsMeta {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  JudgemeReviewsMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory JudgemeReviewsMeta.fromJson(Map<String, dynamic> json) {
    return JudgemeReviewsMeta(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalCount: json['total_count'] ?? 0,
      perPage: json['per_page'] ?? 10,
    );
  }

  /// Check if there are more pages
  bool get hasNextPage => currentPage < totalPages;
}