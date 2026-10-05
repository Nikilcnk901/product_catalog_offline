import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:product_catalog_offline_cart/blocs/cart/cart_cubit.dart';
import 'package:product_catalog_offline_cart/blocs/cart/cart_state.dart';
import 'package:product_catalog_offline_cart/data/local/cart_storage.dart';
import 'package:product_catalog_offline_cart/models/product.dart';

void main() {
  late Directory directory;
  late CartStorage storage;

  const product = Product(
    id: 7,
    title: 'Notebook',
    description: 'Ruled notebook',
    price: 12.5,
    rating: 4.5,
    category: 'stationery',
    brand: 'Paper Co',
    stock: 20,
    thumbnail: 'https://example.com/notebook.png',
    images: ['https://example.com/notebook.png'],
  );

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('cart_test_');
    Hive.init(directory.path);
    storage = CartStorage();
    await storage.init();
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('cart survives a restart and updates quantity offline', () async {
    final cubit = CartCubit(storage);
    await cubit.loadCart();

    expect(cubit.state.status, CartStatus.ready);
    expect(cubit.state.totalQuantity, 0);
    expect(cubit.state.totalPrice, 0);

    await cubit.addProduct(product);
    expect(cubit.state.totalQuantity, 1);
    expect(cubit.state.totalPrice, 12.5);
    await cubit.close();

    final restored = CartCubit(storage);
    await restored.loadCart();
    expect(restored.state.items.single.productId, product.id);
    expect(restored.state.totalQuantity, 1);

    await restored.increaseQuantity(product.id);
    expect(restored.state.totalQuantity, 2);
    expect(restored.state.totalPrice, 25);
    await restored.close();

    final afterEdit = CartCubit(storage);
    await afterEdit.loadCart();
    expect(afterEdit.state.totalQuantity, 2);
    expect(afterEdit.state.totalPrice, 25);
    expect(storage.readItems().single.quantity, 2);

    await afterEdit.decreaseQuantity(product.id);
    expect(afterEdit.state.totalQuantity, 1);
    expect(afterEdit.state.totalPrice, 12.5);

    await afterEdit.decreaseQuantity(product.id);
    expect(afterEdit.state.items, isEmpty);

    await afterEdit.addProduct(product);
    await afterEdit.removeProduct(product.id);
    expect(afterEdit.state.items, isEmpty);
    expect(afterEdit.state.totalQuantity, 0);
    expect(afterEdit.state.totalPrice, 0);
    await afterEdit.close();

    final afterRemove = CartCubit(storage);
    await afterRemove.loadCart();
    expect(afterRemove.state.items, isEmpty);
    expect(storage.readItems(), isEmpty);
    await afterRemove.close();
  });
}
