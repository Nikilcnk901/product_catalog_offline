import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/product/product_cubit.dart';
import '../blocs/product/product_state.dart';
import '../core/format/price_format.dart';
import '../models/product.dart';
import '../widgets/product_image.dart';
import '../widgets/status_message.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  var _adding = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      buildWhen: (previous, current) {
        return previous.detailsStatus != current.detailsStatus ||
            previous.selectedProduct != current.selectedProduct ||
            previous.detailsErrorMessage != current.detailsErrorMessage;
      },
      builder: (context, state) {
        final product = state.selectedProduct;
        final loaded =
            state.detailsStatus == ProductDetailsStatus.success &&
            product != null &&
            product.id == widget.productId;

        return Scaffold(
          appBar: AppBar(title: Text(loaded ? product.title : 'Product')),
          bottomNavigationBar: loaded
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: _adding ? null : () => _addToCart(product),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                )
              : null,
          body: _buildBody(context, state, loaded ? product : null),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductState state,
    Product? product,
  ) {
    if (product != null) {
      return _ProductDetailsBody(product: product);
    }

    if (state.detailsStatus == ProductDetailsStatus.failure) {
      return StatusMessage(
        icon: Icons.error_outline,
        message:
            state.detailsErrorMessage ??
            'Something went wrong while loading this product.',
        actionLabel: 'Retry',
        onAction: () {
          context.read<ProductCubit>().loadProduct(widget.productId);
        },
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _addToCart(Product product) async {
    if (_adding) return;
    setState(() => _adding = true);
    final cart = context.read<CartCubit>();

    try {
      await cart.addProduct(product);
      if (!mounted) return;
      final failed = cart.state.status == CartStatus.failure;
      final message = failed
          ? (cart.state.errorMessage ?? 'Could not update the cart.')
          : '${product.title} added to cart';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      children: [
        _ProductGallery(urls: _imageUrls(product)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                formatPrice(product.price),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailFact(
                label: 'Category',
                value: _displayLabel(product.category),
              ),
              _DetailFact(label: 'Brand', value: _displayLabel(product.brand)),
              _DetailFact(label: 'Stock', value: _stockLabel(product.stock)),
              const SizedBox(height: 8),
              Text(product.description, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _imageUrls(Product product) {
    if (product.images.isNotEmpty) return product.images;
    if (product.thumbnail.isNotEmpty) return [product.thumbnail];
    return const [];
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.urls});

  final List<String> urls;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final colorScheme = Theme.of(context).colorScheme;

    if (urls.isEmpty) {
      return const SizedBox(
        height: 240,
        width: double.infinity,
        child: ProductImage(url: ''),
      );
    }

    return Column(
      children: [
        ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: urls.length == 1
                ? ProductImage(url: urls.first, fit: BoxFit.contain)
                : PageView.builder(
                    itemCount: urls.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) {
                      return ProductImage(
                        url: urls[index],
                        fit: BoxFit.contain,
                      );
                    },
                  ),
          ),
        ),
        if (urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < urls.length; index++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailFact extends StatelessWidget {
  const _DetailFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

String _displayLabel(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return '—';

  return trimmed
      .split(RegExp(r'[-\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        final rest = word.length > 1 ? word.substring(1) : '';
        return '${word[0].toUpperCase()}$rest';
      })
      .join(' ');
}

String _stockLabel(int stock) {
  if (stock <= 0) return 'Out of stock';
  if (stock == 1) return '1 in stock';
  return '$stock in stock';
}
