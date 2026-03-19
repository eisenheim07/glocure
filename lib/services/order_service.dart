import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/customer_model.dart';
import '../utils/app_logger.dart';

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
      AppLogger.info('Processing ${cart.lines.length} cart items...');
      final lineItems = <Map<String, dynamic>>[];
      
      for (var i = 0; i < cart.lines.length; i++) {
        final cartLine = cart.lines[i];
        final merchandise = cartLine.merchandise;
        
        if (merchandise == null) {
          AppLogger.error('Cart item $i has no merchandise');
          throw Exception('Invalid cart item at index $i');
        }

        AppLogger.info('Item $i: ${merchandise.product.title}');
        AppLogger.info('   Variant ID (GID): ${merchandise.id}');
        
        final variantId = _extractNumericId(merchandise.id);
        AppLogger.info('   Variant ID (Numeric): $variantId');
        
        try {
          final numericId = int.parse(variantId);
          lineItems.add({
            'variant_id': numericId,
            'quantity': cartLine.quantity,
          });
          AppLogger.success('   Added: variant_id=$numericId, qty=${cartLine.quantity}');
        } catch (e) {
          AppLogger.error('   Failed to parse variant ID: $e');
          throw Exception('Invalid variant ID format: $variantId');
        }
      }

      // Prepare shipping address
      AppLogger.info('Preparing shipping address...');
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
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('SHOPIFY ORDER CREATION REQUEST');
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('Full URL: $fullUrl');
      AppLogger.info('Method: POST');
      AppLogger.info('Email: ${customer.email}');
      AppLogger.info('Items: ${lineItems.length}');
      AppLogger.info('Payment Method: $paymentMethod');
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Headers:');
      AppLogger.info('   X-Shopify-Access-Token: ${ApiConfig.shopifyAdminAccessToken}');
      AppLogger.info('   Content-Type: application/json');
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Raw JSON Body:');
      AppLogger.info(json.encode(orderPayload));
      AppLogger.info('═══════════════════════════════════════════════════════');

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
            AppLogger.error('REQUEST TIMEOUT after 30 seconds');
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
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('SHOPIFY ORDER CREATION RESPONSE');
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('Status Code: ${response.statusCode}');
      AppLogger.info('Response Time: ${duration.inMilliseconds}ms');
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Response Headers:');
      response.headers.forEach((key, value) {
        AppLogger.info('   $key: $value');
      });
      AppLogger.info('───────────────────────────────────────────────────────');
      AppLogger.info('Response Body:');
      if (response.body.isNotEmpty) {
        try {
          final jsonData = json.decode(response.body);
          AppLogger.info(const JsonEncoder.withIndent('  ').convert(jsonData));
        } catch (e) {
          AppLogger.info(response.body);
        }
      } else {
        AppLogger.info('(empty)');
      }
      AppLogger.info('═══════════════════════════════════════════════════════');

      // Handle redirect
      if (response.statusCode == 301 || response.statusCode == 302) {
        final location = response.headers['location'];
        AppLogger.error('REDIRECT DETECTED');
        AppLogger.error('Redirect Location: $location');
        AppLogger.error('Original URL: $_baseUrl/orders.json');
        throw Exception('API redirected to: $location');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['order'] != null) {
          final order = OrderModel.fromJson(data['order']);
          
          AppLogger.success('═══════════════════════════════════════════════════════');
          AppLogger.success('ORDER CREATED SUCCESSFULLY');
          AppLogger.success('═══════════════════════════════════════════════════════');
          AppLogger.success('Order ID: ${order.id}');
          AppLogger.success('Order Number: ${order.orderNumber}');
          AppLogger.success('Total Price: ${order.totalPrice}');
          AppLogger.success('═══════════════════════════════════════════════════════');
          
          return order;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'] ?? {};
        
        AppLogger.error('VALIDATION ERROR (422)');
        AppLogger.error('Errors: $errors');
        
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
        AppLogger.error('AUTHENTICATION ERROR (401)');
        throw Exception('Authentication failed');
      } else if (response.statusCode == 403) {
        AppLogger.error('PERMISSION ERROR (403)');
        throw Exception('Permission denied');
      } else {
        AppLogger.error('ERROR: Status ${response.statusCode}');
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('EXCEPTION: ${e.toString()}');
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

      AppLogger.success('Order status updated: $financialStatus');
    } catch (e) {
      throw Exception('Unable to update order: ${e.toString()}');
    }
  }
}
