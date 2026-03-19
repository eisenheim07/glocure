import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../utils/auth_storage.dart';
import '../../models/cart_model.dart';
import 'cart_state.dart';

/// Cart Cubit
/// Manages cart state and operations
class CartCubit extends Cubit<CartState> {
  final ApiService _apiService = ApiService();
  
  // Track which line is currently being updated
  String? _updatingLineId;
  
  // Track if any operation is in progress (for disabling all buttons)
  bool _isAnyOperationInProgress = false;

  CartCubit() : super(CartInitial());

  /// Check if a specific line is being updated
  bool isLineUpdating(String lineId) => _updatingLineId == lineId;
  
  /// Check if any operation is in progress
  bool get isAnyOperationInProgress => _isAnyOperationInProgress;

  /// Fetch cart details
  Future<void> fetchCart() async {
    try {
      emit(CartLoading());

      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();

      if (cartId == null || cartId.isEmpty) {
        emit(CartEmpty());
        return;
      }

      // Fetch cart data from API
      final cartData = await _apiService.getCart(cartId);
      final cart = Cart.fromJson(cartData);

      // Check if cart has items
      if (cart.lines.isEmpty) {
        emit(CartEmpty());
      } else {
        emit(CartSuccess(cart));
      }
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Refresh cart
  Future<void> refreshCart() async {
    await fetchCart();
  }

  /// Update item quantity with optimistic update
  /// [lineId] - The cart line ID to update
  /// [newQuantity] - The new quantity (must be >= 1)
  Future<void> updateQuantity(String lineId, int newQuantity) async {
    final currentState = state;
    if (currentState is! CartSuccess) return;

    // Validate quantity
    if (newQuantity < 1) return;
    
    // Prevent multiple operations
    if (_isAnyOperationInProgress) return;

    try {
      // Mark operation as in progress
      _isAnyOperationInProgress = true;
      _updatingLineId = lineId;
      
      // Optimistic update: Update local state immediately
      final updatedLines = currentState.cart.lines.map((line) {
        if (line.id == lineId) {
          return CartLine(
            id: line.id,
            quantity: newQuantity,
            attributes: line.attributes,
            merchandise: line.merchandise,
          );
        }
        return line;
      }).toList();

      final updatedCart = Cart(
        id: currentState.cart.id,
        lines: updatedLines,
        cost: currentState.cart.cost,
        discountCodes: currentState.cart.discountCodes,
      );

      // Emit updated state immediately (optimistic)
      emit(CartSuccess(updatedCart));

      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        throw Exception('Cart not found');
      }

      // Call API to update quantity in background
      await _apiService.cartLinesUpdate(
        cartId: cartId,
        lines: [
          {'id': lineId, 'quantity': newQuantity}
        ],
      );

      // Fetch fresh cart data to sync with server
      final cartData = await _apiService.getCart(cartId);
      final freshCart = Cart.fromJson(cartData);

      // Update with server data
      _updatingLineId = null;
      _isAnyOperationInProgress = false;
      emit(CartSuccess(freshCart));
    } catch (e) {
      // On error, revert to previous state by fetching from server
      _updatingLineId = null;
      _isAnyOperationInProgress = false;
      await fetchCart();
    }
  }

  /// Remove item from cart - waits for API success before updating UI
  /// [lineId] - The cart line ID to remove
  Future<void> removeItem(String lineId) async {
    final currentState = state;
    if (currentState is! CartSuccess) return;
    
    // Prevent multiple operations
    if (_isAnyOperationInProgress) return;

    try {
      // Mark operation as in progress
      _isAnyOperationInProgress = true;
      _updatingLineId = lineId;
      
      // Re-emit current state to trigger UI update (for disabling buttons)
      emit(CartSuccess(currentState.cart));

      // Get cart ID from preferences
      final cartId = await AuthStorage.getCartId();
      if (cartId == null || cartId.isEmpty) {
        throw Exception('Cart not found');
      }

      // Call API to remove line - WAIT for success
      await _apiService.cartLinesRemove(
        cartId: cartId,
        lineIds: [lineId],
      );

      // Fetch fresh cart data to sync with server
      final cartData = await _apiService.getCart(cartId);
      final freshCart = Cart.fromJson(cartData);

      // Update with server data after successful removal
      _updatingLineId = null;
      _isAnyOperationInProgress = false;
      if (freshCart.lines.isEmpty) {
        emit(CartEmpty());
      } else {
        emit(CartSuccess(freshCart));
      }
    } catch (e) {
      // On error, revert to previous state by fetching from server
      _updatingLineId = null;
      _isAnyOperationInProgress = false;
      await fetchCart();
      rethrow; // Re-throw to let UI handle error message
    }
  }
}
