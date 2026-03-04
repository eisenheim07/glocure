import '../../models/shopify_order_model.dart';

/// Orders State
abstract class OrdersState {}

/// Initial state
class OrdersInitial extends OrdersState {}

/// Loading state
class OrdersLoading extends OrdersState {}

/// Loaded state with orders and current tab
class OrdersLoaded extends OrdersState {
  final List<ShopifyOrder> orders;
  final String currentTab;

  OrdersLoaded(this.orders, this.currentTab);
}

/// Error state
class OrdersError extends OrdersState {
  final String message;

  OrdersError(this.message);
}