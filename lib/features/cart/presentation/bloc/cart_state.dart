import 'package:equatable/equatable.dart';

import '../../data/models/cart_item_model.dart';

sealed class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartLoaded extends CartState {
  const CartLoaded({required this.items, this.isUpdating = false});

  final List<CartItemModel> items;
  final bool isUpdating;

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);
  int get totalItems => items.fold(0, (s, i) => s + i.quantity);
  double get totalWeight => items.fold(0.0, (s, i) => s + i.weightTotal);

  CartLoaded copyWith({List<CartItemModel>? items, bool? isUpdating}) =>
      CartLoaded(
        items: items ?? this.items,
        isUpdating: isUpdating ?? this.isUpdating,
      );

  @override
  List<Object?> get props => [items, isUpdating];
}

final class CartError extends CartState {
  const CartError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
