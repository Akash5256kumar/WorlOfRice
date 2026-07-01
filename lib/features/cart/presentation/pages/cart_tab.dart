import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/variation_picker_sheet.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../payment/data/repositories/checkout_repository.dart';
import '../../../payment/presentation/pages/checkout_page.dart';
import '../../data/models/cart_item_model.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

void _dispatchCartRemoval(BuildContext context, int cartId) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    context.read<CartBloc>().add(CartItemRemoved(cartId: cartId));
  });
}

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          BlocBuilder<CartBloc, CartState>(
            buildWhen: (prev, curr) =>
                (prev is CartLoaded ? prev.totalItems : -1) !=
                (curr is CartLoaded ? curr.totalItems : -1),
            builder: (context, state) {
              final count =
                  state is CartLoaded ? state.totalItems : 0;
              final canPop = Navigator.canPop(context);
              return Container(
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: canPop ? 4 : 20,
                  right: 20,
                ),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.darkBrown,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Text(
                      'My Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'item' : 'items'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoading || state is CartInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen),
                  );
                }
                if (state is CartError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<CartBloc>().add(const CartStarted()),
                  );
                }
                if (state is CartLoaded && state.items.isEmpty) {
                  return const _EmptyCart();
                }
                if (state is CartLoaded) {
                  return _CartLoadedView(state: state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loaded view (list + summary + checkout) ───────────────────────────────────

class _CartLoadedView extends StatefulWidget {
  const _CartLoadedView({required this.state});
  final CartLoaded state;

  @override
  State<_CartLoadedView> createState() => _CartLoadedViewState();
}

class _CartLoadedViewState extends State<_CartLoadedView> {
  final _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Stack(
      children: [
        // Scrollable content — fills the full available area
        Positioned.fill(
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            backgroundColor: Colors.white,
            onRefresh: () async {
              context.read<CartBloc>().add(const CartStarted());
              await context.read<CartBloc>().stream.firstWhere(
                    (s) => s is CartLoaded || s is CartError,
                  );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: state.items.length + 2,
              itemBuilder: (context, index) {
                if (index < state.items.length) {
                  return _CartItemCard(item: state.items[index]);
                }
                if (index == state.items.length) {
                  return const SizedBox(height: 12);
                }
                return _PriceDetailsCard(state: state, couponCtrl: _couponCtrl);
              },
            ),
          ),
        ),
        // Sticky checkout bar at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CheckoutBar(state: state),
        ),
        // Loading overlay — always in the tree so its render box is always
        // laid out; opacity drives visibility to avoid "never been laid out"
        // hit-test crashes when the overlay is toggled mid-gesture.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !state.isUpdating,
            child: AnimatedOpacity(
              opacity: state.isUpdating ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cart item card ────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});
  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final name = product?.name ?? 'Item #${item.itemId}';
    final imageUrl = product?.imageFullUrl;
    final allVariations = product?.variations ?? [];
    final canChangeVariation = allVariations.length > 1;

    return Dismissible(
      key: ValueKey('cart-item-${item.id}'),
      direction: DismissDirection.endToStart,
      resizeDuration: null,
      confirmDismiss: (_) async {
        _dispatchCartRemoval(context, item.id);
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.ctaRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImgPlaceholder(),
                        )
                      : const _ImgPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + delete icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _dispatchCartRemoval(context, item.id),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Variation chip
                    GestureDetector(
                      onTap: canChangeVariation
                          ? () async {
                              final currentIdx =
                                  allVariations.indexWhere(
                                      (v) => v.type == item.variation.type);
                              final cartBloc = context.read<CartBloc>();
                              final picked = await showVariationPickerSheet(
                                context,
                                productName: product?.name ?? '',
                                variations: allVariations,
                                initialIndex:
                                    currentIdx >= 0 ? currentIdx : 0,
                                confirmLabel: 'Update',
                              );
                              if (picked != null &&
                                  picked.type != item.variation.type) {
                                cartBloc.add(CartItemQuantityUpdated(
                                  cartId: item.id,
                                  newQuantity: item.quantity,
                                  variation: picked,
                                ));
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primaryGreen
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.variation.type,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            if (canChangeVariation) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 13,
                                  color: AppColors.primaryGreen),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Price + stepper row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            if (item.quantity > 1)
                              Text(
                                '₹${item.lineTotal.toStringAsFixed(0)} total',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        _QtyStepper(item: item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBg,
      child:
          const Icon(Icons.grass, size: 32, color: AppColors.borderMedium),
    );
  }
}

// ── Qty stepper ───────────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.item});
  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = _maxCartQuantityForItem(item);
    final canIncrement = item.quantity < maxQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: item.quantity <= 1
                ? Icons.delete_outline
                : Icons.remove,
            onTap: () {
              if (item.quantity <= 1) {
                _dispatchCartRemoval(context, item.id);
              } else {
                context.read<CartBloc>().add(CartItemQuantityUpdated(
                      cartId: item.id,
                      newQuantity: item.quantity - 1,
                      variation: item.variation,
                    ));
              }
            },
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: canIncrement
                ? () => context.read<CartBloc>().add(CartItemQuantityUpdated(
                      cartId: item.id,
                      newQuantity: item.quantity + 1,
                      variation: item.variation,
                    ))
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Icon(icon, size: 16, color: AppColors.textWhite),
        ),
      ),
    );
  }
}

