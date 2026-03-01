import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// PayU Payment Service
/// Handles PayU payment hash generation and parameter preparation
class PayUService {
  static final PayUService _instance = PayUService._internal();
  factory PayUService() => _instance;
  PayUService._internal();

  /// PayU payment URL
  static const String _testUrl = 'https://test.payu.in/_payment';
  static const String _productionUrl = 'https://secure.payu.in/_payment';

  /// Get PayU payment URL based on environment
  String get paymentUrl => ApiConfig.payuIsProduction ? _productionUrl : _testUrl;

  /// Generate PayU hash for payment
  /// Hash format: key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt
  String generateHash({
    required String txnId,
    required String amount,
    required String productInfo,
    required String firstName,
    required String email,
    String udf1 = '',
    String udf2 = '',
    String udf3 = '',
    String udf4 = '',
    String udf5 = '',
  }) {
    final hashString = '${ApiConfig.payuMerchantKey}|$txnId|$amount|$productInfo|$firstName|$email|$udf1|$udf2|$udf3|$udf4|$udf5||||||${ApiConfig.payuMerchantSalt}';
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔐 GENERATING PAYU HASH');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Hash String: $hashString');
    
    final bytes = utf8.encode(hashString);
    final hash = sha512.convert(bytes);
    final hashHex = hash.toString();
    
    debugPrint('Generated Hash: $hashHex');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return hashHex;
  }

  /// Prepare payment parameters for PayU
  Map<String, String> preparePaymentParams({
    required String orderId,
    required String orderNumber,
    required String amount,
    required String productInfo,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String successUrl,
    required String failureUrl,
  }) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('💳 PREPARING PAYU PAYMENT PARAMETERS');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Environment: ${ApiConfig.payuIsProduction ? "PRODUCTION" : "TEST MODE"}');
    
    if (!ApiConfig.payuIsProduction) {
      debugPrint('⚠️ TEST MODE ACTIVE');
      debugPrint('📝 For testing, use:');
      debugPrint('   Credit Card: 5123456789012346, CVV: 123, Expiry: 12/25');
      debugPrint('   ⚠️ UPI validation is unreliable in test mode - use card instead');
    }
    
    // Generate unique transaction ID
    final txnId = 'ORDER_${orderNumber}_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('Transaction ID: $txnId');
    
    // Generate hash
    final hash = generateHash(
      txnId: txnId,
      amount: amount,
      productInfo: productInfo,
      firstName: firstName,
      email: email,
      udf1: orderId,
      udf2: orderNumber,
    );

    final params = {
      'key': ApiConfig.payuMerchantKey,
      'txnid': txnId,
      'amount': amount,
      'productinfo': productInfo,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'phone': phone,
      'surl': successUrl,
      'furl': failureUrl,
      'hash': hash,
      'udf1': orderId,
      'udf2': orderNumber,
      'udf3': '',
      'udf4': '',
      'udf5': '',
      // Enforce specific payment methods only
      'enforce_paymethod': 'creditcard|debitcard|netbanking|upi',
      // Additional parameters for better compatibility
      'service_provider': 'payu_paisa',
    };

    debugPrint('───────────────────────────────────────────────────────');
    debugPrint('📝 Payment Parameters:');
    debugPrint('Merchant Key: ${ApiConfig.payuMerchantKey}');
    debugPrint('Transaction ID: $txnId');
    debugPrint('Amount: ₹$amount');
    debugPrint('Product Info: $productInfo');
    debugPrint('Customer: $firstName $lastName');
    debugPrint('Email: $email');
    debugPrint('Phone: $phone');
    debugPrint('Success URL: $successUrl');
    debugPrint('Failure URL: $failureUrl');
    debugPrint('Enforce Payment Methods: creditcard|debitcard|netbanking|upi');
    debugPrint('Service Provider: payu_paisa');
    debugPrint('═══════════════════════════════════════════════════════');

    return params;
  }

  /// Verify payment response hash
  bool verifyPaymentResponse({
    required String status,
    required String txnId,
    required String amount,
    required String productInfo,
    required String firstName,
    required String email,
    required String receivedHash,
    String udf1 = '',
    String udf2 = '',
    String udf3 = '',
    String udf4 = '',
    String udf5 = '',
  }) {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔐 VERIFYING PAYMENT HASH');
      debugPrint('═══════════════════════════════════════════════════════');
      
      // Reverse hash format: salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key
      final hashString = '${ApiConfig.payuMerchantSalt}|$status||||||$udf5|$udf4|$udf3|$udf2|$udf1|$email|$firstName|$productInfo|$amount|$txnId|${ApiConfig.payuMerchantKey}';
      
      debugPrint('Hash String: $hashString');
      
      final bytes = utf8.encode(hashString);
      final hash = sha512.convert(bytes);
      final calculatedHash = hash.toString();

      final isValid = calculatedHash == receivedHash;
      
      debugPrint('Received Hash: $receivedHash');
      debugPrint('Calculated Hash: $calculatedHash');
      debugPrint('Valid: $isValid');
      debugPrint('═══════════════════════════════════════════════════════');

      return isValid;
    } catch (e) {
      debugPrint('❌ Hash verification failed: $e');
      return false;
    }
  }

  /// Build HTML form for PayU payment
  String buildPaymentForm(Map<String, String> params) {
    final formFields = params.entries
        .map((entry) => '<input type="hidden" name="${entry.key}" value="${entry.value}" />')
        .join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Processing Payment...</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .loader {
            text-align: center;
            color: white;
        }
        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 4px solid white;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        h2 {
            margin: 0;
            font-size: 24px;
        }
        p {
            margin: 10px 0 0;
            font-size: 14px;
            opacity: 0.9;
        }
    </style>
</head>
<body>
    <div class="loader">
        <div class="spinner"></div>
        <h2>Processing Payment</h2>
        <p>Please wait, redirecting to payment gateway...</p>
    </div>
    <form id="payuForm" action="$paymentUrl" method="post">
        $formFields
    </form>
    <script>
        document.getElementById('payuForm').submit();
    </script>
</body>
</html>
''';
  }
}
