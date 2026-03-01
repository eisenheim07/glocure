/// Serviceability Model
/// Represents the delivery serviceability response from Delhivery API
class ServiceabilityModel {
  final String pincode;
  final String? city;
  final String? state;
  final String? district;
  final bool codAvailable;
  final bool prepaidAvailable;
  final bool pickupAvailable;
  final bool cashAvailable;
  final bool isOda;

  ServiceabilityModel({
    required this.pincode,
    this.city,
    this.state,
    this.district,
    required this.codAvailable,
    required this.prepaidAvailable,
    required this.pickupAvailable,
    required this.cashAvailable,
    required this.isOda,
  });

  factory ServiceabilityModel.fromJson(Map<String, dynamic> json) {
    // Extract postal_code data from the response
    final postalCode = json['postal_code'] as Map<String, dynamic>?;
    
    if (postalCode == null) {
      throw Exception('Invalid response: postal_code not found');
    }

    return ServiceabilityModel(
      pincode: postalCode['pin']?.toString() ?? '',
      city: postalCode['city']?.toString(),
      state: postalCode['state_code']?.toString(),
      district: postalCode['district']?.toString(),
      codAvailable: postalCode['cod']?.toString().toUpperCase() == 'Y',
      prepaidAvailable: postalCode['pre_paid']?.toString().toUpperCase() == 'Y',
      pickupAvailable: postalCode['pickup']?.toString().toUpperCase() == 'Y',
      cashAvailable: postalCode['cash']?.toString().toUpperCase() == 'Y',
      isOda: postalCode['is_oda']?.toString().toUpperCase() == 'Y',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pincode': pincode,
      'city': city,
      'state': state,
      'district': district,
      'cod_available': codAvailable,
      'prepaid_available': prepaidAvailable,
      'pickup_available': pickupAvailable,
      'cash_available': cashAvailable,
      'is_oda': isOda,
    };
  }

  bool get isServiceable => codAvailable || prepaidAvailable;
  bool get supportsPrepaid => prepaidAvailable;
  bool get supportsCOD => codAvailable;
}
