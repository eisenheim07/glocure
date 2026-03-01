import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/serviceability_model.dart';

/// Delivery Service
/// Handles all delivery-related API calls (Delhivery integration)
class DeliveryService {
  /// Check if delivery is serviceable for a given pincode
  /// 
  /// [pincode] - The pincode to check serviceability for
  /// Returns [ServiceabilityModel] with serviceability details
  /// Throws exception if API call fails
  Future<ServiceabilityModel> checkServiceability(String pincode) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.delhiveryBaseUrl}/c/api/pin-codes/json/',
      ).replace(queryParameters: {
        'filter_codes': pincode,
      });

      // Log API Request
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🚚 DELHIVERY API REQUEST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📍 Endpoint: ${url.toString()}');
      debugPrint('🔑 Method: GET');
      debugPrint('📮 Pincode: $pincode');
      debugPrint('🔐 Authorization: Token ${ApiConfig.delhiveryApiToken.substring(0, 10)}...');
      debugPrint('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════');

      final startTime = DateTime.now();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${ApiConfig.delhiveryApiToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ REQUEST TIMEOUT after 30 seconds');
          debugPrint('═══════════════════════════════════════════════════════');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log API Response
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 DELHIVERY API RESPONSE');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('⏱️ Response Time: ${duration.inMilliseconds}ms');
      debugPrint('📏 Response Length: ${response.body.length} bytes');
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📄 Response Headers:');
      response.headers.forEach((key, value) {
        debugPrint('   $key: $value');
      });
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📝 Response Body:');
      
      // Pretty print JSON response
      try {
        final jsonData = json.decode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
        debugPrint(prettyJson);
      } catch (e) {
        debugPrint(response.body);
      }
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('───────────────────────────────────────────────────────');
        debugPrint('🔍 Parsing Response Structure...');
        
        // The new API returns: {"delivery_codes": [{"postal_code": {...}}]}
        if (data is Map<String, dynamic>) {
          final deliveryCodes = data['delivery_codes'];
          
          if (deliveryCodes is List && deliveryCodes.isNotEmpty) {
            // Get the first item from delivery_codes array
            final firstDeliveryCode = deliveryCodes[0] as Map<String, dynamic>;
            
            debugPrint('   Found delivery_codes array with ${deliveryCodes.length} item(s)');
            
            // Pass the entire delivery code object to the model
            final model = ServiceabilityModel.fromJson(firstDeliveryCode);
            
            // Log parsed result
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('✅ SERVICEABILITY CHECK RESULT');
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📮 Pincode: ${model.pincode}');
            debugPrint('🏙️ City: ${model.city ?? "N/A"}');
            debugPrint('🗺️ State: ${model.state ?? "N/A"}');
            debugPrint('🏘️ District: ${model.district ?? "N/A"}');
            debugPrint('✓ Serviceable: ${model.isServiceable ? "YES ✓" : "NO ✗"}');
            debugPrint('───────────────────────────────────────────────────────');
            debugPrint('🎯 Payment Methods Availability:');
            debugPrint('   💳 Pre-paid: ${model.supportsPrepaid ? "✓ Available" : "✗ Not Available"}');
            debugPrint('   💵 COD: ${model.supportsCOD ? "✓ Available" : "✗ Not Available"}');
            debugPrint('   📦 Pickup: ${model.pickupAvailable ? "✓ Available" : "✗ Not Available"}');
            debugPrint('   💰 Cash: ${model.cashAvailable ? "✓ Available" : "✗ Not Available"}');
            debugPrint('───────────────────────────────────────────────────────');
            debugPrint('📊 Additional Info:');
            debugPrint('   🚚 Is ODA: ${model.isOda ? "YES" : "NO"}');
            debugPrint('═══════════════════════════════════════════════════════');
            
            return model;
          } else {
            debugPrint('❌ ERROR: No delivery_codes found in response');
            debugPrint('═══════════════════════════════════════════════════════');
            
            // Return non-serviceable if no data
            return ServiceabilityModel(
              pincode: pincode,
              codAvailable: false,
              prepaidAvailable: false,
              pickupAvailable: false,
              cashAvailable: false,
              isOda: false,
            );
          }
        }
        
        debugPrint('❌ ERROR: Invalid response format from delivery service');
        debugPrint('═══════════════════════════════════════════════════════');
        throw Exception('Invalid response format from delivery service');
      } else if (response.statusCode == 404) {
        // Pincode not found - treat as non-serviceable
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('⚠️ PINCODE NOT FOUND (404)');
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('📮 Pincode: $pincode');
        debugPrint('✓ Serviceable: NO');
        debugPrint('💳 Payment Methods: None');
        debugPrint('═══════════════════════════════════════════════════════');
        
        return ServiceabilityModel(
          pincode: pincode,
          codAvailable: false,
          prepaidAvailable: false,
          pickupAvailable: false,
          cashAvailable: false,
          isOda: false,
        );
      } else {
        debugPrint('❌ ERROR: Failed to check serviceability');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        throw Exception(
          'Failed to check serviceability. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ EXCEPTION OCCURRED');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Error: ${e.toString()}');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      throw Exception('Unable to check delivery availability: ${e.toString()}');
    }
  }
}
