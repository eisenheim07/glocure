/// Order Model
/// Represents order data for Shopify order creation
class OrderModel {
  final String? id;
  final String? orderNumber;
  final String email;
  final List<OrderLineItem> lineItems;
  final OrderAddress shippingAddress;
  final OrderAddress billingAddress;
  final String? financialStatus;
  final String? fulfillmentStatus;
  final String? totalPrice;
  final String? subtotalPrice;
  final String? totalTax;
  final String? tags;
  final DateTime? createdAt;

  OrderModel({
    this.id,
    this.orderNumber,
    required this.email,
    required this.lineItems,
    required this.shippingAddress,
    required this.billingAddress,
    this.financialStatus,
    this.fulfillmentStatus,
    this.totalPrice,
    this.subtotalPrice,
    this.totalTax,
    this.tags,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString(),
      orderNumber: json['order_number']?.toString() ?? json['name']?.toString(),
      email: json['email'] ?? '',
      lineItems: (json['line_items'] as List?)
              ?.map((item) => OrderLineItem.fromJson(item))
              .toList() ??
          [],
      shippingAddress: json['shipping_address'] != null
          ? OrderAddress.fromJson(json['shipping_address'])
          : OrderAddress.empty(),
      billingAddress: json['billing_address'] != null
          ? OrderAddress.fromJson(json['billing_address'])
          : OrderAddress.empty(),
      financialStatus: json['financial_status'],
      fulfillmentStatus: json['fulfillment_status'],
      totalPrice: json['total_price']?.toString(),
      subtotalPrice: json['subtotal_price']?.toString(),
      totalTax: json['total_tax']?.toString(),
      tags: json['tags']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress.toJson(),
      'billing_address': billingAddress.toJson(),
      if (financialStatus != null) 'financial_status': financialStatus,
    };
  }
}

/// Order Line Item
class OrderLineItem {
  final String? id;
  final String? variantId;
  final String? productId;
  final String? title;
  final int quantity;
  final String? price;
  final String? sku;

  OrderLineItem({
    this.id,
    this.variantId,
    this.productId,
    this.title,
    required this.quantity,
    this.price,
    this.sku,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: json['id']?.toString(),
      variantId: json['variant_id']?.toString(),
      productId: json['product_id']?.toString(),
      title: json['title'],
      quantity: json['quantity'] ?? 1,
      price: json['price']?.toString(),
      sku: json['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'quantity': quantity,
      if (price != null) 'price': price,
    };
  }
}

/// Order Address
class OrderAddress {
  final String? firstName;
  final String? lastName;
  final String? address1;
  final String? address2;
  final String? city;
  final String? province;
  final String? country;
  final String? zip;
  final String? phone;

  OrderAddress({
    this.firstName,
    this.lastName,
    this.address1,
    this.address2,
    this.city,
    this.province,
    this.country,
    this.zip,
    this.phone,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      firstName: json['first_name'],
      lastName: json['last_name'],
      address1: json['address1'],
      address2: json['address2'],
      city: json['city'],
      province: json['province'],
      country: json['country'],
      zip: json['zip'],
      phone: json['phone'],
    );
  }

  factory OrderAddress.empty() {
    return OrderAddress();
  }

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (address1 != null) 'address1': address1,
      if (address2 != null) 'address2': address2,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (country != null) 'country': country,
      if (zip != null) 'zip': zip,
      if (phone != null) 'phone': phone,
    };
  }

  bool get isValid {
    return firstName != null &&
        lastName != null &&
        address1 != null &&
        city != null &&
        country != null &&
        zip != null;
  }
}
