import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/cart/cart_state.dart';
import '../core/format/price_format.dart';
import '../models/cart_item.dart';
import '../widgets/product_image.dart';
import '../widgets/status_message.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          final waiting =
              state.items.isEmpty &&
              (state.status == CartStatus.initial ||
                  state.status == CartStatus.loading);

          if (waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CartStatus.failure && state.items.isEmpty) {
            return StatusMessage(
              icon: Icons.error_outline,
              message: state.errorMessage ?? 'Could not load the cart.',
              actionLabel: 'Retry',
              onAction: () => context.read<CartCubit>().loadCart(),
            );
          }

          return Column(
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: state.items.isEmpty
                    ? const StatusMessage(
                        icon: Icons.shopping_cart_outlined,
                        message: 'Your cart is empty.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _CartLine(
                            key: ValueKey(item.productId),
                            item: item,
                          );
                        },
                      ),
              ),
              _CartSummary(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartCubit>();

    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: ProductImage(url: item.thumbnail, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(item.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease quantity',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              onPressed: () =>
                                  cart.decreaseQuantity(item.productId),
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase quantity',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              onPressed: () =>
                                  cart.increaseQuantity(item.productId),
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => cart.removeProduct(item.productId),
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Total items',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.totalQuantity}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Total price',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(state.totalPrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
