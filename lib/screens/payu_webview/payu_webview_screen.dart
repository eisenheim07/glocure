import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../config/api_config.dart';
import '../../models/customer_model.dart';
import '../../models/top_products_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_colors.dart';

class PayUWebViewScreen extends StatefulWidget {
  final Customer customer;
  final TopProduct product;
  final ProductVariant selectedVariant;
  final int quantity;
  final Function(Map<String, dynamic>) onSuccess;
  final Function(Map<String, dynamic>) onFailure;

  const PayUWebViewScreen({
    super.key,
    required this.customer,
    required this.product,
    required this.selectedVariant,
    required this.quantity,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<PayUWebViewScreen> createState() => _PayUWebViewScreenState();
}

class _PayUWebViewScreenState extends State<PayUWebViewScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    AppLogger.info('🌐 Initializing PayU WebView');

    // Generate payment parameters
    final txnId = DateTime.now().millisecondsSinceEpoch.toString();
    // TODO: Remove hardcoded amount after testing
    final amount = '1.00'; // Hardcoded for testing - was: (double.parse(widget.selectedVariant.priceV2.amount) * widget.quantity).toStringAsFixed(2)
    final productInfo = 'Order - ${widget.product.title}';
    final firstName = widget.customer.firstName ?? 'Customer';
    final email = widget.customer.email ?? 'customer@glocure.com';

    // Get phone number
    String phone = '';
    if (widget.customer.defaultAddress?.phone != null && widget.customer.defaultAddress!.phone!.isNotEmpty) {
      phone = widget.customer.defaultAddress!.phone!;
    } else if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty) {
      phone = widget.customer.phone!;
    } else {
      phone = '9999999999';
    }
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Generate hash
    final hashString = '${ApiConfig.payuMerchantKey}|$txnId|$amount|$productInfo|$firstName|$email|||||||||||${ApiConfig.payuMerchantSalt}';
    final hash = sha512.convert(utf8.encode(hashString)).toString();

    AppLogger.info('💳 Payment details: txnId=$txnId, amount=₹$amount');

