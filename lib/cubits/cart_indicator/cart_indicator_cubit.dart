import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/auth_storage.dart';
import '../../utils/app_logger.dart';
import 'cart_indicator_state.dart';

/// Cart Indicator Cubit
/// Manages the cart indicator dot visibility state
class CartIndicatorCubit extends Cubit<CartIndicatorState> {
  CartIndicatorCubit() : super(CartIndicatorInitial());

  /// Initialize cart indicator state from storage
  Future<void> initializeCartIndicator() async {
    try {
      final hasItems = await AuthStorage.getCartHasItems();
      emit(CartIndicatorState(hasItems: hasItems));
      AppLogger.info("Cart indicator initialized: hasItems=$hasItems");
    } catch (e) {
      AppLogger.error("Error initializing cart indicator: $e");
      emit(const CartIndicatorState(hasItems: false));
    }
  }

  /// Set cart has items flag (called when adding items to cart)
  Future<void> setCartHasItems(bool hasItems) async {
    try {
      await AuthStorage.setCartHasItems(hasItems);
      emit(CartIndicatorState(hasItems: hasItems));
      AppLogger.info("Cart indicator updated: hasItems=$hasItems");
    } catch (e) {
      AppLogger.error("Error updating cart indicator: $e");
    }
  }

  /// Clear cart indicator (called when cart is empty or new cart is created)
  Future<void> clearCartIndicator() async {
    try {
      await AuthStorage.setCartHasItems(false);
      emit(const CartIndicatorState(hasItems: false));
      AppLogger.info("Cart indicator cleared");
    } catch (e) {
      AppLogger.error("Error clearing cart indicator: $e");
    }
  }

  /// Get current cart indicator state
  bool get hasItems {
    final currentState = state;
    return currentState is CartIndicatorState ? currentState.hasItems : false;
  }
}