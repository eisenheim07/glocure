import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/shopify_order_model.dart';
import '../../utils/auth_storage.dart';
import '../../utils/app_logger.dart';
import 'orders_state.dart';

/// Orders Cubit
/// Manages order listing with separate API calls for each tab
class OrdersCubit extends Cubit<OrdersState> {
  final ApiService _apiService;
  
  // Track current tab
  String _currentTab = 'All';

  OrdersCubit({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(OrdersInitial());

  /// Initialize orders - don't fetch, just set initial state
  Future<void> initializeOrders() async {
    AppLogger.info('OrdersCubit: Initializing orders (no API call)');
    // Don't fetch anything, just stay in initial state
    // API will be called when user actually navigates to Orders tab
  }

  /// Check customer ID and emit appropriate state if not found
  Future<bool> _checkCustomerId() async {
    final customerId = await _getCustomerId();
    
    AppLogger.info('OrdersCubit: _checkCustomerId - customerId=$customerId');
    
    if (customerId == null || customerId.isEmpty) {
      AppLogger.info('OrdersCubit: No customer ID found, showing no customer state');
      emit(OrdersNoCustomer());
      return false;
    }
    
    AppLogger.info('OrdersCubit: Customer ID exists, proceeding with API call');
    return true;
  }

  /// Get customer ID from storage (already saved in cart screen)
  Future<String?> _getCustomerId() async {
    final customerId = await AuthStorage.getCustomerId();
    AppLogger.info('OrdersCubit: Retrieved customer ID from storage: $customerId');
    return customerId;
  }

  /// Fetch orders for a specific status
  Future<List<ShopifyOrder>> _fetchOrdersForStatus(String status) async {
    final customerId = await _getCustomerId();
    
    if (customerId == null || customerId.isEmpty) {
      throw Exception('Customer not found. Please login again.');
    }

    AppLogger.info('OrdersCubit: Fetching orders for customer: $customerId with status: $status');

    final orders = await _apiService.getCustomerOrdersByStatus(customerId, status);
    
    AppLogger.info('OrdersCubit: Fetched ${orders.length} orders for status: $status');
    return orders;
  }

  /// Show all orders tab (status = any)
  Future<void> showAllTab() async {
    AppLogger.info('OrdersCubit: Showing all orders tab');
    _currentTab = 'All';
    
    // Immediately emit loading state to clear old data
    emit(OrdersLoading());
    
    // Check customer ID
    final hasCustomerId = await _checkCustomerId();
    
    if (!hasCustomerId) {
      return; // No customer ID, OrdersNoCustomer state already emitted
    }

    try {
      final orders = await _fetchOrdersForStatus('any');
      emit(OrdersLoaded(orders, 'All'));
    } catch (e) {
      AppLogger.error('OrdersCubit: Error fetching all orders: $e');
      emit(OrdersError('Failed to load orders: ${e.toString()}'));
    }
  }

  /// Show pending orders tab (status = open)
  Future<void> showPendingTab() async {
    AppLogger.info('OrdersCubit: Showing PENDING orders tab with status=open');
    _currentTab = 'Pending';
    
    // Immediately emit loading state to clear old data
    emit(OrdersLoading());
    
    // Check customer ID
    if (!await _checkCustomerId()) {
      return; // No customer ID, state already emitted
    }

    try {
      AppLogger.info('OrdersCubit: Calling _fetchOrdersForStatus with status=open');
      final orders = await _fetchOrdersForStatus('open'); // Use 'open' for pending orders
      emit(OrdersLoaded(orders, 'Pending'));
    } catch (e) {
      AppLogger.error('OrdersCubit: Error fetching pending orders: $e');
      emit(OrdersError('Failed to load pending orders: ${e.toString()}'));
    }
  }

  /// Show closed orders tab (status = closed)
  Future<void> showClosedTab() async {
    AppLogger.info('OrdersCubit: Showing CLOSED orders tab with status=closed');
    _currentTab = 'Closed';
    
    // Immediately emit loading state to clear old data
    emit(OrdersLoading());
    
    // Check customer ID
    if (!await _checkCustomerId()) {
      return; // No customer ID, state already emitted
    }

    try {
      AppLogger.info('OrdersCubit: Calling _fetchOrdersForStatus with status=closed');
      final orders = await _fetchOrdersForStatus('closed'); // Use 'closed' for closed orders
      emit(OrdersLoaded(orders, 'Closed'));
    } catch (e) {
      AppLogger.error('OrdersCubit: Error fetching closed orders: $e');
      emit(OrdersError('Failed to load closed orders: ${e.toString()}'));
    }
  }

  /// Show cancelled orders tab (status = cancelled)
  Future<void> showCancelledTab() async {
    AppLogger.info('OrdersCubit: Showing CANCELLED orders tab with status=cancelled');
    _currentTab = 'Cancelled';
    
    // Immediately emit loading state to clear old data
    emit(OrdersLoading());
    
    // Check customer ID
    if (!await _checkCustomerId()) {
      return; // No customer ID, state already emitted
    }

    try {
      AppLogger.info('OrdersCubit: Calling _fetchOrdersForStatus with status=cancelled');
      final orders = await _fetchOrdersForStatus('cancelled'); // Use 'cancelled' for cancelled orders
      emit(OrdersLoaded(orders, 'Cancelled'));
    } catch (e) {
      AppLogger.error('OrdersCubit: Error fetching cancelled orders: $e');
      emit(OrdersError('Failed to load cancelled orders: ${e.toString()}'));
    }
  }

  /// Force refresh orders for current tab (for pull-to-refresh)
  Future<void> refreshOrders() async {
    AppLogger.info('OrdersCubit: Force refreshing orders for current tab: $_currentTab');
    
    // Re-fetch current tab based on which tab is active
    switch (_currentTab) {
      case 'Pending':
        await showPendingTab();
        break;
      case 'Closed':
        await showClosedTab();
        break;
      case 'Cancelled':
        await showCancelledTab();
        break;
      case 'All':
      default:
        await showAllTab();
        break;
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    AppLogger.info('OrdersCubit: Deleting order: $orderId');
    
    try {
      // Call API service to delete order
      final success = await _apiService.deleteOrder(orderId);
      
      if (success) {
        AppLogger.success('OrdersCubit: Order deleted successfully');
        
        // Refresh current tab to update the list
        await refreshOrders();
      } else {
        throw Exception('Failed to delete order');
      }
    } catch (e) {
      AppLogger.error('OrdersCubit: Error deleting order: $e');
      emit(OrdersError('Failed to delete order: ${e.toString()}'));
      
      // Refresh to restore previous state
      await refreshOrders();
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    AppLogger.info('OrdersCubit: Cancelling order: $orderId');
    
    try {
      // Call API service to cancel order
      final success = await _apiService.cancelOrder(orderId);
      
      if (success) {
        AppLogger.success('OrdersCubit: Order cancelled successfully');
        
        // Refresh current tab to update the list
        await refreshOrders();
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      AppLogger.error('OrdersCubit: Error cancelling order: $e');
      emit(OrdersError('Failed to cancel order: ${e.toString()}'));
      
      // Refresh to restore previous state
      await refreshOrders();
    }
  }

  /// Reset to initial state
  void reset() {
    AppLogger.info('OrdersCubit: Resetting to initial state');
    emit(OrdersInitial());
  }
}
