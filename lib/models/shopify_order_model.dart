/// Shopify Order Model
/// Represents order data from Shopify Admin API
class ShopifyOrder {
  final String id;
  final String name;
  final String email;
  final String financialStatus;
  final String fulfillmentStatus;
  final String totalPrice;
  final String subtotalPrice;
  final String totalTax;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShopifyLineItem> lineItems;
  final ShopifyAddress? shippingAddress;
  final ShopifyAddress? billingAddress;
  final String? note;
  final List<String> tags;

  ShopifyOrder({
    required this.id,
    required this.name,
    required this.email,
    required this.financialStatus,
    required this.fulfillmentStatus,
    required this.totalPrice,
    required this.subtotalPrice,
    required this.totalTax,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    required this.lineItems,
    this.shippingAddress,
    this.billingAddress,
    this.note,
    required this.tags,
  });

  factory ShopifyOrder.fromJson(Map<String, dynamic> json) {
    return ShopifyOrder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      financialStatus: json['financial_status']?.toString() ?? '',
      fulfillmentStatus: json['fulfillment_status']?.toString() ?? '',
      totalPrice: json['total_price']?.toString() ?? '0.00',
      subtotalPrice: json['subtotal_price']?.toString() ?? '0.00',
      totalTax: json['total_tax']?.toString() ?? '0.00',
      currencyCode: json['currency']?.toString() ?? 'INR',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      lineItems: (json['line_items'] as List?)
              ?.map((item) => ShopifyLineItem.fromJson(item))
              .toList() ??
          [],
      shippingAddress: json['shipping_address'] != null
          ? ShopifyAddress.fromJson(json['shipping_address'])
          : null,
      billingAddress: json['billing_address'] != null
          ? ShopifyAddress.fromJson(json['billing_address'])
          : null,
      note: json['note']?.toString(),
      tags: json['tags']?.toString().split(',').map((e) => e.trim()).toList() ?? [],
    );
  }

  /// Get status color based on financial and fulfillment status
  String get statusColor {
    if (financialStatus.toLowerCase() == 'paid' && 
        fulfillmentStatus.toLowerCase() == 'fulfilled') {
      return '#4CAF50'; // Green for completed
    } else if (financialStatus.toLowerCase() == 'pending') {
      return '#FF9800'; // Orange for pending
    } else if (financialStatus.toLowerCase() == 'refunded' || 
               fulfillmentStatus.toLowerCase() == 'cancelled') {
      return '#F44336'; // Red for cancelled/refunded
    } else {
      return '#2196F3'; // Blue for processing
    }
  }

  /// Get display status text
  String get displayStatus {
    if (financialStatus.toLowerCase() == 'paid' && 
        fulfillmentStatus.toLowerCase() == 'fulfilled') {
      return 'Delivered';
    } else if (financialStatus.toLowerCase() == 'pending') {
      return 'Pending';
    } else if (financialStatus.toLowerCase() == 'refunded' || 
               fulfillmentStatus.toLowerCase() == 'cancelled') {
      return 'Cancelled';
    } else {
      return 'Processing';
    }
  }
}

/// Shopify Line Item
class ShopifyLineItem {
  final String id;
  final String title;
  final String variantTitle;
  final int quantity;
  final String price;
  final String totalDiscount;
  final String sku;
  final String vendor;
  final String? productId;
  final String? variantId;

  ShopifyLineItem({
    required this.id,
    required this.title,
    required this.variantTitle,
    required this.quantity,
    required this.price,
    required this.totalDiscount,
    required this.sku,
    required this.vendor,
    this.productId,
    this.variantId,
  });

  factory ShopifyLineItem.fromJson(Map<String, dynamic> json) {
    return ShopifyLineItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      variantTitle: json['variant_title']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      price: json['price']?.toString() ?? '0.00',
      totalDiscount: json['total_discount']?.toString() ?? '0.00',
      sku: json['sku']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      variantId: json['variant_id']?.toString(),
    );
  }

  /// Get formatted price
  String get formattedPrice {
    final priceValue = double.tryParse(price) ?? 0.0;
    return '₹${priceValue.toStringAsFixed(2)}';
  }

  /// Get total price for this line item
  String get totalPrice {
    final priceValue = double.tryParse(price) ?? 0.0;
    final total = priceValue * quantity;
    return '₹${total.toStringAsFixed(2)}';
  }
}

/// Shopify Address
class ShopifyAddress {
  final String firstName;
  final String lastName;
  final String address1;
  final String? address2;
  final String city;
  final String province;
  final String country;
  final String zip;
  final String? phone;

  ShopifyAddress({
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2,
    required this.city,
    required this.province,
    required this.country,
    required this.zip,
    this.phone,
  });

  factory ShopifyAddress.fromJson(Map<String, dynamic> json) {
    return ShopifyAddress(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      address1: json['address1']?.toString() ?? '',
      address2: json['address2']?.toString(),
      city: json['city']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zip: json['zip']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  /// Get formatted full name
  String get fullName => '$firstName $lastName'.trim();

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[
      address1,
      if (address2?.isNotEmpty == true) address2!,
      city,
      province,
      country,
      zip,
    ];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }
}