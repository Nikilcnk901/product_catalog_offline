import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/cart/cart_cubit.dart';
import 'blocs/product/product_cubit.dart';
import 'core/theme/app_theme.dart';
import 'data/local/cart_storage.dart';
import 'data/repositories/product_repository.dart';
import 'views/product_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final cartStorage = CartStorage();
  await cartStorage.init();

  runApp(
    ProductCatalogApp(
      productRepository: ProductRepository(),
      cartStorage: cartStorage,
    ),
  );
}

class ProductCatalogApp extends StatelessWidget {
  const ProductCatalogApp({
    super.key,
    required this.productRepository,
    required this.cartStorage,
  });

  final ProductRepository productRepository;
  final CartStorage cartStorage;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = ProductCubit(productRepository);
            unawaited(cubit.loadProducts());
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = CartCubit(cartStorage);
            unawaited(cubit.loadCart());
            return cubit;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Product Catalog',
        theme: AppTheme.light,
        home: const ProductListScreen(),
      ),
    );
  }
}
