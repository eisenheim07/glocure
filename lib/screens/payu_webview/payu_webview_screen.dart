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
  WebViewController? controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  String? _txnId;
  String? _amount;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    // Clean up to prevent assertion errors
    controller = null;
    super.dispose();
  }

  void _initializeWebView() async {
    AppLogger.info('🌐 Initializing PayU WebView');

    // Enable cookies for PayU session management
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    AppLogger.info('🍪 Cookies cleared and enabled');

    // Generate payment parameters
    final txnId = DateTime.now().millisecondsSinceEpoch.toString();
    // Calculate total amount (price * quantity) and format to 2 decimal places
    String amount = '0';
    amount =
        (double.parse(widget.selectedVariant.priceV2.amount) * widget.quantity)
            .toStringAsFixed(2);

    /// Adding flat shipping charge of 99
    if (double.parse(amount) < 1000 && double.parse(amount) > 0) {
      amount = (double.parse(amount) + 99).toStringAsFixed(2);
    }

    final productInfo = 'Order - ${widget.product.title}';
    final firstName = widget.customer.firstName ?? 'Customer';
    final email = widget.customer.email ?? 'customer@glocure.com';

    // Store for later use
    _txnId = txnId;
    _amount = amount;

    // Get phone number
    String phone = '';
    if (widget.customer.defaultAddress?.phone != null &&
        widget.customer.defaultAddress!.phone!.isNotEmpty) {
      phone = widget.customer.defaultAddress!.phone!;
    } else if (widget.customer.phone != null &&
        widget.customer.phone!.isNotEmpty) {
      phone = widget.customer.phone!;
    } else {
      phone = '9999999999';
    }
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Generate hash
    final hashString =
        '${ApiConfig.payuMerchantKey}|$txnId|$amount|$productInfo|$firstName|$email|||||||||||${ApiConfig.payuMerchantSalt}';
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

    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..addJavaScriptChannel(
        'PayUFlutter',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted || _paymentCompleted) return;

          AppLogger.info('📨 JavaScript message: ${message.message}');

          // Handle payment status from JavaScript
          if (message.message.startsWith('PAYMENT_')) {
            final status =
                message.message.replaceFirst('PAYMENT_', '').toLowerCase();
            AppLogger.warning('🎯 Payment status detected from JS: $status');

            if (!_paymentCompleted && mounted) {
              _paymentCompleted = true;

              final result = {
                'status': status == 'success' ? 'success' : 'failed',
                'url': 'javascript_detected',
                'params': {},
                'txnid': _txnId ?? '',
                'amount': _amount ?? '',
                'mihpayid': '',
                'error_Message':
                    status == 'failed' ? 'Payment declined or failed' : '',
              };

              if (status == 'success') {
                widget.onSuccess(result);
              } else {
                widget.onFailure(result);
              }
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.info('📄 PAYU_SDK_WEBVIEW ===>>> Page started: $url');
            _checkPaymentResult(url);
          },
          onPageFinished: (String url) {
            AppLogger.info('✅ PAYU_SDK_WEBVIEW ===>>>  Page finished: $url');

            // Inject JavaScript to detect PayU's feedback/result pages
            if (url.contains('api.payu.in/public')) {
              _injectPaymentDetectionScript();
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.info(
                '🔗 PAYU_SDK_WEBVIEW ===>>>  Navigation request: ${request.url}');

            // Log glocure.com URLs with parameters
            if (request.url.contains('glocure.com')) {
              AppLogger.warning(
                  '🌐 PAYU_SDK_WEBVIEW ===>>>  Glocure URL detected: ${request.url}');

              try {
                final uri = Uri.parse(request.url);
                if (uri.queryParameters.isNotEmpty) {
                  AppLogger.info(
                      '📋 PAYU_SDK_WEBVIEW ===>>>  Query parameters:');
                  uri.queryParameters.forEach((key, value) {
                    AppLogger.info('  $key = $value');
                  });
                }
              } catch (e) {
                AppLogger.error('Failed to parse URL: $e');
              }
            }

            // Handle UPI, payment app schemes, and Android intent URLs
            if (request.url.startsWith('upi://') ||
                request.url.startsWith('tez://') ||
                request.url.startsWith('paytmmp://') ||
                request.url.startsWith('phonepe://') ||
                request.url.startsWith('gpay://') ||
                request.url.startsWith('intent://')) {
              AppLogger.info(
                  '🚀 PAYU_SDK_WEBVIEW ===>>>  Launching payment app/intent');
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

            // Check for payment result - ONLY intercept OUR URLs
            if (_isPaymentResultUrl(request.url)) {
              AppLogger.warning(
                  '✋ PAYU_SDK_WEBVIEW ===>>>  Payment result URL intercepted');
              _checkPaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error(
                '❌ PAYU_SDK_WEBVIEW ===>>>  WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(html);

    // Update state with initialized controller
    if (mounted) {
      setState(() {
        controller = webViewController;
      });
    }
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
    final baseUrl = ApiConfig.payuIsProduction
        ? 'https://secure.payu.in/_payment'
        : 'https://test.payu.in/_payment';

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

  /// Inject JavaScript to detect PayU's payment result pages
  void _injectPaymentDetectionScript() {
    if (controller == null) return;

    AppLogger.info('💉 Injecting payment detection script');

    final script = """
      (function() {
        console.log('PayU Detection Script Loaded');
        
        // Check for "GO BACK" button or failure indicators
        function checkPaymentStatus() {
          var bodyText = document.body.innerText || document.body.textContent || '';
          var bodyHTML = document.body.innerHTML || '';
          
          console.log('Checking page content...');
          
          // Check for failure/declined indicators
          if (bodyText.includes('Transaction Failed') || 
              bodyText.includes('Payment Failed') ||
              bodyText.includes('Transaction Declined') ||
              bodyText.includes('Payment Declined') ||
              bodyText.includes('GO BACK') ||
              bodyHTML.includes('transaction-failed') ||
              bodyHTML.includes('payment-failed')) {
            console.log('Payment failure detected!');
            if (window.PayUFlutter) {
              window.PayUFlutter.postMessage('PAYMENT_FAILED');
            }
            return true;
          }
          
          // Check for success indicators
          if (bodyText.includes('Transaction Successful') || 
              bodyText.includes('Payment Successful') ||
              bodyText.includes('Success') ||
              bodyHTML.includes('transaction-success') ||
              bodyHTML.includes('payment-success')) {
            console.log('Payment success detected!');
            if (window.PayUFlutter) {
              window.PayUFlutter.postMessage('PAYMENT_SUCCESS');
            }
            return true;
          }
          
          return false;
        }
        
        // Check immediately
        setTimeout(checkPaymentStatus, 500);
        setTimeout(checkPaymentStatus, 1000);
        setTimeout(checkPaymentStatus, 2000);
        
        // Monitor for DOM changes
        var observer = new MutationObserver(function(mutations) {
          checkPaymentStatus();
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true,
          characterData: true
        });
        
        // Monitor for button clicks
        document.addEventListener('click', function(e) {
          console.log('Click detected on:', e.target);
          setTimeout(checkPaymentStatus, 500);
        }, true);
        
        console.log('PayU Detection Script Active');
      })();
    """;

    controller!.runJavaScript(script);
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
    if (url.contains('payu.in/response') ||
        url.contains('payu.in/merchant/postservice')) {
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
        status =
            params['status']!.toLowerCase() == 'success' ? 'success' : 'failed';
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

      // Call appropriate callback FIRST (they will handle navigation)
      if (status == 'success') {
        widget.onSuccess(result);
      } else {
        widget.onFailure(result);
      }

      // Note: Don't pop here - let the callbacks handle navigation
      // The callbacks in CommonPaymentFlow will pop with result
    }
  }

  /// Launch external URL for UPI apps and Android intents
  Future<void> _launchExternalUrl(String url) async {
    try {
      AppLogger.info('🚀 Attempting to launch: $url');

      // For intent URLs, try multiple launch strategies
      if (url.startsWith('intent://')) {
        AppLogger.info('🤖 Detected Android intent URL');

        // Strategy 1: Try launching the intent URL directly
        try {
          final intentUri = Uri.parse(url);
          AppLogger.info('📱 Strategy 1: Launching intent directly...');

          final launched = await launchUrl(
            intentUri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            AppLogger.success('✅ Intent launched successfully!');
            return;
          }
          AppLogger.warning('⚠️ Strategy 1 failed, trying fallback...');
        } catch (e) {
          AppLogger.error('Strategy 1 error: $e');
        }

        // Strategy 2: Extract UPI URL from intent and launch
        try {
          AppLogger.info('📱 Strategy 2: Extracting UPI from intent...');

          // Parse intent URL: intent://pay?params#Intent;scheme=upi;package=...;end
          final intentUri = Uri.parse(url);
          final path = intentUri.path;
          final query = intentUri.query;
          final fragment = intentUri.fragment;

          if (fragment.contains('scheme=upi')) {
            // Reconstruct as upi:// URL
            final upiUrl = 'upi:/$path${query.isNotEmpty ? '?$query' : ''}';
            AppLogger.info('🔄 Converted to UPI: $upiUrl');

            final upiUri = Uri.parse(upiUrl);
            final launched = await launchUrl(
              upiUri,
              mode: LaunchMode.externalApplication,
            );

            if (launched) {
              AppLogger.success('✅ UPI URL launched successfully!');
              return;
            }
            AppLogger.warning('⚠️ Strategy 2 failed');
          }
        } catch (e) {
          AppLogger.error('Strategy 2 error: $e');
        }

        // Strategy 3: Try to extract package name and launch specific app
        try {
          AppLogger.info('📱 Strategy 3: Checking for fallback URL...');

          // Look for browser_fallback_url in the intent
          if (url.contains('browser_fallback_url=')) {
            final fallbackMatch =
                RegExp(r'browser_fallback_url=([^;]+)').firstMatch(url);
            if (fallbackMatch != null) {
              final fallbackUrl = Uri.decodeComponent(fallbackMatch.group(1)!);
              AppLogger.info('🔄 Found fallback URL: $fallbackUrl');

              // Don't navigate to fallback - just show message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please select a different payment method or install the payment app'),
                    backgroundColor: AppColors.warning,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              return;
            }
          }
        } catch (e) {
          AppLogger.error('Strategy 3 error: $e');
        }

        // All strategies failed
        AppLogger.error('❌ All launch strategies failed for intent URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to open payment app. Please install the required UPI app.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Regular UPI/payment app URLs
      final uri = Uri.parse(url);
      AppLogger.info('📱 Launching regular URL: ${uri.scheme}://');

      if (await canLaunchUrl(uri)) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          AppLogger.success('✅ External app launched');
        } else {
          AppLogger.warning('⚠️ Launch returned false');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open payment app'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        AppLogger.warning('⚠️ Cannot launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Unable to open payment app. Please install a UPI app.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('❌ Failed to launch URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If payment already completed, allow back navigation
        if (_paymentCompleted) {
          return true;
        }

        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Payment?'),
            content:
                const Text('Are you sure you want to cancel this payment?'),
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

        if (shouldPop == true) {
          // User confirmed cancellation - call failure callback with cancelled status
          AppLogger.warning('⚠️ Payment cancelled by user');
          widget.onFailure({
            'status': 'cancelled',
            'url': '',
            'params': {},
            'txnid': '',
            'amount': '',
            'mihpayid': '',
            'error_Message': 'Payment cancelled by user',
          });
          return true;
        }

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayU Payment'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // If payment already completed, just pop
              if (_paymentCompleted) {
                Navigator.pop(context);
                return;
              }

              // Show confirmation dialog
              final shouldCancel = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Payment?'),
                  content: const Text(
                      'Are you sure you want to cancel this payment?'),
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

              if (shouldCancel == true && mounted) {
                // User confirmed cancellation - call failure callback with cancelled status
                AppLogger.warning(
                    '⚠️ Payment cancelled by user via back button');
                widget.onFailure({
                  'status': 'cancelled',
                  'url': '',
                  'params': {},
                  'txnid': '',
                  'amount': '',
                  'mihpayid': '',
                  'error_Message': 'Payment cancelled by user',
                });
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: controller == null
              ? Container(
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
                          'Initializing Payment Gateway...',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // WebView
                    WebViewWidget(controller: controller!),

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
