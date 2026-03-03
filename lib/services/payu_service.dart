import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';

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
    
    AppLogger.info('═══════════════════════════════════════════════════════');
    AppLogger.info('GENERATING PAYU HASH');
    AppLogger.info('═══════════════════════════════════════════════════════');
    AppLogger.info('Hash String: $hashString');
    
    final bytes = utf8.encode(hashString);
    final hash = sha512.convert(bytes);
    final hashHex = hash.toString();
    
    AppLogger.info('Generated Hash: $hashHex');
    AppLogger.info('═══════════════════════════════════════════════════════');
    
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
    AppLogger.info('═══════════════════════════════════════════════════════');
    AppLogger.info('PREPARING PAYU PAYMENT PARAMETERS');
    AppLogger.info('═══════════════════════════════════════════════════════');
    AppLogger.info('Environment: ${ApiConfig.payuIsProduction ? "PRODUCTION" : "TEST MODE"}');
    
    if (!ApiConfig.payuIsProduction) {
      AppLogger.warning('TEST MODE ACTIVE');
      AppLogger.info('For testing, use:');
      AppLogger.info('   Credit Card: 5123456789012346, CVV: 123, Expiry: 12/25');
      AppLogger.warning('   UPI validation is unreliable in test mode - use card instead');
    }
    
    // Generate unique transaction ID
    final txnId = 'ORDER_${orderNumber}_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.info('Transaction ID: $txnId');
    
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

    AppLogger.info('───────────────────────────────────────────────────────');
    AppLogger.info('Payment Parameters:');
    AppLogger.info('Merchant Key: ${ApiConfig.payuMerchantKey}');
    AppLogger.info('Transaction ID: $txnId');
    AppLogger.info('Amount: ₹$amount');
    AppLogger.info('Product Info: $productInfo');
    AppLogger.info('Customer: $firstName $lastName');
    AppLogger.info('Email: $email');
    AppLogger.info('Phone: $phone');
    AppLogger.info('Success URL: $successUrl');
    AppLogger.info('Failure URL: $failureUrl');
    AppLogger.info('Enforce Payment Methods: creditcard|debitcard|netbanking|upi');
    AppLogger.info('Service Provider: payu_paisa');
    AppLogger.info('═══════════════════════════════════════════════════════');

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
      AppLogger.info('═══════════════════════════════════════════════════════');
      AppLogger.info('VERIFYING PAYMENT HASH');
      AppLogger.info('═══════════════════════════════════════════════════════');
      
      // Reverse hash format: salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key
      final hashString = '${ApiConfig.payuMerchantSalt}|$status||||||$udf5|$udf4|$udf3|$udf2|$udf1|$email|$firstName|$productInfo|$amount|$txnId|${ApiConfig.payuMerchantKey}';
      
      AppLogger.info('Hash String: $hashString');
      
      final bytes = utf8.encode(hashString);
      final hash = sha512.convert(bytes);
      final calculatedHash = hash.toString();

      final isValid = calculatedHash == receivedHash;
      
      AppLogger.info('Received Hash: $receivedHash');
      AppLogger.info('Calculated Hash: $calculatedHash');
      AppLogger.info('Valid: $isValid');
      AppLogger.info('═══════════════════════════════════════════════════════');

      return isValid;
    } catch (e) {
      AppLogger.error('Hash verification failed: $e');
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
