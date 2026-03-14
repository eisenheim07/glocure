import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Service to handle internet connectivity checking for the entire app
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isBottomSheetShowing = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize connectivity monitoring
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      // If connectivity check fails, assume no connection
      _handleConnectivityChange([ConnectivityResult.none]);
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasConnection = await _hasInternetConnection(results);

    if (!hasConnection && _isConnected) {
      // Lost connection - start aggressive monitoring
      _isConnected = false;
      _showNoInternetBottomSheet();
      _startPeriodicConnectivityCheck();
    } else if (hasConnection && !_isConnected) {
      // Regained connection
      _isConnected = true;
      _hideNoInternetBottomSheet();
      _stopPeriodicConnectivityCheck();
    } else if (!hasConnection && !_isConnected) {
      // Still no connection - ensure periodic checking is running
      _startPeriodicConnectivityCheck();
    }
  }

  Timer? _periodicTimer;

  /// Start periodic connectivity checking for continuous monitoring
  void _startPeriodicConnectivityCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final results = await _connectivity.checkConnectivity();
        final hasConnection = await _hasInternetConnection(results);

        if (!hasConnection && _isConnected) {
          // Lost connection
          _isConnected = false;
          _showNoInternetBottomSheet();
        } else if (hasConnection && !_isConnected) {
          // Regained connection
          _isConnected = true;
          _hideNoInternetBottomSheet();
          // Stop periodic checking when connection is stable
          _stopPeriodicConnectivityCheck();
        }
      } catch (e) {
        // If check fails, assume no connection
        if (_isConnected) {
          _isConnected = false;
          _showNoInternetBottomSheet();
        }
      }
    });
  }

  /// Stop periodic connectivity checking
  void _stopPeriodicConnectivityCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Check if device has actual internet connection
  Future<bool> _hasInternetConnection(List<ConnectivityResult> results) async {
    // If no connectivity result, no internet
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    // If connected to wifi or mobile, verify actual internet access
    if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile)) {
      return await _verifyInternetAccess();
    }

    return false;
  }

  /// Verify actual internet access by pinging a reliable server
  Future<bool> _verifyInternetAccess() async {
    try {
      // Try multiple servers for better reliability
      final futures = [
        InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3)),
        InternetAddress.lookup('cloudflare.com').timeout(const Duration(seconds: 3)),
      ];

      final results = await Future.wait(futures, eagerError: false);

      // If any lookup succeeds, we have internet
      for (final result in results) {
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Show no internet bottom sheet
  void _showNoInternetBottomSheet() {
    final context = _navigatorKey?.currentContext;
    if (context == null || _isBottomSheetShowing) return;

    _isBottomSheetShowing = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: false,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // No Internet Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Try Again Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _retryConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide no internet bottom sheet
  void _hideNoInternetBottomSheet() {
    if (!_isBottomSheetShowing) return;

    _isBottomSheetShowing = false;
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      Navigator.of(context).pop();
    }
  }

  /// Retry connection check
  Future<void> _retryConnection() async {
    try {
      // Show loading state on button (optional enhancement)
      final results = await _connectivity.checkConnectivity();
      final hasConnection = await _hasInternetConnection(results);

      if (hasConnection) {
        _isConnected = true;
        _hideNoInternetBottomSheet();
      }
      // If still no connection, the periodic timer will continue checking
    } catch (e) {
      // If check fails, assume still no connection
      // The periodic timer will continue checking
    }
  }

  /// Check if currently connected (for external use)
  bool get isConnected => _isConnected;

  /// Manual connectivity check (for API calls)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _hasInternetConnection(results);
    } catch (e) {
      return false;
    }
  }

  /// Dispose connectivity subscription
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicTimer?.cancel();
  }
}
