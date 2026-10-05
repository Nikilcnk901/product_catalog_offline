import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog_offline_cart/blocs/cart/cart_cubit.dart';
import 'package:product_catalog_offline_cart/blocs/product/product_cubit.dart';
import 'package:product_catalog_offline_cart/data/local/cart_storage.dart';
import 'package:product_catalog_offline_cart/data/remote/product_api.dart';
import 'package:product_catalog_offline_cart/data/repositories/product_repository.dart';
import 'package:product_catalog_offline_cart/models/cart_item.dart';
import 'package:product_catalog_offline_cart/views/product_list_screen.dart';

void main() {
  late _MemoryCartStorage storage;

  setUp(() {
    storage = _MemoryCartStorage();
  });

  testWidgets('adds a product and updates cart totals', (tester) async {
    await tester.pumpWidget(_catalogApp(storage, _CatalogAdapter()));
    await _pumpUntil(tester, find.text('Notebook'));

    expect(find.text('Notebook'), findsOneWidget);
    expect(find.text('\$12.50'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);

    await tester.tap(find.text('Notebook'));
    await _pumpUntil(tester, find.text('A ruled notebook'));

    expect(find.text('Stationery'), findsOneWidget);
    expect(find.text('Paper Co'), findsOneWidget);
    expect(find.text('8 in stock'), findsOneWidget);

    await tester.tap(find.text('Add to Cart'));
    await _flushCartWrites(tester);

    expect(find.text('Notebook added to cart'), findsAtLeastNWidgets(1));
    expect(storage.readItems().single.quantity, 1);
    expect(storage.readItems().single.price, 12.5);

    ScaffoldMessenger.of(
      tester.element(find.text('Add to Cart')),
    ).clearSnackBars();
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Products'), findsOneWidget);
    await tester.tap(find.byTooltip('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Items: 1'), findsOneWidget);
    expect(find.text('Total: \$12.50'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await _flushCartWrites(tester);
    expect(find.text('Items: 2'), findsOneWidget);
    expect(find.text('Total: \$25.00'), findsOneWidget);
    expect(storage.readItems().single.quantity, 2);

    await tester.tap(find.byTooltip('Decrease quantity'));
    await _flushCartWrites(tester);
    expect(find.text('Items: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await _flushCartWrites(tester);
    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(find.text('Items: 0'), findsOneWidget);
    expect(find.text('Total: \$0.00'), findsOneWidget);
    expect(storage.readItems(), isEmpty);
  });

  testWidgets('search shows an empty state and can return to the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(_catalogApp(storage, _CatalogAdapter()));
    await _pumpUntil(tester, find.text('Notebook'));

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump(const Duration(milliseconds: 500));
    await _pumpUntil(tester, find.text('No products match "missing".'));

    expect(find.text('Notebook'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await _pumpUntil(tester, find.text('Notebook'));
  });

  testWidgets('product loading failure can be retried', (tester) async {
    await tester.pumpWidget(_catalogApp(storage, _FlakyCatalogAdapter()));
    await _pumpUntil(tester, find.text('Check your connection and try again.'));

    expect(find.text('SocketException'), findsNothing);

    await tester.tap(find.text('Retry'));
    await _pumpUntil(tester, find.text('Notebook'));
  });
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _flushCartWrites(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class _MemoryCartStorage extends CartStorage {
  final _items = <CartItem>[];

  @override
  Future<void> init() async {}

  @override
  List<CartItem> readItems() => List<CartItem>.of(_items);

  @override
  Future<void> saveItems(List<CartItem> items) async {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> removeItem(int productId) async {
    _items.removeWhere((item) => item.productId == productId);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

Widget _catalogApp(CartStorage storage, HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..httpClientAdapter = adapter;

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) {
          final cubit = ProductCubit(
            ProductRepository(api: ProductApi(dio: dio)),
          );
          unawaited(cubit.loadProducts());
          return cubit;
        },
      ),
      BlocProvider(
        create: (_) {
          final cubit = CartCubit(storage);
          unawaited(cubit.loadCart());
          return cubit;
        },
      ),
    ],
    child: const MaterialApp(home: ProductListScreen()),
  );
}

Map<String, Object?> _productJson() {
  return {
    'id': 1,
    'title': 'Notebook',
    'description': 'A ruled notebook',
    'price': 12.5,
    'rating': 4.5,
    'category': 'stationery',
    'brand': 'Paper Co',
    'stock': 8,
    'thumbnail': '',
    'images': <String>[],
  };
}

ResponseBody _jsonBody(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _CatalogAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path.endsWith('/search')) {
      final query = options.uri.queryParameters['q'];
      final products = query == 'missing' ? <Object?>[] : [_productJson()];
      return _jsonBody({'products': products});
    }
    if (RegExp(r'/products/\d+$').hasMatch(path)) {
      return _jsonBody(_productJson());
    }
    return _jsonBody({
      'products': [_productJson()],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FlakyCatalogAdapter implements HttpClientAdapter {
  var _attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _attempts += 1;
    if (_attempts == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'SocketException: failed host lookup',
      );
    }
    return _jsonBody({
      'products': [_productJson()],
    });
  }

  @override
  void close({bool force = false}) {}
}
