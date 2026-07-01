import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc({OrderRepository? repository})
      : _repo = repository ?? OrderRepository(),
        super(const OrderInitial()) {
    on<OrderRunningOrdersStarted>(_onRunningOrdersStarted);
    on<OrderRefreshed>(_onRefreshed);
    on<OrderTrackStarted>(_onTrackStarted);
    on<OrderDetailsStarted>(_onDetailsStarted);
  }

  final OrderRepository _repo;

  Future<void> _onRunningOrdersStarted(
      OrderRunningOrdersStarted event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    await _loadRunningOrders(emit);
  }

  Future<void> _onRefreshed(
      OrderRefreshed event, Emitter<OrderState> emit) async {
    // Keep current list visible while refreshing.
    final prev = state;
    if (prev is RunningOrdersLoaded) {
      emit(RunningOrdersLoaded(orders: prev.orders, total: prev.total, isRefreshing: true));
    } else {
      emit(const OrderLoading());
    }
    await _loadRunningOrders(emit);
  }

  Future<void> _loadRunningOrders(Emitter<OrderState> emit) async {
    try {
      final result = await _repo.getRunningOrders();
      debugPrint('[OrderBloc] running orders: ${result.orders.length}');
      emit(RunningOrdersLoaded(orders: result.orders, total: result.total));
    } catch (e) {
      debugPrint('[OrderBloc] running orders error: $e');
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onTrackStarted(
      OrderTrackStarted event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final order = await _repo.getOrderTrack(event.orderId);
      debugPrint('[OrderBloc] track loaded: #${order.id} status=${order.orderStatus}');
      emit(OrderTrackLoaded(order));
    } catch (e) {
      debugPrint('[OrderBloc] track error: $e');
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onDetailsStarted(
      OrderDetailsStarted event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final order = await _repo.getOrderDetails(event.orderId);
      debugPrint('[OrderBloc] details loaded: #${order.id} items=${order.items.length}');
      emit(OrderDetailsLoaded(order));
    } catch (e) {
      debugPrint('[OrderBloc] details error: $e');
      emit(OrderError(e.toString()));
    }
  }
}
