import 'package:equatable/equatable.dart';

import '../../../home/data/models/variation_model.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

final class CartStarted extends CartEvent {
  const CartStarted();
}

final class CartItemAdded extends CartEvent {
  const CartItemAdded({
    required this.itemId,
    required this.variation,
    this.quantity = 1,
  });
  final int itemId;
  final VariationModel variation;
  final int quantity;
  @override
  List<Object?> get props => [itemId, variation, quantity];
}

final class CartItemQuantityUpdated extends CartEvent {
  const CartItemQuantityUpdated({
    required this.cartId,
    required this.newQuantity,
    required this.variation,
  });
  final int cartId;
  final int newQuantity;
  final VariationModel variation;
  @override
  List<Object?> get props => [cartId, newQuantity, variation];
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved({required this.cartId});
  final int cartId;
  @override
  List<Object?> get props => [cartId];
}
