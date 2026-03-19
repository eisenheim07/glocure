// Customer Model
// Represents customer information including addresses

class CustomerResponse {
  final Customer? customer;

  CustomerResponse({this.customer});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
    );
  }
}

class Customer {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final CustomerAddress? defaultAddress;
  final List<CustomerAddress> addresses;

  Customer({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.defaultAddress,
    required this.addresses,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final addressesData = json['addresses']?['edges'] as List<dynamic>? ?? [];
    final addresses = addressesData
        .map((edge) =>
            CustomerAddress.fromJson(edge['node'] as Map<String, dynamic>))
        .toList();

    return Customer(
      id: json['id'] ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      defaultAddress: json['defaultAddress'] != null
          ? CustomerAddress.fromJson(json['defaultAddress'])
          : null,
      addresses: addresses,
    );
  }

  /// Check if customer has a complete address based on all required fields
  bool hasCompleteAddress() {
    // Check if defaultAddress exists and all required fields are complete
    return defaultAddress != null &&
        defaultAddress!.firstName != null &&
        defaultAddress!.firstName!.isNotEmpty &&
        defaultAddress!.lastName != null &&
        defaultAddress!.lastName!.isNotEmpty &&
        defaultAddress!.address1 != null &&
        defaultAddress!.address1!.isNotEmpty &&
        defaultAddress!.address2 != null &&
        defaultAddress!.address2!.isNotEmpty &&
        defaultAddress!.city != null &&
        defaultAddress!.city!.isNotEmpty &&
        defaultAddress!.province != null &&
        defaultAddress!.province!.isNotEmpty &&
        defaultAddress!.zip != null &&
        defaultAddress!.zip!.isNotEmpty &&
        defaultAddress!.phone != null &&
        defaultAddress!.phone!.isNotEmpty;
  }
}

class CustomerAddress {
  final String? id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? address1;
  final String? address2;
  final String? city;
  final String? country;
  final String? zip;
  final String? company;
  final String? province;
  final String? phone;

  CustomerAddress({
    this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.address1,
    this.address2,
    this.city,
    this.country,
    this.zip,
    this.company,
    this.province,
    this.phone,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String?,
      name: json['name'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      zip: json['zip'] as String?,
      company: json['company'] as String?,
      province: json['province'] as String?,
      phone: json['phone'] as String?,
    );
  }

  /// Check if address has all required fields
  bool isComplete() {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        address1 != null &&
        address1!.isNotEmpty &&
        address2 != null &&
        address2!.isNotEmpty &&
        city != null &&
        city!.isNotEmpty &&
        province != null &&
        province!.isNotEmpty &&
        zip != null &&
        zip!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty;
  }
}
