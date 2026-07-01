part of 'order_bloc.dart';

sealed class OrderEvent {
  const OrderEvent();
}

/// Fetch the customer's active/running orders.
final class OrderRunningOrdersStarted extends OrderEvent {
  const OrderRunningOrdersStarted();
}

/// Pull-to-refresh running orders list.
final class OrderRefreshed extends OrderEvent {
  const OrderRefreshed();
}

/// Fetch live tracking for a single order.
final class OrderTrackStarted extends OrderEvent {
  const OrderTrackStarted(this.orderId);
  final int orderId;
}

/// Fetch full details for a single order.
final class OrderDetailsStarted extends OrderEvent {
  const OrderDetailsStarted(this.orderId);
  final int orderId;
}