int _maxCartQuantityForItem(CartItemModel item) {
  final limits = <int>[];
  if (item.variation.stock > 0) {
    limits.add(item.variation.stock);
  }

  final productLimit = item.product?.maximumCartQuantity ?? 0;
  if (productLimit > 0) {
    limits.add(productLimit);
  }

  if (limits.isEmpty) {
    return 1 << 30;
  }

  final limit = limits.reduce((a, b) => a < b ? a : b);
  return limit < item.quantity ? item.quantity : limit;
}

// ── Price details card ────────────────────────────────────────────────────────

class _PriceDetailsCard extends StatelessWidget {
  const _PriceDetailsCard(
      {required this.state, required this.couponCtrl});
  final CartLoaded state;
  final TextEditingController couponCtrl;

  @override
  Widget build(BuildContext context) {
    final itemCount =
        state.items.fold<int>(0, (sum, i) => sum + i.quantity);

    // Tax is computed from cart weight — no API call needed.
    final tax = CheckoutRepository.tax(state.subtotal, state.totalWeight);
    final estimatedTotal = state.subtotal + tax;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'PRICE DETAILS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PriceRow(
                  label:
                      'Subtotal ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                  value: '₹${state.subtotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 10),
                // Tax: 5% when total weight < 25 kg, else ₹0
                _PriceRow(
                  label: state.totalWeight < 25
                      ? 'Tax (5% · ${state.totalWeight.toStringAsFixed(1)} kg)'
                      : 'Tax (weight ≥ 25 kg)',
                  value: tax > 0
                      ? '(+) ₹${tax.toStringAsFixed(0)}'
                      : '₹0',
                ),
                const SizedBox(height: 10),
                // Delivery requires an address — calculated on the checkout page.
                _PriceRow(
                  label: 'Delivery',
                  value: 'At checkout',
                  valueColor: AppColors.textSecondary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      height: 1, color: AppColors.borderLight),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal + Tax',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    Text(
                      '₹${estimatedTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '+ delivery at checkout',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponCtrl,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Coupon or gift card code',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint),
                      prefixIcon: const Icon(
                          Icons.local_offer_outlined,
                          size: 18,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.scaffoldBg,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon feature coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    minimumSize:
                        const Size(0, AppDimensions.buttonHeight),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
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
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Sticky checkout bar ───────────────────────────────────────────────────────

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.state});
  final CartLoaded state;

  @override
  Widget build(BuildContext context) {
    final tax = CheckoutRepository.tax(state.subtotal, state.totalWeight);
    final estimatedTotal = state.subtotal + tax;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            final cartBloc = context.read<CartBloc>();
            final customerBloc = context.read<CustomerBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutPage(
                  cartBloc: cartBloc,
                  customerBloc: customerBloc,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proceed to Checkout',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${estimatedTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty cart ────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the Shop to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
            const Icon(Icons.wifi_off,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Retry',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
