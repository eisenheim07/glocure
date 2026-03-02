/// Model for Shopify Pages (Privacy Policy, Terms & Conditions, etc.)
class PageModel {
  final String id;
  final String title;
  final String handle;
  final String body;
  final String bodySummary;
  final String? createdAt;
  final String? updatedAt;
  final String? onlineStoreUrl;

  PageModel({
    required this.id,
    required this.title,
    required this.handle,
    required this.body,
    required this.bodySummary,
    this.createdAt,
    this.updatedAt,
    this.onlineStoreUrl,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      handle: json['handle'] ?? '',
      body: json['body'] ?? '',
      bodySummary: json['bodySummary'] ?? '',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      onlineStoreUrl: json['onlineStoreUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'handle': handle,
      'body': body,
      'bodySummary': bodySummary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'onlineStoreUrl': onlineStoreUrl,
    };
  }
}

class PagesResponse {
  final List<PageModel> pages;
  final bool hasNextPage;
  final String? endCursor;

  PagesResponse({
    required this.pages,
    required this.hasNextPage,
    this.endCursor,
  });

  factory PagesResponse.fromJson(Map<String, dynamic> json) {
    final edges = json['pages']?['edges'] as List<dynamic>? ?? [];
    final pages = edges.map((edge) => PageModel.fromJson(edge['node'])).toList();

    final pageInfo = json['pages']?['pageInfo'] as Map<String, dynamic>? ?? {};

    return PagesResponse(
      pages: pages,
      hasNextPage: pageInfo['hasNextPage'] ?? false,
      endCursor: pageInfo['endCursor'],
    );
  }
}
