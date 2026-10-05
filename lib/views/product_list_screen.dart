import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/product/product_cubit.dart';
import '../blocs/product/product_state.dart';
import '../core/format/price_format.dart';
import '../models/product.dart';
import '../widgets/cart_quantity_control.dart';
import '../widgets/product_image.dart';
import '../widgets/status_message.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _searchDelay = Duration(milliseconds: 400);

  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _submittedQuery;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 12),
            child: Row(
              children: [
                Expanded(child: _searchField()),
                _CartButton(onPressed: () => _openCart(context)),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        buildWhen: (previous, current) {
          return previous.listStatus != current.listStatus ||
              previous.products != current.products ||
              previous.listErrorMessage != current.listErrorMessage ||
              previous.query != current.query;
        },
        builder: (context, state) {
          return switch (state.listStatus) {
            ProductListStatus.initial || ProductListStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ProductListStatus.failure => StatusMessage(
              icon: Icons.error_outline,
              message:
                  state.listErrorMessage ??
                  'Something went wrong while loading products.',
              actionLabel: 'Retry',
              onAction: () {
                context.read<ProductCubit>().searchProducts(state.query);
              },
            ),
            ProductListStatus.success when state.products.isEmpty =>
              StatusMessage(
                icon: state.query.isEmpty
                    ? Icons.shopping_bag_outlined
                    : Icons.search_off,
                message: state.query.isEmpty
                    ? 'No products to show.'
                    : 'No products match "${state.query}".',
              ),
            ProductListStatus.success => _ProductGrid(
              products: state.products,
              onProductTap: (productId) => _openProduct(context, productId),
            ),
          };
        },
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      onChanged: _onSearchChanged,
      onSubmitted: _submitSearch,
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Clear search',
              onPressed: _clearSearch,
              icon: const Icon(Icons.close),
            );
          },
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDelay, () {
      if (!mounted) return;
      _submitSearch(_searchController.text);
    });
  }

  void _submitSearch(String raw) {
    _debounce?.cancel();
    final query = raw.trim();
    if (query == _submittedQuery) return;
    _submittedQuery = query;
    context.read<ProductCubit>().searchProducts(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _submitSearch('');
  }

  void _openCart(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  void _openProduct(BuildContext context, int productId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(productId: productId),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.totalQuantity,
      builder: (context, itemCount) {
        return IconButton(
          tooltip: 'Cart',
          onPressed: onPressed,
          icon: Badge(
            isLabelVisible: itemCount > 0,
            label: Text('$itemCount'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onProductTap});

  final List<Product> products;
  final ValueChanged<int> onProductTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          key: ValueKey(product.id),
          product: product,
          onTap: () => onProductTap(product.id),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ProductImage(url: product.thumbnail)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatPrice(product.price),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: CartQuantityControl(product: product),
          ),
        ],
      ),
    );
  }
}
