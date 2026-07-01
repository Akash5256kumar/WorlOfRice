part of 'order_bloc.dart';

sealed class OrderState {
  const OrderState();
}

final class OrderInitial extends OrderState {
  const OrderInitial();
}

final class OrderLoading extends OrderState {
  const OrderLoading();
}

final class RunningOrdersLoaded extends OrderState {
  const RunningOrdersLoaded({
    required this.orders,
    required this.total,
    this.isRefreshing = false,
  });

  final List<OrderModel> orders;
  final int total;
  final bool isRefreshing;
}

final class OrderTrackLoaded extends OrderState {
  const OrderTrackLoaded(this.order);
  final OrderModel order;
}

final class OrderDetailsLoaded extends OrderState {
  const OrderDetailsLoaded(this.order);
  final OrderModel order;
}

final class OrderError extends OrderState {
  const OrderError(this.message);
  final String message;
}
