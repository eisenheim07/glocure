/// Judge.me Product Model
/// This model represents the product data from Judge.me API
class JudgemeProductResponse {
  final JudgemeProduct? product;

  JudgemeProductResponse({this.product});

  factory JudgemeProductResponse.fromJson(Map<String, dynamic> json) {
    return JudgemeProductResponse(
      product: json['product'] != null 
          ? JudgemeProduct.fromJson(json['product']) 
          : null,
    );
  }
}

class JudgemeProduct {
  final int id;
  final String externalId;
  final String name;
  final String? imageUrl;
  final double averageRating;
  final int reviewsCount;

  JudgemeProduct({
    required this.id,
    required this.externalId,
    required this.name,
    this.imageUrl,
    required this.averageRating,
    required this.reviewsCount,
  });

  factory JudgemeProduct.fromJson(Map<String, dynamic> json) {
    return JudgemeProduct(
      id: json['id'] ?? 0,
      externalId: json['external_id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
    );
  }
}