import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/serviceability_model.dart';
import '../utils/app_logger.dart';

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
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('DELHIVERY API REQUEST');
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('Endpoint: ${url.toString()}');
      AppLogger.info('Method: GET');
      AppLogger.info('Pincode: $pincode');
      AppLogger.info('Authorization: Token ${ApiConfig.delhiveryApiToken.substring(0, 10)}...');
      AppLogger.info('Timestamp: ${DateTime.now().toIso8601String()}');
      AppLogger.info('═══════════════════════════════════════════════════════');

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
          AppLogger.error('REQUEST TIMEOUT after 30 seconds');
          AppLogger.info('═══════════════════════════════════════════════════════');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log API Response
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('DELHIVERY API RESPONSE');
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('Status Code: ${response.statusCode}');
      AppLogger.info('Response Time: ${duration.inMilliseconds}ms');
      AppLogger.info('Response Length: ${response.body.length} bytes');
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Response Headers:');
      response.headers.forEach((key, value) {
        AppLogger.info('   $key: $value');
      });
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Response Body:');
      
      // Pretty print JSON response
      try {
        final jsonData = json.decode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
        AppLogger.info(prettyJson);
      } catch (e) {
        AppLogger.info(response.body);
      }
      AppLogger.info('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        AppLogger.info('───────────────────────────────────────────────────────');
        AppLogger.info('Parsing Response Structure...');
        
        // The new API returns: {"delivery_codes": [{"postal_code": {...}}]}
        if (data is Map<String, dynamic>) {
          final deliveryCodes = data['delivery_codes'];
          
          if (deliveryCodes is List && deliveryCodes.isNotEmpty) {
            // Get the first item from delivery_codes array
            final firstDeliveryCode = deliveryCodes[0] as Map<String, dynamic>;
            
            AppLogger.info('   Found delivery_codes array with ${deliveryCodes.length} item(s)');
            
            // Pass the entire delivery code object to the model
            final model = ServiceabilityModel.fromJson(firstDeliveryCode);
            
            // Log parsed result
            AppLogger.success('═══════════════════════════════════════════════════════');
            AppLogger.success('SERVICEABILITY CHECK RESULT');
            AppLogger.success('═══════════════════════════════════════════════════════');
            AppLogger.success('Pincode: ${model.pincode}');
            AppLogger.success('City: ${model.city ?? "N/A"}');
            AppLogger.success('State: ${model.state ?? "N/A"}');
            AppLogger.success('District: ${model.district ?? "N/A"}');
            AppLogger.success('Serviceable: ${model.isServiceable ? "YES ✓" : "NO ✗"}');
            AppLogger.info('───────────────────────────────────────────────────────');
            AppLogger.info('Payment Methods Availability:');
            AppLogger.info('   Pre-paid: ${model.supportsPrepaid ? "✓ Available" : "✗ Not Available"}');
            AppLogger.info('   COD: ${model.supportsCOD ? "✓ Available" : "✗ Not Available"}');
            AppLogger.info('   Pickup: ${model.pickupAvailable ? "✓ Available" : "✗ Not Available"}');
            AppLogger.info('   Cash: ${model.cashAvailable ? "✓ Available" : "✗ Not Available"}');
            AppLogger.info('───────────────────────────────────────────────────────');
            AppLogger.info('Additional Info:');
            AppLogger.info('   Is ODA: ${model.isOda ? "YES" : "NO"}');
            AppLogger.success('═══════════════════════════════════════════════════════');
            
            return model;
          } else {
            AppLogger.error('ERROR: No delivery_codes found in response');
            AppLogger.info('═══════════════════════════════════════════════════════');
            
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
        
        AppLogger.error('ERROR: Invalid response format from delivery service');
        AppLogger.info('═══════════════════════════════════════════════════════');
        throw Exception('Invalid response format from delivery service');
      } else if (response.statusCode == 404) {
        // Pincode not found - treat as non-serviceable
        AppLogger.warning('═══════════════════════════════════════════════════════');
        AppLogger.warning('PINCODE NOT FOUND (404)');
        AppLogger.warning('═══════════════════════════════════════════════════════');
        AppLogger.warning('Pincode: $pincode');
        AppLogger.warning('Serviceable: NO');
        AppLogger.warning('Payment Methods: None');
        AppLogger.warning('═══════════════════════════════════════════════════════');
        
        return ServiceabilityModel(
          pincode: pincode,
          codAvailable: false,
          prepaidAvailable: false,
          pickupAvailable: false,
          cashAvailable: false,
          isOda: false,
        );
      } else {
        AppLogger.error('ERROR: Failed to check serviceability');
        AppLogger.error('Status Code: ${response.statusCode}');
        AppLogger.error('Response: ${response.body}');
        AppLogger.info('═══════════════════════════════════════════════════════');
        
        throw Exception(
          'Failed to check serviceability. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      
      AppLogger.error('═══════════════════════════════════════════════════════');
      AppLogger.error('EXCEPTION OCCURRED');
      AppLogger.error('═══════════════════════════════════════════════════════');
      AppLogger.error('Error: ${e.toString()}');
      AppLogger.error('Type: ${e.runtimeType}');
      AppLogger.error('═══════════════════════════════════════════════════════');
      
      throw Exception('Unable to check delivery availability: ${e.toString()}');
    }
  }
}
