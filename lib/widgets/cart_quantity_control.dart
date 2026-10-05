import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/cart/cart_state.dart';
import '../models/product.dart';

class CartQuantityControl extends StatelessWidget {
  const CartQuantityControl({
    super.key,
    required this.product,
    this.expanded = false,
    this.onAdded,
  });

  final Product product;
  final bool expanded;
  final void Function(CartCubit cart)? onAdded;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.quantityOf(product.id),
      builder: (context, quantity) {
        if (quantity <= 0) {
          return _AddToCartButton(
            expanded: expanded,
            onPressed: () => _add(context),
          );
        }

        return _QuantityStepper(
          quantity: quantity,
          expanded: expanded,
          onDecrease: () {
            context.read<CartCubit>().decreaseQuantity(product.id);
          },
          onIncrease: () {
            context.read<CartCubit>().increaseQuantity(product.id);
          },
        );
      },
    );
  }

  Future<void> _add(BuildContext context) async {
    final cart = context.read<CartCubit>();
    await cart.addProduct(product);
    if (!context.mounted) return;
    onAdded?.call(cart);
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          visualDensity: expanded
              ? VisualDensity.standard
              : VisualDensity.compact,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: expanded ? 14 : 8,
          ),
        ),
        child: const Text('Add to Cart'),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.expanded,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool expanded;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonConstraints = expanded
        ? const BoxConstraints.tightFor(width: 44, height: 44)
        : const BoxConstraints.tightFor(width: 36, height: 36);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            onPressed: onDecrease,
            icon: Icon(Icons.remove, size: expanded ? 22 : 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            onPressed: onIncrease,
            icon: Icon(Icons.add, size: expanded ? 22 : 18),
          ),
        ],
      ),
    );
  }
}
