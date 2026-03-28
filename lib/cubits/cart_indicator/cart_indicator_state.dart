/// Cart Indicator State
class CartIndicatorState {
  final bool hasItems;

  const CartIndicatorState({required this.hasItems});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartIndicatorState && other.hasItems == hasItems;
  }

  @override
  int get hashCode => hasItems.hashCode;

  @override
  String toString() => 'CartIndicatorState(hasItems: $hasItems)';
}

/// Initial state for cart indicator
class CartIndicatorInitial extends CartIndicatorState {
  const CartIndicatorInitial() : super(hasItems: false);
}