import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/shopify_order_model.dart';
import '../../utils/auth_storage.dart';
import '../../utils/app_logger.dart';
import 'orders_state.dart';

/// Orders Cubit
/// Manages order listing with tabs and caching
class OrdersCubit extends Cubit<OrdersState> {
  final ApiService _apiService;
  
  // Cache for orders data
  List<ShopifyOrder> _allOrders = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  OrdersCubit({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(OrdersInitial());

  /// Initialize orders - fetch all orders once and cache them
  Future<void> initializeOrders() async {
    AppLogger.info('OrdersCubit: Initializing orders...');
    
    // Check if cache is still valid
    if (_isCacheValid()) {
      AppLogger.info('OrdersCubit: Using cached data');
      showAllTab();
      return;
    }

    emit(OrdersLoading());

    try {
      final customerId = await AuthStorage.getCustomerId();
      AppLogger.info('OrdersCubit: Retrieved customer ID from storage: $customerId');
      
      if (customerId == null || customerId.isEmpty) {
        AppLogger.error('OrdersCubit: No customer ID found in storage');
        
        // Try to get customer ID from current session
        final token = await AuthStorage.getToken();
        if (token != null) {
          AppLogger.info('OrdersCubit: Found token, trying to fetch customer...');
          final customer = await _apiService.getCustomer(token);
          if (customer != null) {
            AppLogger.info('OrdersCubit: Customer fetched, retrying orders...');
            await initializeOrders(); // Retry after customer ID is saved
            return;
          }
        }
        
        emit(OrdersError('Customer not found. Please login again.'));
        return;
      }

      // Test with known customer ID if current one doesn't work
      String testCustomerId = customerId;
      if (customerId != '8596371243186') {
        AppLogger.warning('OrdersCubit: Customer ID ($customerId) differs from expected (8596371243186)');
        AppLogger.info('OrdersCubit: Trying with both IDs...');
      }

      AppLogger.info('OrdersCubit: Fetching orders for customer: $testCustomerId');

      // Fetch all orders from Shopify Admin API
      final orders = await _apiService.getCustomerOrders(testCustomerId);
      
      _allOrders = orders;
      _lastFetchTime = DateTime.now();
      
      AppLogger.info('OrdersCubit: Fetched ${orders.length} orders successfully');
      
      // Show all tab by default
      showAllTab();
      
    } catch (e) {
      AppLogger.error('OrdersCubit: Error fetching orders: $e');
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastFetchTime == null || _allOrders.isEmpty) {
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);
    return difference < _cacheExpiry;
  }

  /// Show all orders tab
  void showAllTab() {
    AppLogger.info('OrdersCubit: Showing all orders (${_allOrders.length} orders)');
    emit(OrdersLoaded(_allOrders, 'All'));
  }

  /// Show pending orders tab
  void showPendingTab() {
    final pendingOrders = _allOrders.where((order) => 
        order.financialStatus.toLowerCase() == 'pending' ||
        order.fulfillmentStatus.toLowerCase() == 'unfulfilled'
    ).toList();
    
    AppLogger.info('OrdersCubit: Showing pending orders (${pendingOrders.length} orders)');
    emit(OrdersLoaded(pendingOrders, 'Pending'));
  }

  /// Show closed orders tab
  void showClosedTab() {
    final closedOrders = _allOrders.where((order) => 
        order.financialStatus.toLowerCase() == 'paid' &&
        order.fulfillmentStatus.toLowerCase() == 'fulfilled'
    ).toList();
    
    AppLogger.info('OrdersCubit: Showing closed orders (${closedOrders.length} orders)');
    emit(OrdersLoaded(closedOrders, 'Closed'));
  }

  /// Show cancelled orders tab
  void showCancelledTab() {
    final cancelledOrders = _allOrders.where((order) => 
        order.financialStatus.toLowerCase() == 'refunded' ||
        order.fulfillmentStatus.toLowerCase() == 'cancelled'
    ).toList();
    
    AppLogger.info('OrdersCubit: Showing cancelled orders (${cancelledOrders.length} orders)');
    emit(OrdersLoaded(cancelledOrders, 'Cancelled'));
  }

  /// Force refresh orders (for pull-to-refresh)
  Future<void> refreshOrders() async {
    AppLogger.info('OrdersCubit: Force refreshing orders...');
    
    // Clear cache
    _allOrders.clear();
    _lastFetchTime = null;
    
    // Fetch fresh data
    await initializeOrders();
  }

  /// Reset to initial state
  void reset() {
    AppLogger.info('OrdersCubit: Resetting to initial state');
    _allOrders.clear();
    _lastFetchTime = null;
    emit(OrdersInitial());
  }
}