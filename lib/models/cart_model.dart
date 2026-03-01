/// Cart Model
/// Represents the shopping cart with line items and pricing information

class CartResponse {
  final Cart? cart;

  CartResponse({this.cart});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cart: json['cart'] != null ? Cart.fromJson(json['cart']) : null,
    );
  }
}

class Cart {
  final String id;
  final List<CartLine> lines;
  final CartCost? cost;
  final List<DiscountCode> discountCodes;

  Cart({
    required this.id,
    required this.lines,
    this.cost,
    required this.discountCodes,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final linesData = json['lines']?['edges'] as List<dynamic>? ?? [];
    final lines = linesData
        .map((edge) => CartLine.fromJson(edge['node'] as Map<String, dynamic>))
        .toList();

    final discountCodesData = json['discountCodes'] as List<dynamic>? ?? [];
    final discountCodes = discountCodesData
        .map((code) => DiscountCode.fromJson(code as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'] ?? '',
      lines: lines,
      cost: json['cost'] != null ? CartCost.fromJson(json['cost']) : null,
      discountCodes: discountCodes,
    );
  }
}

class CartLine {
  final String id;
  final int quantity;
  final List<CartAttribute> attributes;
  final CartMerchandise? merchandise;

  CartLine({
    required this.id,
    required this.quantity,
    required this.attributes,
    this.merchandise,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final attributesData = json['attributes'] as List<dynamic>? ?? [];
    final attributes = attributesData
        .map((attr) => CartAttribute.fromJson(attr as Map<String, dynamic>))
        .toList();

    return CartLine(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 1,
      attributes: attributes,
      merchandise: json['merchandise'] != null
          ? CartMerchandise.fromJson(json['merchandise'])
          : null,
    );
  }
}

class CartAttribute {
  final String key;
  final String value;

  CartAttribute({
    required this.key,
    required this.value,
  });

  factory CartAttribute.fromJson(Map<String, dynamic> json) {
    return CartAttribute(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class CartMerchandise {
  final String id;
  final String title;
  final String? sku;
  final bool availableForSale;
  final int? quantityAvailable;
  final Money priceV2;
  final Money? compareAtPriceV2;
  final CartProduct product;

  CartMerchandise({
    required this.id,
    required this.title,
    this.sku,
    required this.availableForSale,
    this.quantityAvailable,
    required this.priceV2,
    this.compareAtPriceV2,
    required this.product,
  });

  factory CartMerchandise.fromJson(Map<String, dynamic> json) {
    return CartMerchandise(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sku: json['sku'] as String?,
      availableForSale: json['availableForSale'] ?? false,
      quantityAvailable: json['quantityAvailable'] as int?,
      priceV2: Money.fromJson(json['priceV2'] ?? {}),
      compareAtPriceV2: json['compareAtPriceV2'] != null
          ? Money.fromJson(json['compareAtPriceV2'])
          : null,
      product: CartProduct.fromJson(json['product'] ?? {}),
    );
  }
}

class CartProduct {
  final String id;
  final String title;
  final String handle;
  final String? imageUrl;
  final String? imageAlt;

  CartProduct({
    required this.id,
    required this.title,
    required this.handle,
    this.imageUrl,
    this.imageAlt,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    final imagesData = json['images']?['edges'] as List<dynamic>? ?? [];
    String? imageUrl;
    String? imageAlt;

    if (imagesData.isNotEmpty) {
      final firstImage = imagesData.first['node'] as Map<String, dynamic>?;
      imageUrl = firstImage?['url'] as String?;
      imageAlt = firstImage?['altText'] as String?;
    }

    return CartProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      handle: json['handle'] ?? '',
      imageUrl: imageUrl,
      imageAlt: imageAlt,
    );
  }
}

class Money {
  final String amount;
  final String currencyCode;

  Money({
    required this.amount,
    required this.currencyCode,
  });

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: json['amount']?.toString() ?? '0',
      currencyCode: json['currencyCode'] ?? 'INR',
    );
  }
}

class CartCost {
  final Money subtotalAmount;
  final Money totalAmount;
  final Money? totalTaxAmount;
  final Money? totalDutyAmount;

  CartCost({
    required this.subtotalAmount,
    required this.totalAmount,
    this.totalTaxAmount,
    this.totalDutyAmount,
  });

  factory CartCost.fromJson(Map<String, dynamic> json) {
    return CartCost(
      subtotalAmount: Money.fromJson(json['subtotalAmount'] ?? {}),
      totalAmount: Money.fromJson(json['totalAmount'] ?? {}),
      totalTaxAmount: json['totalTaxAmount'] != null
          ? Money.fromJson(json['totalTaxAmount'])
          : null,
      totalDutyAmount: json['totalDutyAmount'] != null
          ? Money.fromJson(json['totalDutyAmount'])
          : null,
    );
  }
}

class DiscountCode {
  final String code;
  final bool applicable;

  DiscountCode({
    required this.code,
    required this.applicable,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      code: json['code'] ?? '',
      applicable: json['applicable'] ?? false,
    );
  }
}
