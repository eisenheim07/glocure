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
          .where((image) => !image.hidden) // Filter out hidden images
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
  final Map<String, String> urls;
  final bool hidden;
  final String? altText;

  JudgemeReviewImage({
    required this.urls,
    this.hidden = false,
    this.altText,
  });

  factory JudgemeReviewImage.fromJson(Map<String, dynamic> json) {
    // Handle null or missing urls field
    final urlsData = json['urls'];
    Map<String, String> urls = {};
    
    if (urlsData != null && urlsData is Map) {
      urls = Map<String, String>.from(urlsData);
    }
    
    return JudgemeReviewImage(
      urls: urls,
      hidden: json['hidden'] ?? false,
      altText: json['alt_text'],
    );
  }

  /// Get the best quality image URL
  String get url {
    if (urls.isEmpty) return '';
    
    // Priority: original > huge > compact > small
    if (urls.containsKey('original') && urls['original'] != null && urls['original']!.isNotEmpty) {
      return urls['original']!;
    } else if (urls.containsKey('huge') && urls['huge'] != null && urls['huge']!.isNotEmpty) {
      return urls['huge']!;
    } else if (urls.containsKey('compact') && urls['compact'] != null && urls['compact']!.isNotEmpty) {
      return urls['compact']!;
    } else if (urls.containsKey('small') && urls['small'] != null && urls['small']!.isNotEmpty) {
      return urls['small']!;
    }
    return ''; // Fallback to empty string
  }

  /// Get thumbnail URL for smaller displays
  String get thumbnailUrl {
    if (urls.isEmpty) return '';
    
    // Priority: small > compact > original > huge
    if (urls.containsKey('small') && urls['small'] != null && urls['small']!.isNotEmpty) {
      return urls['small']!;
    } else if (urls.containsKey('compact') && urls['compact'] != null && urls['compact']!.isNotEmpty) {
      return urls['compact']!;
    } else if (urls.containsKey('original') && urls['original'] != null && urls['original']!.isNotEmpty) {
      return urls['original']!;
    } else if (urls.containsKey('huge') && urls['huge'] != null && urls['huge']!.isNotEmpty) {
      return urls['huge']!;
    }
    return ''; // Fallback to empty string
  }
}

class JudgemeReviewsMeta {
  final int currentPage;
  final int perPage;
  final bool hasMorePages; // Determined by checking if we got fewer reviews than requested

  JudgemeReviewsMeta({
    required this.currentPage,
    required this.perPage,
    this.hasMorePages = true, // Default to true, will be updated based on reviews count
  });

  factory JudgemeReviewsMeta.fromJson(Map<String, dynamic> json) {
    return JudgemeReviewsMeta(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      hasMorePages: true, // Will be updated in the service based on reviews length
    );
  }

  /// Create a copy with updated pagination info
  JudgemeReviewsMeta copyWith({
    int? currentPage,
    int? perPage,
    bool? hasMorePages,
  }) {
    return JudgemeReviewsMeta(
      currentPage: currentPage ?? this.currentPage,
      perPage: perPage ?? this.perPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }

  /// Check if there are more pages available
  bool get hasNextPage {
    return hasMorePages;
  }
}