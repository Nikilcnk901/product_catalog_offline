import 'package:hive/hive.dart';

import '../../models/cart_item.dart';
import 'cart_item_adapter.dart';

class CartStorage {
  static const _boxName = 'cart';
  static const _itemsKey = 'items';

  final CartItemAdapter _adapter = CartItemAdapter();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(_adapter.typeId)) {
      Hive.registerAdapter(_adapter);
    }
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<dynamic>(_boxName);
    }
  }

  List<CartItem> readItems() {
    final stored = _box.get(_itemsKey);
    if (stored == null) {
      return const [];
    }
    if (stored is! List) {
      throw const FormatException('Stored cart has an unexpected format.');
    }

    final items = <CartItem>[];
    for (final item in stored) {
      if (item is! CartItem) {
        throw const FormatException('Stored cart has an unexpected format.');
      }
      items.add(item);
    }
    return items;
  }

  Future<void> saveItems(List<CartItem> items) {
    return _box.put(_itemsKey, items);
  }

  Future<void> removeItem(int productId) {
    final remaining = [
      for (final item in readItems())
        if (item.productId != productId) item,
    ];
    return saveItems(remaining);
  }

  Future<void> clear() {
    return _box.delete(_itemsKey);
  }

  Box<dynamic> get _box {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError('Cart storage is not open.');
    }
    return Hive.box<dynamic>(_boxName);
  }
}
