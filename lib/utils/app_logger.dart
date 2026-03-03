import 'package:flutter/foundation.dart';

/// Centralized Application Logger
/// This utility provides a single point for all logging throughout the app
/// Automatically disabled in release builds for performance and security
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Enable/disable logging globally
  /// Set to false for release builds to disable all logs
  static const bool _isLoggingEnabled = kDebugMode;

  /// Log levels for different types of messages
  static const String _apiTag = '🔵 API';
  static const String _judgemeTag = '🟡 JUDGEME';
  static const String _connectivityTag = '🟢 CONNECTIVITY';
  static const String _errorTag = '🔴 ERROR';
  static const String _warningTag = '🟠 WARNING';
  static const String _infoTag = '⚪ INFO';
  static const String _successTag = '✅ SUCCESS';

  /// Generic log method - all logging goes through this
  static void _log(String tag, String message) {
    if (_isLoggingEnabled) {
      debugPrint('$tag: $message');
    }
  }

  /// API related logs (Shopify GraphQL, REST APIs)
  static void api(String message) {
    _log(_apiTag, message);
  }

  /// Judge.me API specific logs
  static void judgeme(String message) {
    _log(_judgemeTag, message);
  }

  /// Connectivity related logs
  static void connectivity(String message) {
    _log(_connectivityTag, message);
  }

  /// Error logs
  static void error(String message) {
    _log(_errorTag, message);
  }

  /// Warning logs
  static void warning(String message) {
    _log(_warningTag, message);
  }

  /// General information logs
  static void info(String message) {
    _log(_infoTag, message);
  }

  /// Success logs
  static void success(String message) {
    _log(_successTag, message);
  }

  /// Formatted API request log
  static void apiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? variables,
  }) {
    if (!_isLoggingEnabled) return;

    api('═══════════════════════════════════════════════════════════');
    api('📤 $method REQUEST START');
    api('═══════════════════════════════════════════════════════════');
    api('URL: $url');
    
    if (headers != null && headers.isNotEmpty) {
      api('Headers: $headers');
    }
    
    if (body != null && body.isNotEmpty) {
      api('Body: $body');
    }
    
    if (variables != null && variables.isNotEmpty) {
      api('Variables: $variables');
    }
    
    api('═══════════════════════════════════════════════════════════');
  }

  /// Formatted API response log
  static void apiResponse({
    required int statusCode,
    required String method,
    Map<String, dynamic>? responseData,
    String? error,
  }) {
    if (!_isLoggingEnabled) return;

    api('═══════════════════════════════════════════════════════════');
    api('📥 $method RESPONSE RECEIVED');
    api('═══════════════════════════════════════════════════════════');
    api('Status Code: $statusCode');
    
    if (error != null) {
      api('❌ Error: $error');
    } else if (responseData != null) {
      api('📥 Response Data Length: ${responseData.toString().length}');
      // Only log full response in debug for performance
      if (kDebugMode && responseData.toString().length < 5000) {
        api('Response: $responseData');
      }
    }
    
    if (statusCode >= 200 && statusCode < 300 && error == null) {
      api('✅ REQUEST COMPLETED SUCCESSFULLY');
    } else {
      api('❌ REQUEST FAILED');
    }
    
    api('═══════════════════════════════════════════════════════════');
  }

  /// Judge.me specific request log
  static void judgemeRequest({
    required String endpoint,
    required String url,
    Map<String, String>? params,
  }) {
    if (!_isLoggingEnabled) return;

    judgeme('═══════════════════════════════════════════════════════════');
    judgeme('🚀 JUDGEME API REQUEST: $endpoint');
    judgeme('═══════════════════════════════════════════════════════════');
    judgeme('URL: $url');
    
    if (params != null && params.isNotEmpty) {
      judgeme('Parameters: $params');
    }
    
    judgeme('═══════════════════════════════════════════════════════════');
  }

  /// Judge.me specific response log
  static void judgemeResponse({
    required String endpoint,
    required int statusCode,
    Map<String, dynamic>? responseData,
    String? error,
    int? itemCount,
  }) {
    if (!_isLoggingEnabled) return;

    judgeme('═══════════════════════════════════════════════════════════');
    judgeme('📥 JUDGEME RESPONSE: $endpoint');
    judgeme('═══════════════════════════════════════════════════════════');
    judgeme('Status Code: $statusCode');
    
    if (error != null) {
      judgeme('❌ Error: $error');
    } else {
      if (itemCount != null) {
        judgeme('✅ Successfully fetched $itemCount items');
      }
      if (responseData != null) {
        judgeme('📥 Response Data Length: ${responseData.toString().length}');
      }
    }
    
    judgeme('═══════════════════════════════════════════════════════════');
  }

  /// Cubit state change log
  static void cubitState(String cubitName, String stateName, [String? details]) {
    if (details != null) {
      info('🔄 $cubitName -> $stateName: $details');
    } else {
      info('🔄 $cubitName -> $stateName');
    }
  }

  /// Navigation log
  static void navigation(String from, String to) {
    info('🧭 Navigation: $from -> $to');
  }

  /// Performance log
  static void performance(String operation, Duration duration) {
    info('⏱️ Performance: $operation took ${duration.inMilliseconds}ms');
  }
}