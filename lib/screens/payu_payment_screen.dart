import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payu_service.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../config/api_config.dart';

/// PayU Payment Screen
/// WebView screen for PayU payment gateway
class PayUPaymentScreen extends StatefulWidget {
  final OrderModel order;
  final Customer customer;

  const PayUPaymentScreen({
    super.key,
    required this.order,
    required this.customer,
  });

  @override
  State<PayUPaymentScreen> createState() => _PayUPaymentScreenState();
}

class _PayUPaymentScreenState extends State<PayUPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _showingResult = false;
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    // Ensure status bar is visible
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _initializeWebView();
  }

  @override
  void dispose() {
    // Ensure status bar remains visible when leaving this screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    super.dispose();
  }

  void _initializeWebView() {
    // Prepare payment parameters
    final amount = widget.order.totalPrice?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
    final productInfo = 'Order #${widget.order.orderNumber} - ${widget.order.lineItems.length} items';
    final firstName = widget.customer.firstName ?? 'Customer';
    final lastName = widget.customer.lastName ?? '';
    
    // Ensure email is valid, use default if not provided
    String email = widget.customer.email ?? '';
    if (email.isEmpty || !email.contains('@')) {
      email = 'test@glocure.com';
    }
    
    // Ensure phone is valid, use default if not provided
    String phone = widget.customer.phone ?? widget.customer.defaultAddress?.phone ?? '';
    if (phone.isEmpty) {
      phone = '9999999999';
    }

    // Success and failure URLs (these will be intercepted)
    // Using simple, standard URLs that PayU test mode accepts
    const successUrl = 'https://apiplayground-response.herokuapp.com/';
    const failureUrl = 'https://apiplayground-response.herokuapp.com/';

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔧 PAYU PAYMENT INITIALIZATION');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Amount: $amount');
    debugPrint('Email: $email');
    debugPrint('Phone: $phone');
    debugPrint('First Name: $firstName');
    debugPrint('Last Name: $lastName');
    debugPrint('═══════════════════════════════════════════════════════');

    final params = PayUService().preparePaymentParams(
      orderId: widget.order.id ?? '',
      orderNumber: widget.order.orderNumber ?? '',
      amount: amount,
      productInfo: productInfo,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      successUrl: successUrl,
      failureUrl: failureUrl,
    );

    // Build HTML form
    final html = PayUService().buildPaymentForm(params);

    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('📄 Page started: $url');
            _handleNavigation(url);
            _updateCanGoBack();
          },
          onPageFinished: (url) {
            debugPrint('✅ Page finished: $url');
            setState(() => _isLoading = false);
            _updateCanGoBack();
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(html);
  }

  /// Update the canGoBack state
  Future<void> _updateCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
      });
    }
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    // If WebView can go back, navigate back in WebView
    if (_canGoBack) {
      debugPrint('⬅️ Going back in WebView history');
      await _controller.goBack();
      return false; // Don't pop the screen
    }
    
    // If can't go back, show confirmation dialog
    debugPrint('⚠️ No WebView history, showing cancel confirmation');
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (shouldPop == true) {
      _handlePaymentCancelled();
    }
    
    return false; // We handle the pop manually
  }

  void _handleNavigation(String url) {
    debugPrint('🔗 Navigation: $url');

    // Check for success URL patterns (case-insensitive)
    final lowerUrl = url.toLowerCase();
    
    // Check if URL contains success indicators
    if (lowerUrl.contains('success') && !lowerUrl.contains('failure')) {
      debugPrint('✅ Payment Success detected from URL');
      _handlePaymentSuccess();
      return;
    }
    
    // Check for failure URL patterns
    if (lowerUrl.contains('failure') || lowerUrl.contains('failed')) {
      debugPrint('❌ Payment Failure detected from URL');
      _handlePaymentFailure();
      return;
    }
    
    // Check for cancel patterns
    if (lowerUrl.contains('cancel')) {
      debugPrint('⚠️ Payment Cancelled detected from URL');
      _handlePaymentCancelled();
      return;
    }
    
    // Check for PayU test response page with status parameter
    if (lowerUrl.contains('testpg_response.php')) {
      debugPrint('📋 PayU test response page detected, checking for status...');
      
      // Try to extract status from URL parameters
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'];
      
      debugPrint('Status parameter: $status');
      
      // PayU status codes:
      // 000 = Success
      // 001 = Failure
      // 002 = Pending
      // 003 = Cancelled
      
      if (status == '000') {
        debugPrint('✅ Payment Success detected (status: $status)');
        _showPaymentResultOverlay('success');
      } else if (status == '001') {
        debugPrint('❌ Payment Failure detected (status: $status)');
        _showPaymentResultOverlay('failed');
      } else if (status == '003') {
        debugPrint('⚠️ Payment Cancelled detected (status: $status)');
        _showPaymentResultOverlay('cancelled');
      } else if (status == '002') {
        debugPrint('⏳ Payment Pending detected (status: $status)');
        _showPaymentResultOverlay('success');
      }
    }
  }

  void _showPaymentResultOverlay(String status) {
    if (_showingResult) return; // Prevent multiple overlays
    
    setState(() {
      _showingResult = true;
      _paymentStatus = status;
    });
    
    // Auto-redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showingResult) {
        debugPrint('🔄 Auto-redirecting to payment status screen');
        
        if (status == 'success') {
          _handlePaymentSuccess();
        } else if (status == 'failed') {
          _handlePaymentFailure();
        } else {
          _handlePaymentCancelled();
        }
      }
    });
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;
    
    // Ensure status bar is visible before popping
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    
    Navigator.pop(context, {
      'status': 'success',
      'orderId': widget.order.id,
      'orderNumber': widget.order.orderNumber,
    });
  }

  void _handlePaymentFailure() {
    if (!mounted) return;
    
    // Ensure status bar is visible before popping
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    
    Navigator.pop(context, {
      'status': 'failed',
      'orderId': widget.order.id,
      'orderNumber': widget.order.orderNumber,
    });
  }

  void _handlePaymentCancelled() {
    if (!mounted) return;
    
    // Ensure status bar is visible before popping
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    
    Navigator.pop(context, {
      'status': 'cancelled',
      'orderId': widget.order.id,
      'orderNumber': widget.order.orderNumber,
    });
  }

  Widget _buildPaymentResultOverlay() {
    final config = _getResultConfig(_paymentStatus!);
    
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: config['backgroundColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config['icon'],
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Status title
              Text(
                config['title'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Status message
              Text(
                config['message'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5C9A)),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Redirecting...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getResultConfig(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return {
          'icon': Icons.check_circle,
          'backgroundColor': const Color(0xFF4CAF50),
          'title': 'Payment Successful!',
          'message': 'Your payment has been processed successfully.',
        };
      case 'failed':
        return {
          'icon': Icons.error,
          'backgroundColor': Colors.red.shade400,
          'title': 'Payment Failed',
          'message': 'We couldn\'t process your payment. Please try again.',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel,
          'backgroundColor': Colors.orange.shade400,
          'title': 'Payment Cancelled',
          'message': 'You have cancelled the payment.',
        };
      default:
        return {
          'icon': Icons.info,
          'backgroundColor': Colors.grey.shade400,
          'title': 'Payment Status',
          'message': 'Processing your payment...',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: const Color(0xFFFF5C9A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onWillPop,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                // Show confirmation dialog for close button
                final shouldCancel = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Payment?'),
                    content: const Text('Are you sure you want to cancel this payment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );
                
                if (shouldCancel == true) {
                  _handlePaymentCancelled();
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
          Column(
            children: [
              // Test mode banner
              if (!ApiConfig.payuIsProduction)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'TEST MODE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use test card: 5123456789012346, CVV: 123',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '⚠️ UPI may show validation errors in test mode',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // WebView
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5C9A)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment gateway...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Payment result overlay
          if (_showingResult && _paymentStatus != null)
            _buildPaymentResultOverlay(),
          ],
        ),
      ),
    );
  }
}
