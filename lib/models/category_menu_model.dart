/// Model for the Shopify Admin API menu query response
class CategoryMenuResponse {
  final CategoryMenu? menu;

  CategoryMenuResponse({required this.menu});

  factory CategoryMenuResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final menuJson = data['menu'];

    return CategoryMenuResponse(
      menu: menuJson != null ? CategoryMenu.fromJson(menuJson) : null,
    );
  }
}

class CategoryMenu {
  final String id;
  final String handle;
  final String title;
  final List<CategoryMenuItem> items;

  CategoryMenu({
    required this.id,
    required this.handle,
    required this.title,
    required this.items,
  });

  factory CategoryMenu.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return CategoryMenu(
      id: json['id'] ?? '',
      handle: json['handle'] ?? '',
      title: json['title'] ?? '',
      items: itemsJson
          .map((item) => CategoryMenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryMenuItem {
  final String id;
  final String title;
  final String type;
  final String url;
  final String? resourceId;

  CategoryMenuItem({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.resourceId,
  });

  /// Extract collection handle from url (e.g. "/collections/oily-skin" → "oily-skin")
  String get collectionHandle => url.replaceFirst('/collections/', '');

  factory CategoryMenuItem.fromJson(Map<String, dynamic> json) {
    return CategoryMenuItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      resourceId: json['resourceId'],
    );
  }
}