    // Generate HTML
    final html = _generatePaymentHTML(
      txnId: txnId,
      amount: amount,
      productInfo: productInfo,
      firstName: firstName,
      email: email,
      phone: phone,
      hash: hash,
    );

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.info('📄 Page started: $url');
            _checkPaymentResult(url);
          },
          onPageFinished: (String url) {
            AppLogger.info('✅ Page finished: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.info('🔗 Navigation request: ${request.url}');

            // Log glocure.com URLs with parameters
            if (request.url.contains('glocure.com')) {
              AppLogger.warning('🌐 Glocure URL detected: ${request.url}');

              try {
                final uri = Uri.parse(request.url);
                if (uri.queryParameters.isNotEmpty) {
                  AppLogger.info('📋 Query parameters:');
                  uri.queryParameters.forEach((key, value) {
                    AppLogger.info('  $key = $value');
                  });
                }
              } catch (e) {
                AppLogger.error('Failed to parse URL: $e');
              }
            }

            // Handle UPI and payment app schemes
            if (request.url.startsWith('upi://') ||
                request.url.startsWith('tez://') ||
                request.url.startsWith('paytmmp://') ||
                request.url.startsWith('phonepe://') ||
                request.url.startsWith('gpay://')) {
              AppLogger.info('🚀 Launching payment app');
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

            // Check for payment result - ONLY intercept OUR URLs
            if (_isPaymentResultUrl(request.url)) {
              AppLogger.warning('✋ Payment result URL intercepted');
              _checkPaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(html);
  }

  /// Generate PayU payment HTML form
  String _generatePaymentHTML({
    required String txnId,
    required String amount,
    required String productInfo,
    required String firstName,
    required String email,
    required String phone,
    required String hash,
  }) {
    final baseUrl = ApiConfig.payuIsProduction ? 'https://secure.payu.in/_payment' : 'https://test.payu.in/_payment';

    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Processing Payment...</title>
    <style>
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background: linear-gradient(135deg, #FF5C9A 0%, #FF8FB3 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 20px 60px rgba(255, 92, 154, 0.3);
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #FF5C9A;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        h2 {
            color: #333;
            margin: 0 0 10px 0;
        }
        p {
            color: #666;
            margin: 0;
        }
    </style>
</head>
<body onload="document.forms[0].submit()">
    <div class="container">
        <div class="spinner"></div>
        <h2>Processing Payment</h2>
        <p>Please wait while we redirect you to the payment gateway...</p>
    </div>
    <form action="$baseUrl" method="post">
        <input type="hidden" name="key" value="${ApiConfig.payuMerchantKey}" />
        <input type="hidden" name="txnid" value="$txnId" />
        <input type="hidden" name="amount" value="$amount" />
        <input type="hidden" name="productinfo" value="$productInfo" />
        <input type="hidden" name="firstname" value="$firstName" />
        <input type="hidden" name="email" value="$email" />
        <input type="hidden" name="phone" value="$phone" />
        <input type="hidden" name="surl" value="https://glocure.com/payment/success" />
        <input type="hidden" name="furl" value="https://glocure.com/payment/failure" />
        <input type="hidden" name="hash" value="$hash" />
    </form>
</body>
</html>
    """;
  }

  /// Check if URL is a payment result URL
  bool _isPaymentResultUrl(String url) {
    // ONLY intercept OUR redirect URLs, not PayU's intermediate pages
    if (url.contains('glocure.com/payment/success') ||
        url.contains('glocure.com/payment/failure') ||
        url.contains('glocure.com/pages/payment-success') ||
        url.contains('glocure.com/pages/payment-failure')) {
      AppLogger.info('✅ Our redirect URL detected');
      return true;
    }

    // DO NOT intercept PayU's intermediate pages
    if (url.contains('payu.in/response') || url.contains('payu.in/merchant/postservice')) {
      AppLogger.info('⏭️ PayU intermediate page - letting it continue');
      return false;
    }

    return false;
  }

  /// Check payment result from URL
  void _checkPaymentResult(String url) {
    if (_paymentCompleted) return;

    if (_isPaymentResultUrl(url)) {
      _paymentCompleted = true;

      AppLogger.info('🎯 Payment result detected: $url');

      // Parse URL
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      // Log all parameters
      AppLogger.info('📋 All URL parameters:');
      params.forEach((key, value) {
        AppLogger.info('  $key: $value');
      });

      // Determine status - check URL first, then parameters
      String status = 'failed';

      if (url.contains('success')) {
        status = 'success';
        AppLogger.info('✅ Status: SUCCESS (URL contains success)');
      } else if (url.contains('failure')) {
        status = 'failed';
        AppLogger.info('❌ Status: FAILURE (URL contains failure)');
      } else if (params['status'] != null) {
        status = params['status']!.toLowerCase() == 'success' ? 'success' : 'failed';
        AppLogger.info('💰 Status from param: $status');
      }

      final result = {
        'status': status,
        'url': url,
        'params': params,
        'txnid': params['txnid'] ?? '',
        'amount': params['amount'] ?? '',
        'mihpayid': params['mihpayid'] ?? '',
        'error_Message': params['error_Message'] ?? '',
      };

      AppLogger.success('📦 Final result: $result');

      // Call appropriate callback
      if (status == 'success') {
        widget.onSuccess(result);
      } else {
        widget.onFailure(result);
      }

      // Close screen
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Launch external URL for UPI apps
  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.success('✅ External app launched');
      } else {
        AppLogger.warning('⚠️ Cannot launch URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open payment app. Please install a UPI app.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('❌ Failed to launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Payment?'),
            content: const Text('Are you sure you want to cancel this payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayU Payment'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              WebViewWidget(controller: controller),

              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading Payment Gateway...',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
