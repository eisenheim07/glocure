/// Models for "Browse by categories" collections response

class BrowseCategory {
  final String id;
  final String handle;
  final String title;
  final String description;
  final String? imageSrc;
  final bool hasMetafield;

  BrowseCategory({
    required this.id,
    required this.handle,
    required this.title,
    required this.description,
    required this.imageSrc,
    required this.hasMetafield,
  });

  factory BrowseCategory.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;

    return BrowseCategory(
      id: json['id'] ?? '',
      handle: json['handle'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageSrc: image != null ? image['src'] as String? : null,
      hasMetafield: json['metafield'] != null,
    );
  }
}

class BrowseCategoriesResponse {
  final List<BrowseCategory> categories;

  BrowseCategoriesResponse({required this.categories});

  factory BrowseCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final collections = data['collections'] ?? {};
    final edges = collections['edges'] as List<dynamic>? ?? [];

    final items = edges
        .map(
          (edge) => BrowseCategory.fromJson(
            (edge as Map<String, dynamic>)['node'] ?? <String, dynamic>{},
          ),
        )
        .toList();

    return BrowseCategoriesResponse(categories: items);
  }
}
