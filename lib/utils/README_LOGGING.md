# Centralized Logging System

The Glocure app uses a centralized logging system that provides consistent, categorized logging throughout the application while automatically disabling logs in release builds for performance and security.

## Features

- **Automatic Release Disable**: All logs are automatically disabled in release builds
- **Categorized Logging**: Different log types with color-coded emojis
- **Structured API Logging**: Formatted request/response logging for APIs
- **Performance Optimized**: Zero overhead in release builds
- **Single Point of Control**: All logging controlled from one utility class

## Usage

### Import the Logger
```dart
import '../utils/app_logger.dart';
```

### Basic Logging Methods

```dart
// API related logs (Shopify GraphQL, REST APIs)
AppLogger.api('Fetching product data...');

// Judge.me API specific logs
AppLogger.judgeme('Getting product reviews...');

// Connectivity related logs
AppLogger.connectivity('Internet connection restored');

// Error logs
AppLogger.error('Failed to load data: $error');

// Warning logs
AppLogger.warning('Token will expire soon');

// General information logs
AppLogger.info('User navigated to product screen');

// Success logs
AppLogger.success('Data loaded successfully');
```

### Structured API Logging

#### API Request Logging
```dart
AppLogger.apiRequest(
  method: 'GraphQL',
  url: 'https://api.example.com/graphql',
  body: {'query': query},
  variables: {'handle': 'product-handle'},
  headers: {'Authorization': 'Bearer token'},
);
```

#### API Response Logging
```dart
AppLogger.apiResponse(
  statusCode: 200,
  method: 'GraphQL',
  responseData: responseData,
  // OR for errors:
  error: 'HTTP Error: 404 - Not Found',
);
```

#### Judge.me Specific Logging
```dart
// Request logging
AppLogger.judgemeRequest(
  endpoint: 'Get Product Reviews',
  url: 'https://judge.me/api/v1/reviews',
  params: {'product_id': '123', 'page': '1'},
);

// Response logging
AppLogger.judgemeResponse(
  endpoint: 'Get Product Reviews',
  statusCode: 200,
  responseData: responseData,
  itemCount: 15, // Number of items fetched
);
```

### Specialized Logging

#### Cubit State Changes
```dart
AppLogger.cubitState('ProductDetailsCubit', 'ProductDetailsLoaded', 'Product: iPhone 14');
```

#### Navigation Tracking
```dart
AppLogger.navigation('HomeScreen', 'ProductDetailsScreen');
```

#### Performance Monitoring
```dart
final stopwatch = Stopwatch()..start();
// ... perform operation
AppLogger.performance('API Call', stopwatch.elapsed);
```

## Log Categories and Emojis

| Category | Emoji | Usage |
|----------|-------|-------|
| API | 🔵 | Shopify GraphQL/REST API calls |
| Judge.me | 🟡 | Judge.me review API calls |
| Connectivity | 🟢 | Internet connectivity status |
| Error | 🔴 | Error conditions and exceptions |
| Warning | 🟠 | Warning conditions |
| Info | ⚪ | General information |
| Success | ✅ | Successful operations |

## Implementation Examples

### Service Layer (API Service)
```dart
class ApiService {
  Future<ProductResponse> getProduct(String id) async {
    try {
      AppLogger.apiRequest(
        method: 'GraphQL',
        url: ApiConfig.baseUrl,
        body: {'query': query},
        variables: {'id': id},
      );

      final response = await http.post(/* ... */);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'GraphQL',
          responseData: data,
        );
        
        return ProductResponse.fromJson(data);
      } else {
        AppLogger.apiResponse(
          statusCode: response.statusCode,
          method: 'GraphQL',
          error: 'HTTP Error: ${response.statusCode}',
        );
        throw Exception('Failed to fetch product');
      }
    } catch (e) {
      AppLogger.error('API request failed: $e');
      rethrow;
    }
  }
}
```

### Cubit Layer
```dart
class ProductCubit extends Cubit<ProductState> {
  void loadProduct(String id) async {
    try {
      AppLogger.cubitState('ProductCubit', 'Loading', 'Product ID: $id');
      emit(ProductLoading());
      
      final product = await apiService.getProduct(id);
      
      AppLogger.cubitState('ProductCubit', 'Loaded', 'Product: ${product.name}');
      emit(ProductLoaded(product));
    } catch (e) {
      AppLogger.error('Failed to load product: $e');
      emit(ProductError(e.toString()));
    }
  }
}
```

### Screen Layer
```dart
class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppLogger.navigation('HomeScreen', 'ProductScreen');
    
    return Scaffold(
      // ... UI implementation
    );
  }
}
```

## Configuration

### Debug vs Release Behavior

The logging system automatically detects the build mode:

```dart
// In AppLogger class
static const bool _isLoggingEnabled = kDebugMode;
```

- **Debug Mode**: All logs are printed with full formatting
- **Release Mode**: All logs are completely disabled (zero overhead)

### Performance Considerations

- **Zero Release Overhead**: No logging code executes in release builds
- **Efficient Debug Logging**: Minimal performance impact in debug mode
- **Large Response Handling**: Responses over 5KB are truncated in logs
- **Conditional Formatting**: Complex formatting only occurs when logging is enabled

## Migration from Direct Logging

### Before (Direct Logging)
```dart
debugPrint('🔵 API_LOG: Fetching products...');
print('Response: $responseData');
_log('✅ Success: ${products.length} products loaded');
```

### After (Centralized Logging)
```dart
AppLogger.api('Fetching products...');
AppLogger.apiResponse(
  statusCode: 200,
  method: 'GraphQL',
  responseData: responseData,
);
AppLogger.success('${products.length} products loaded');
```

## Benefits

### Development Benefits
- **Consistent Formatting**: All logs follow the same format
- **Easy Debugging**: Color-coded categories make logs easy to scan
- **Structured Data**: API logs include all relevant request/response data
- **Performance Tracking**: Built-in performance monitoring capabilities

### Production Benefits
- **Zero Overhead**: No logging code executes in release builds
- **Security**: No sensitive data logged in production
- **Performance**: No string formatting or I/O operations in release
- **Clean Builds**: No debug output in production logs

### Maintenance Benefits
- **Single Point of Control**: All logging controlled from one class
- **Easy Updates**: Change logging behavior globally from one place
- **Consistent Standards**: Enforces consistent logging practices
- **Future Extensibility**: Easy to add new log categories or features

## Best Practices

1. **Use Appropriate Categories**: Choose the right log method for the context
2. **Include Context**: Provide meaningful messages with relevant data
3. **Handle Errors**: Always log errors with sufficient context
4. **Performance Logging**: Use performance logging for critical operations
5. **Avoid Sensitive Data**: Never log passwords, tokens, or personal information
6. **Structured Logging**: Use the structured API logging methods for requests/responses

The centralized logging system ensures consistent, maintainable, and performant logging throughout the Glocure application while providing excellent debugging capabilities during development.