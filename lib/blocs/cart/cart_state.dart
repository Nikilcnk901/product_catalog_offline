import '../../models/cart_item.dart';

enum CartStatus { initial, loading, ready, failure }

class CartState {
  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final CartStatus status;
  final List<CartItem> items;
  final String? errorMessage;

  int quantityOf(int productId) {
    for (final item in items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  int get totalQuantity {
    var total = 0;
    for (final item in items) {
      total += item.quantity;
    }
    return total;
  }

  double get totalPrice {
    var total = 0.0;
    for (final item in items) {
      total += item.lineTotal;
    }
    return total;
  }

  CartState copyWith({
    CartStatus? status,
    List<CartItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
