import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/customer_model.dart';

/// Order Service
/// Handles order creation and management via Shopify REST API
class OrderService {
  static const String _baseUrl = 'https://bxaqgp-p1.myshopify.com/admin/api/2025-10';

  /// Create order in Shopify
  /// 
  /// [cart] - Cart with line items
  /// [customer] - Customer information
  /// [paymentMethod] - 'Pre-paid' or 'COD'
  /// Returns created [OrderModel]
  Future<OrderModel> createOrder({
    required Cart cart,
    required Customer customer,
    required String paymentMethod,
  }) async {
    try {
      // Validate inputs
      if (cart.lines.isEmpty) {
        throw Exception('Cart is empty');
      }

      if (customer.defaultAddress == null) {
        throw Exception('Shipping address is required');
      }

      final address = customer.defaultAddress!;
      if (!_isAddressValid(address)) {
        throw Exception('Invalid shipping address');
      }

      // Validate email
      if (customer.email == null || customer.email!.isEmpty) {
        throw Exception('Customer email is required');
      }

      // Prepare line items
      debugPrint('🔍 Processing ${cart.lines.length} cart items...');
      final lineItems = <Map<String, dynamic>>[];
      
      for (var i = 0; i < cart.lines.length; i++) {
        final cartLine = cart.lines[i];
        final merchandise = cartLine.merchandise;
        
        if (merchandise == null) {
          debugPrint('❌ Cart item $i has no merchandise');
          throw Exception('Invalid cart item at index $i');
        }

        debugPrint('📦 Item $i: ${merchandise.product.title}');
        debugPrint('   Variant ID (GID): ${merchandise.id}');
        
        final variantId = _extractNumericId(merchandise.id);
        debugPrint('   Variant ID (Numeric): $variantId');
        
        try {
          final numericId = int.parse(variantId);
          lineItems.add({
            'variant_id': numericId,
            'quantity': cartLine.quantity,
          });
          debugPrint('   ✅ Added: variant_id=$numericId, qty=${cartLine.quantity}');
        } catch (e) {
          debugPrint('   ❌ Failed to parse variant ID: $e');
          throw Exception('Invalid variant ID format: $variantId');
        }
      }

      // Prepare shipping address
      debugPrint('📍 Preparing shipping address...');
      final shippingAddress = {
        'first_name': address.firstName ?? customer.firstName ?? 'Customer',
        'last_name': address.lastName ?? customer.lastName ?? 'Name',
        'address1': address.address1 ?? '',
        'city': address.city ?? '',
        'province': address.province ?? '',
        'country': address.country ?? 'India',
        'zip': address.zip ?? '',
        'phone': address.phone ?? customer.phone ?? '',
      };
      
      if (address.address2 != null && address.address2!.isNotEmpty) {
        shippingAddress['address2'] = address.address2!;
      }

      final billingAddress = Map<String, dynamic>.from(shippingAddress);

      // Prepare order payload
      final orderPayload = {
        'order': {
          'email': customer.email,
          'line_items': lineItems,
          'financial_status': 'pending',
          'shipping_address': shippingAddress,
          'billing_address': billingAddress,
          'note': 'Payment Method: $paymentMethod',
          'tags': 'mobile-app,$paymentMethod',
        }
      };

      // Log request
      final fullUrl = '$_baseUrl/orders.json';
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📦 SHOPIFY ORDER CREATION REQUEST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔗 Full URL: $fullUrl');
      debugPrint('🔗 Method: POST');
      debugPrint('📧 Email: ${customer.email}');
      debugPrint('📦 Items: ${lineItems.length}');
      debugPrint('💳 Payment Method: $paymentMethod');
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📋 Headers:');
      debugPrint('   X-Shopify-Access-Token: ${ApiConfig.shopifyAdminAccessToken}');
      debugPrint('   Content-Type: application/json');
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📝 Raw JSON Body:');
      debugPrint(json.encode(orderPayload));
      debugPrint('═══════════════════════════════════════════════════════');

      final startTime = DateTime.now();

      // Create a client that doesn't follow redirects
      final client = http.Client();
      http.Response response;
      
      try {
        // Make API request using Request to have more control
        final request = http.Request('POST', Uri.parse('$_baseUrl/orders.json'));
        request.headers['X-Shopify-Access-Token'] = ApiConfig.shopifyAdminAccessToken;
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode(orderPayload);
        
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('❌ REQUEST TIMEOUT after 30 seconds');
            throw Exception('Request timeout');
          },
        );
        
        response = await http.Response.fromStream(streamedResponse);
      } finally {
        client.close();
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log response
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 SHOPIFY ORDER CREATION RESPONSE');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('⏱️ Response Time: ${duration.inMilliseconds}ms');
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📋 Response Headers:');
      response.headers.forEach((key, value) {
        debugPrint('   $key: $value');
      });
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('📝 Response Body:');
      if (response.body.isNotEmpty) {
        try {
          final jsonData = json.decode(response.body);
          debugPrint(const JsonEncoder.withIndent('  ').convert(jsonData));
        } catch (e) {
          debugPrint(response.body);
        }
      } else {
        debugPrint('(empty)');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      // Handle redirect
      if (response.statusCode == 301 || response.statusCode == 302) {
        final location = response.headers['location'];
        debugPrint('❌ REDIRECT DETECTED');
        debugPrint('Redirect Location: $location');
        debugPrint('Original URL: $_baseUrl/orders.json');
        throw Exception('API redirected to: $location');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['order'] != null) {
          final order = OrderModel.fromJson(data['order']);
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('✅ ORDER CREATED SUCCESSFULLY');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🆔 Order ID: ${order.id}');
          debugPrint('📋 Order Number: ${order.orderNumber}');
          debugPrint('💰 Total Price: ${order.totalPrice}');
          debugPrint('═══════════════════════════════════════════════════════');
          
          return order;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'] ?? {};
        
        debugPrint('❌ VALIDATION ERROR (422)');
        debugPrint('Errors: $errors');
        
        String errorMessage = 'Validation failed';
        if (errors is Map) {
          final errorList = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorList.add('$key: ${value.join(", ")}');
            } else {
              errorList.add('$key: $value');
            }
          });
          if (errorList.isNotEmpty) {
            errorMessage = errorList.join('; ');
          }
        }
        
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        debugPrint('❌ AUTHENTICATION ERROR (401)');
        throw Exception('Authentication failed');
      } else if (response.statusCode == 403) {
        debugPrint('❌ PERMISSION ERROR (403)');
        throw Exception('Permission denied');
      } else {
        debugPrint('❌ ERROR: Status ${response.statusCode}');
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ EXCEPTION: ${e.toString()}');
      rethrow;
    }
  }

  /// Extract numeric ID from Shopify GID
  String _extractNumericId(String gid) {
    final parts = gid.split('/');
    return parts.last;
  }

  /// Validate address has required fields
  bool _isAddressValid(CustomerAddress address) {
    return address.address1 != null &&
        address.address1!.isNotEmpty &&
        address.city != null &&
        address.city!.isNotEmpty &&
        address.zip != null &&
        address.zip!.isNotEmpty;
  }

  /// Get order by ID
  Future<OrderModel> getOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': ApiConfig.shopifyAdminAccessToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderModel.fromJson(data['order']);
      } else {
        throw Exception('Failed to get order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Unable to get order: ${e.toString()}');
    }
  }

  /// Update order financial status
  Future<void> updateOrderStatus({
    required String orderId,
    required String financialStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': ApiConfig.shopifyAdminAccessToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order': {
            'id': orderId,
            'financial_status': financialStatus,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update order: ${response.statusCode}');
      }

      debugPrint('✅ Order status updated: $financialStatus');
    } catch (e) {
      throw Exception('Unable to update order: ${e.toString()}');
    }
  }
}
