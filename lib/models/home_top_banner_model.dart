/// Model class to store home top banner data
/// This class represents a single banner item from the API response
class HomeTopBannerModel {
  /// Unique identifier for the banner
  final String id;

  /// Handle/slug for the banner
  final String handle;

  /// List of fields containing banner data
  final List<BannerField> fields;

  /// Constructor
  HomeTopBannerModel({
    required this.id,
    required this.handle,
    required this.fields,
  });

  /// Get banner position (1, 2, 3, etc.)
  int get bannerPosition {
    for (var field in fields) {
      if (field.key == 'banner_position' && field.value != null) {
        return int.tryParse(field.value!) ?? 0;
      }
    }
    return 0;
  }

  /// Get banner URL for navigation
  String? get bannerUrl {
    for (var field in fields) {
      if (field.key == 'banner_url' && field.value != null && field.value!.isNotEmpty) {
        return field.value;
      }
    }
    return null;
  }

  /// Get banner image URL
  String? get bannerImageUrl {
    for (var field in fields) {
      if (field.key == 'banner_image' && field.reference != null && field.reference!.image != null) {
        return field.reference!.image!.url;
      }
    }
    return null;
  }

  /// Create model from JSON data
  factory HomeTopBannerModel.fromJson(Map<String, dynamic> json) {
    return HomeTopBannerModel(
      id: json['id'] ?? '',
      handle: json['handle'] ?? '',
      fields: (json['fields'] as List<dynamic>?)
              ?.map((field) => BannerField.fromJson(field))
              .toList() ?? [],
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'handle': handle,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }
}

/// Model class for banner fields
class BannerField {
  /// Field key (e.g., 'title', 'image', etc.)
  final String key;

  /// Field value (text content)
  final String? value;

  /// Reference to media/image if available
  final MediaImageReference? reference;

  /// Constructor
  BannerField({
    required this.key,
    this.value,
    this.reference,
  });

  /// Create model from JSON data
  factory BannerField.fromJson(Map<String, dynamic> json) {
    return BannerField(
      key: json['key'] ?? '',
      value: json['value'],
      reference: json['reference'] != null
          ? MediaImageReference.fromJson(json['reference'])
          : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'reference': reference?.toJson(),
    };
  }
}

/// Model class for media image reference
class MediaImageReference {
  /// Type name (should be 'MediaImage')
  final String typeName;

  /// Image data
  final ImageData? image;

  /// Constructor
  MediaImageReference({
    required this.typeName,
    this.image,
  });

  /// Create model from JSON data
  factory MediaImageReference.fromJson(Map<String, dynamic> json) {
    return MediaImageReference(
      typeName: json['__typename'] ?? '',
      image: json['image'] != null
          ? ImageData.fromJson(json['image'])
          : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      '__typename': typeName,
      'image': image?.toJson(),
    };
  }
}

/// Model class for image data
class ImageData {
  /// Image URL
  final String? url;

  /// Alt text for the image
  final String? altText;

  /// Constructor
  ImageData({
    this.url,
    this.altText,
  });

  /// Create model from JSON data
  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      url: json['url'],
      altText: json['altText'],
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'altText': altText,
    };
  }
}

/// Model class for the complete API response
class HomeTopBannerResponse {
  /// List of banner items
  final List<HomeTopBannerModel> banners;

  /// Constructor
  HomeTopBannerResponse({
    required this.banners,
  });

  /// Create model from JSON data
  factory HomeTopBannerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final metaobjects = data['metaobjects'] ?? {};
    final edges = metaobjects['edges'] as List<dynamic>? ?? [];

    final banners = edges.map((edge) {
      return HomeTopBannerModel.fromJson(edge['node'] ?? {});
    }).toList();

    // Sort banners by banner_position (1, 2, 3, etc.)
    banners.sort((a, b) => a.bannerPosition.compareTo(b.bannerPosition));

    return HomeTopBannerResponse(banners: banners);
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'metaobjects': {
          'edges': banners.map((banner) => {
            'node': banner.toJson(),
          }).toList(),
        },
      },
    };
  }
}
