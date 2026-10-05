import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog_offline_cart/views/product_list_screen.dart';

void main() {
  testWidgets('catalog screen opens the cart and a product', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProductListScreen()));

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Products will show up here.'), findsOneWidget);

    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Cart items will show up here.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open product'));
    await tester.pumpAndSettle();

    expect(
      find.text('Details for product 1 will show up here.'),
      findsOneWidget,
    );
  });
}
