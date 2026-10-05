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
      width: expanded ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          visualDensity: expanded
              ? VisualDensity.standard
              : VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
    final buttonConstraints = expanded
        ? null
        : const BoxConstraints.tightFor(width: 32, height: 32);

    return Row(
      mainAxisAlignment: expanded
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: buttonConstraints,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),
        Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          tooltip: 'Increase quantity',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: buttonConstraints,
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
