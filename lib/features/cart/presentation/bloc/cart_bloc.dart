import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({CartRepository? repository})
      : _repo = repository ?? CartRepository(),
        super(const CartInitial()) {
    on<CartStarted>(_onStarted, transformer: _sequential());
    on<CartItemAdded>(_onItemAdded, transformer: _sequential());
    on<CartItemQuantityUpdated>(_onQuantityUpdated, transformer: _sequential());
    on<CartItemRemoved>(_onItemRemoved, transformer: _sequential());
  }

  final CartRepository _repo;

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    emit(const CartLoading());
    try {
      final items = await _repo.getCart();
      debugPrint('[CartBloc] loaded ${items.length} items');
      emit(CartLoaded(items: items));
    } catch (e) {
      debugPrint('[CartBloc] load error: $e');
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final prev = state;
    if (prev is CartLoaded) emit(prev.copyWith(isUpdating: true));
    try {
      await _repo.addToCart(
        itemId: event.itemId,
        quantity: event.quantity,
        variation: event.variation,
      );
      final items = await _repo.getCart();
      emit(CartLoaded(items: items));
      debugPrint('[CartBloc] added item ${event.itemId}, cart now ${items.length}');
    } catch (e) {
      debugPrint('[CartBloc] addToCart error: $e');
      if (prev is CartLoaded) emit(prev.copyWith(isUpdating: false));
    }
  }

  Future<void> _onQuantityUpdated(
      CartItemQuantityUpdated event, Emitter<CartState> emit) async {
    final prev = state;
    if (prev is CartLoaded) emit(prev.copyWith(isUpdating: true));
    try {
      await _repo.updateCart(
        cartId: event.cartId,
        quantity: event.newQuantity,
        variation: event.variation,
      );
      final items = await _repo.getCart();
      emit(CartLoaded(items: items));
    } catch (e) {
      debugPrint('[CartBloc] updateCart error: $e');
      if (prev is CartLoaded) emit(prev.copyWith(isUpdating: false));
    }
  }

  Future<void> _onItemRemoved(
      CartItemRemoved event, Emitter<CartState> emit) async {
    final prev = state;
    CartLoaded? optimisticState;
    if (prev is CartLoaded) {
      final optimistic = prev.items.where((i) => i.id != event.cartId).toList();
      optimisticState = CartLoaded(items: optimistic, isUpdating: true);
      emit(optimisticState);
    }
    try {
      await _repo.removeFromCart(cartId: event.cartId);
      if (optimisticState != null) {
        emit(optimisticState.copyWith(isUpdating: false));
      }
      debugPrint('[CartBloc] removed cart item ${event.cartId}');
    } catch (e) {
      debugPrint('[CartBloc] removeCart error: $e');
      if (prev is CartLoaded) emit(prev.copyWith(isUpdating: false));
    }
  }
}

EventTransformer<E> _sequential<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
