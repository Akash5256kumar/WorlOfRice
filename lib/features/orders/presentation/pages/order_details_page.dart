import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../bloc/order_bloc.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderBloc()..add(OrderDetailsStarted(orderId)),
      child: _OrderDetailsScaffold(orderId: orderId),
    );
  }
}

class _OrderDetailsScaffold extends StatelessWidget {
  const _OrderDetailsScaffold({required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 22, color: AppColors.primaryGreen),
            onPressed: () =>
                context.read<OrderBloc>().add(OrderDetailsStarted(orderId)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8E0D5)),
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }
          if (state is OrderError) {
            return _ErrorBody(
              message: state.message,
              onRetry: () =>
                  context.read<OrderBloc>().add(OrderDetailsStarted(orderId)),
            );
          }
          if (state is OrderDetailsLoaded) {
            return _DetailsBody(order: state.order);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order header ─────────────────────────────────────────────
          _OrderHeaderCard(order: order),
          const SizedBox(height: 16),

          // ── Store info ───────────────────────────────────────────────
          if (order.store != null) ...[
            _StoreCard(store: order.store!),
            const SizedBox(height: 16),
          ],

          // ── Items list ───────────────────────────────────────────────
          _ItemsCard(items: order.items, order: order),
          const SizedBox(height: 16),

          // ── Bill summary ─────────────────────────────────────────────
          _BillSummaryCard(order: order),
          const SizedBox(height: 16),

          // ── Delivery address ─────────────────────────────────────────
          if (order.deliveryAddress != null) ...[
            _AddressCard(address: order.deliveryAddress!),
            const SizedBox(height: 16),
          ],

          // ── Payment info ─────────────────────────────────────────────
          _PaymentCard(order: order),
          const SizedBox(height: 20),

          // ── Reorder button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reorder feature coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text('Reorder',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order header card ─────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});
  final OrderModel order;

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.primaryGreen;
      case 'cancelled':
      case 'failed':
        return AppColors.ctaRed;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.30)),
                ),
                child: Text(
                  order.statusLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),
          if (order.createdAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.createdAt,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Store card ────────────────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final OrderStore store;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Fulfilled By',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E0D5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: store.logoFullUrl != null
                  ? Image.network(
                      store.logoFullUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        size: 24,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : const Icon(Icons.store_rounded,
                      size: 24, color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (store.address != null && store.address!.isNotEmpty)
                  Text(store.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items card ────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.order});
  final List<OrderItem> items;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items Ordered',
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${order.displayItemCount} item${order.displayItemCount == 1 ? '' : 's'} ordered',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _ItemRow(item: items[i]),
                  if (i < items.length - 1)
                    const Divider(height: 16, color: Color(0xFFF0EAE0)),
                ],
              ],
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8E0D5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: item.imageFullUrl != null
                ? Image.network(
                    item.imageFullUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.grass_rounded,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const Icon(Icons.grass_rounded,
                    size: 24, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),

        // Name + variant + qty
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              if (item.variant.isNotEmpty) ...[
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.variant,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textSecondary)),
                ),
              ],
              const SizedBox(height: 4),
              Text('Qty: ${item.quantity}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
              if (item.taxAmount > 0)
                Text('Tax: ₹${item.taxAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),

        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${item.lineTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown)),
            Text('₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ── Bill summary card ─────────────────────────────────────────────────────────

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final itemsTotal = order.items.isNotEmpty
        ? order.items.fold(0.0, (sum, i) => sum + i.lineTotal)
        : order.orderAmount;

    return _SectionCard(
      title: 'Bill Summary',
      child: Column(
        children: [
          _BillRow(label: 'Item Total', value: '₹${itemsTotal.toStringAsFixed(0)}'),
          if (order.taxAmount > 0) ...[
            const SizedBox(height: 8),
            _BillRow(
                label: 'Taxes & Charges',
                value: '₹${order.taxAmount.toStringAsFixed(0)}'),
          ],
          if (order.deliveryCharge > 0) ...[
            const SizedBox(height: 8),
            _BillRow(
                label: 'Delivery Fee',
                value: '₹${order.deliveryCharge.toStringAsFixed(0)}'),
          ] else ...[
            const SizedBox(height: 8),
            _BillRow(
                label: 'Delivery Fee',
                value: 'FREE',
                valueColor: AppColors.primaryGreen),
          ],
          if (order.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _BillRow(
                label: 'Coupon Discount',
                value: '−₹${order.couponDiscount.toStringAsFixed(0)}',
                valueColor: AppColors.primaryGreen),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0EAE0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown)),
              Text(
                '₹${order.orderAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

// ── Delivery address card ─────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});
  final OrderAddress address;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Delivery Address',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                size: 20, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.contactName.isNotEmpty)
                  Text(address.contactName,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown)),
                if (address.contactPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(address.contactPhone,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
                if (address.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(address.fullAddress,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment Information',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Method',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                order.isCOD ? 'Cash on Delivery' : 'Online Payment',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Status',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isPaid
                      ? AppColors.primaryGreen.withValues(alpha: 0.10)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.isCOD && !order.isPaid
                      ? 'Pay on Delivery'
                      : order.paymentStatusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: order.isPaid
                        ? AppColors.primaryGreen
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
