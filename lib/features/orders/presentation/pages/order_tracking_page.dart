import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../bloc/order_bloc.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderBloc()..add(OrderTrackStarted(orderId)),
      child: _OrderTrackingScaffold(orderId: orderId),
    );
  }
}

class _OrderTrackingScaffold extends StatelessWidget {
  const _OrderTrackingScaffold({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.darkBrown,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: AppColors.primaryGreen,
            ),
            onPressed: () =>
                context.read<OrderBloc>().add(OrderTrackStarted(orderId)),
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
                  context.read<OrderBloc>().add(OrderTrackStarted(orderId)),
            );
          }

          if (state is OrderTrackLoaded) {
            return _TrackingBody(order: state.order);
          }

          if (state is OrderDetailsLoaded) {
            return _TrackingBody(order: state.order);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              children: [
                _TrackingHero(order: order),
                const SizedBox(height: 16),
                _DynamicMetaCard(order: order),
                if (order.trackingTimeline.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _TrackingTimelineCard(entries: order.trackingTimeline),
                ],
                if (order.store != null &&
                    (order.store!.name.isNotEmpty ||
                        (order.store!.address?.isNotEmpty ?? false) ||
                        (order.store!.phone?.isNotEmpty ?? false))) ...[
                  const SizedBox(height: 16),
                  _MerchantCard(store: order.store!),
                ],
                if (order.items.isNotEmpty || order.displayItemCount > 0) ...[
                  const SizedBox(height: 16),
                  _ItemsCard(order: order),
                ],
                if (_showPricing(order)) ...[
                  const SizedBox(height: 16),
                  _PricingCard(order: order),
                ],
                if (_showDeliverySection(order)) ...[
                  const SizedBox(height: 16),
                  _DeliveryAndPaymentCard(order: order),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static bool _showPricing(OrderModel order) {
    return order.grandTotal > 0 ||
        order.derivedSubtotal > 0 ||
        order.deliveryCharge > 0 ||
        order.taxAmount > 0 ||
        order.couponDiscount > 0;
  }

  static bool _showDeliverySection(OrderModel order) {
    final address = order.deliveryAddress;
    return address != null ||
        order.paymentMethod.isNotEmpty ||
        order.paymentStatus.isNotEmpty ||
        (order.transactionRef?.isNotEmpty ?? false);
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final currentEntry = order.trackingTimeline.isNotEmpty
        ? order.trackingTimeline.firstWhere(
            (entry) => entry.isCurrent,
            orElse: () => order.trackingTimeline.last,
          )
        : null;
    final headline = currentEntry?.label.isNotEmpty == true
        ? currentEntry!.label
        : order.statusLabel;
    final timelineLength = order.trackingTimeline.length;
    final currentIndex =
        order.trackingTimeline.indexWhere((entry) => entry.isCurrent);
    final progress = timelineLength <= 1
        ? (headline.isNotEmpty ? 1.0 : 0.0)
        : ((currentIndex == -1 ? timelineLength : currentIndex + 1) /
                timelineLength)
            .clamp(0.0, 1.0);
    final accent = _statusColor(order.orderStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF103D27),
            AppColors.primaryGreen,
            AppColors.darkBrown,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (order.store?.name.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        order.store!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                    if (order.formattedCreatedAt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.formattedCreatedAt,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (headline.isNotEmpty)
                _StatusPill(
                  label: headline,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  textColor: Colors.white,
                  borderColor: Colors.white.withValues(alpha: 0.16),
                ),
            ],
          ),
          if (headline.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              headline,
              style: GoogleFonts.poppins(
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
          if (currentEntry?.description.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              currentEntry!.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
          if (progress > 0) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentGoldLight,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Items',
                  value: '${order.displayItemCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Total',
                  value: _formatCurrency(order.grandTotal),
                ),
              ),
              if (order.etaLabel.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroMetric(
                    label: 'Window',
                    value: order.etaLabel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicMetaCard extends StatelessWidget {
  const _DynamicMetaCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final metadata = <_MetaField>[
      _MetaField(label: 'Tracking Status', value: order.statusLabel),
      _MetaField(label: 'Payment Status', value: order.paymentStatusLabel),
      _MetaField(label: 'Payment Method', value: order.paymentMethodLabel),
      _MetaField(label: 'Order Type', value: order.orderTypeLabel),
      _MetaField(label: 'Delivery Window', value: order.etaLabel),
      _MetaField(label: 'Transaction Ref', value: order.transactionRef ?? ''),
      _MetaField(label: 'Verification OTP', value: order.otp ?? ''),
    ].where((field) => field.value.isNotEmpty).toList();

    if (metadata.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Order Snapshot',
      icon: Icons.grid_view_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: metadata
            .map((field) =>
                _MetaTile(field: field, color: _statusColor(field.value)))
            .toList(),
      ),
    );
  }
}

class _TrackingTimelineCard extends StatelessWidget {
  const _TrackingTimelineCard({required this.entries});

  final List<OrderTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Tracking Timeline',
      icon: Icons.alt_route_rounded,
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            _TimelineTile(
              entry: entries[index],
              isLast: index == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isLast});

  final OrderTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = entry.isCurrent
        ? AppColors.primaryGreen
        : entry.isCompleted
            ? AppColors.accentGold
            : AppColors.borderMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color:
                      accent.withValues(alpha: entry.isCurrent ? 0.16 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.6),
                ),
                child: Icon(
                  entry.isCompleted
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 11,
                  color: accent,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 56,
                  margin: const EdgeInsets.only(top: 6),
                  color: accent.withValues(alpha: 0.22),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: entry.isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (entry.isCurrent)
                      _StatusPill(
                        label: 'Live',
                        backgroundColor:
                            AppColors.primaryGreen.withValues(alpha: 0.1),
                        textColor: AppColors.primaryGreen,
                        borderColor:
                            AppColors.primaryGreen.withValues(alpha: 0.18),
                      ),
                  ],
                ),
                if (entry.timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(entry.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.store});

  final OrderStore store;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Fulfilled By',
      icon: Icons.storefront_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F1E7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: store.logoFullUrl != null && store.logoFullUrl!.isNotEmpty
                  ? Image.network(
                      store.logoFullUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : const Icon(
                      Icons.store_rounded,
                      color: AppColors.primaryGreen,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (store.name.isNotEmpty)
                  Text(
                    store.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (store.address?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    store.address!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (store.phone?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    store.phone!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items in This Order',
      icon: Icons.shopping_bag_outlined,
      child: order.items.isEmpty
          ? Text(
              '${order.displayItemCount} item${order.displayItemCount == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < order.items.length; index++) ...[
                  _OrderItemTile(item: order.items[index]),
                  if (index < order.items.length - 1)
                    const Divider(height: 22, color: Color(0xFFF0E8DB)),
                ],
              ],
            ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1E7),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: item.imageFullUrl != null && item.imageFullUrl!.isNotEmpty
                ? Image.network(
                    item.imageFullUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.grass_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : const Icon(
                    Icons.grass_rounded,
                    color: AppColors.primaryGreen,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (item.variant.isNotEmpty) ...[
                const SizedBox(height: 6),
                _StatusPill(
                  label: item.variant,
                  backgroundColor: const Color(0xFFF6F1E7),
                  textColor: AppColors.darkBrown,
                  borderColor: const Color(0xFFE7DCC7),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Qty ${item.quantity}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.price > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Unit ${_formatCurrency(item.price)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(item.lineTotal),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            if (item.taxAmount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Tax ${_formatCurrency(item.taxAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final rows = <_PriceRowData>[
      if (order.derivedSubtotal > 0)
        _PriceRowData(label: 'Items Total', value: order.derivedSubtotal),
      if (order.deliveryCharge > 0)
        _PriceRowData(label: 'Delivery Charge', value: order.deliveryCharge),
      if (order.taxAmount > 0)
        _PriceRowData(label: 'Taxes', value: order.taxAmount),
      if (order.couponDiscount > 0)
        _PriceRowData(
          label: 'Discount',
          value: order.couponDiscount,
          isDiscount: true,
        ),
    ];

    return _SectionCard(
      title: 'Price Details',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          for (final row in rows) ...[
            _PriceRow(row: row),
            const SizedBox(height: 10),
          ],
          const Divider(height: 18, color: Color(0xFFF0E8DB)),
          _PriceRow(
            row: _PriceRowData(label: 'Grand Total', value: order.grandTotal),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.row, this.isTotal = false});

  final _PriceRowData row;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final color = row.isDiscount ? AppColors.primaryGreen : AppColors.darkBrown;
    final formatted = row.isDiscount
        ? '- ${_formatCurrency(row.value)}'
        : _formatCurrency(row.value);

    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          formatted,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: isTotal ? AppColors.darkBrown : color,
          ),
        ),
      ],
    );
  }
}

class _DeliveryAndPaymentCard extends StatelessWidget {
  const _DeliveryAndPaymentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress;

    return _SectionCard(
      title: 'Delivery and Payment',
      icon: Icons.local_shipping_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address != null) ...[
            if (address.addressType.isNotEmpty)
              _DetailLine(label: 'Address Type', value: address.addressType),
            if (address.contactName.isNotEmpty)
              _DetailLine(label: 'Contact', value: address.contactName),
            if (address.contactPhone.isNotEmpty)
              _DetailLine(label: 'Phone', value: address.contactPhone),
            if (address.fullAddress.isNotEmpty)
              _DetailLine(label: 'Address', value: address.fullAddress),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0E8DB)),
            const SizedBox(height: 12),
          ],
          if (order.paymentMethodLabel.isNotEmpty)
            _DetailLine(
                label: 'Payment Method', value: order.paymentMethodLabel),
          if (order.paymentStatusLabel.isNotEmpty)
            _DetailLine(
                label: 'Payment Status', value: order.paymentStatusLabel),
          if ((order.transactionRef?.isNotEmpty ?? false))
            _DetailLine(
              label: 'Transaction Ref',
              value: order.transactionRef!,
            ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.field, required this.color});

  final _MetaField field;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width > 460
          ? 180
          : (MediaQuery.sizeOf(context).width - 58) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            field.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaField {
  const _MetaField({required this.label, required this.value});

  final String label;
  final String value;
}

class _PriceRowData {
  const _PriceRowData({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  final String label;
  final double value;
  final bool isDiscount;
}

Color _statusColor(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return AppColors.navy;
  if (normalized.contains('cancel') ||
      normalized.contains('fail') ||
      normalized.contains('reject')) {
    return AppColors.ctaRed;
  }
  if (normalized.contains('deliver') ||
      normalized.contains('complete') ||
      normalized.contains('paid') ||
      normalized.contains('success')) {
    return AppColors.primaryGreen;
  }
  if (normalized.contains('pending') ||
      normalized.contains('hold') ||
      normalized.contains('waiting') ||
      normalized.contains('unpaid')) {
    return AppColors.warning;
  }
  return AppColors.navy;
}

String _formatCurrency(double value) {
  final safe = value.isFinite ? value : 0.0;
  final hasDecimals = safe % 1 != 0;
  return '₹${hasDecimals ? safe.toStringAsFixed(2) : safe.toStringAsFixed(0)}';
}

String _formatDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  try {
    final parsed = DateTime.parse(value).toLocal();
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.day}/${parsed.month}/${parsed.year} • $hour:$minute $period';
  } catch (_) {
    return value;
  }
}
