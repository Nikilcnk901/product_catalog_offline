import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/cart_storage.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._storage) : super(const CartState());

  final CartStorage _storage;
  Future<void> _writes = Future<void>.value();

  Future<void> loadCart() {
    return _run(_readCart);
  }

  Future<void> addProduct(Product product) {
    return _run(() => _addProduct(product));
  }

  Future<void> increaseQuantity(int productId) {
    return _run(() => _changeQuantity(productId, 1));
  }

  Future<void> decreaseQuantity(int productId) {
    return _run(() => _changeQuantity(productId, -1));
  }

  Future<void> removeProduct(int productId) {
    return _run(() => _removeProduct(productId));
  }

  Future<void> _readCart() async {
    emit(state.copyWith(status: CartStatus.loading, clearError: true));

    try {
      final items = _storage.readItems();
      if (isClosed) return;
      emit(state.copyWith(status: CartStatus.ready, items: items));
    } catch (_) {
      _emitFailure('Could not load the cart.');
    }
  }

  Future<void> _addProduct(Product product) async {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.productId == product.id);

    if (index == -1) {
      items.add(
        CartItem(
          productId: product.id,
          title: product.title,
          price: product.price,
          thumbnail: product.thumbnail,
          quantity: 1,
        ),
      );
    } else {
      final current = items[index];
      items[index] = current.copyWith(quantity: current.quantity + 1);
    }

    await _persist(items);
  }

  Future<void> _removeProduct(int productId) async {
    try {
      await _storage.removeItem(productId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CartStatus.ready,
          items: _storage.readItems(),
          clearError: true,
        ),
      );
    } catch (_) {
      _emitFailure('Could not update the cart.');
    }
  }

  Future<void> _changeQuantity(int productId, int delta) async {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) return;

    final items = [...state.items];
    final current = items[index];
    final nextQuantity = current.quantity + delta;

    if (nextQuantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = current.copyWith(quantity: nextQuantity);
    }

    await _persist(items);
  }

  Future<void> _persist(List<CartItem> items) async {
    try {
      await _storage.saveItems(items);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CartStatus.ready,
          items: items,
          clearError: true,
        ),
      );
    } catch (_) {
      _emitFailure('Could not update the cart.');
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: CartStatus.failure, errorMessage: message));
  }

  Future<void> _run(Future<void> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
