import '../../models/cart_model.dart';

/// Cart State
abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartSuccess extends CartState {
  final Cart cart;

  CartSuccess(this.cart);
}

class CartEmpty extends CartState {}

class CartError extends CartState {
  final String message;

  CartError(this.message);
}
