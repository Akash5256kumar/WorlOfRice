import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/pages/cart_tab.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../data/repositories/product_detail_repository.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_detail_event.dart';
import '../bloc/product_detail_state.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailBloc()..add(ProductDetailStarted(slug)),
      child: _Body(slug: slug),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  const _Body({required this.slug});
  final String slug;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int _varIdx = 0;
  int _qty = 1;
  int _imgIdx = 0;
  bool _isRefreshing = false;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Pull-to-refresh: re-fetches product detail and cart state.
  /// Guards against concurrent calls so the indicator never duplicates.
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      context
          .read<ProductDetailBloc>()
          .add(ProductDetailStarted(widget.slug));
      context.read<CartBloc>().add(const CartStarted());
      // Hold the RefreshIndicator open until the bloc settles.
      await context.read<ProductDetailBloc>().stream.firstWhere(
            (s) => s is ProductDetailLoaded || s is ProductDetailError,
          );
    } catch (_) {
      // Stream closed or widget unmounted — safe to ignore.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        if (state is ProductDetailLoading || state is ProductDetailInitial) {
          return const _LoadingView();
        }
        if (state is ProductDetailError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<ProductDetailBloc>()
                .add(ProductDetailStarted(widget.slug)),
          );
        }
        if (state is! ProductDetailLoaded) return const SizedBox.shrink();

        final detail = state.detail;
        final product = detail.product;
        final variations = product.variations;
        final safeIdx =
            _varIdx < variations.length ? _varIdx : 0;
        final selected =
            variations.isNotEmpty ? variations[safeIdx] : null;
        final images = product.imagesFullUrl.isNotEmpty
            ? product.imagesFullUrl
            : product.imageFullUrl != null
                ? [product.imageFullUrl!]
                : <String>[];

        // Discount / MRP — sourced from per-variation fields.
        // Recomputed whenever the selected variation changes.
        final mrp = selected?.hasDiscount == true ? selected!.actualPrice : null;
        final discountPct = selected?.discountPercentage ?? 0.0;
        final savings = selected?.savings ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          // ── Sticky bottom CTA bar ──────────────────────────────────────────
          bottomNavigationBar: _StickyBar(
            productId: product.id,
            selected: selected,
            quantity: _qty,
            onQtyChanged: (q) => setState(() => _qty = q),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primaryGreen,
            backgroundColor: Colors.white,
            displacement: 60,
            child: CustomScrollView(
            // BouncingScrollPhysics gives iOS rubber-banding;
            // AlwaysScrollableScrollPhysics ensures pull-to-refresh
            // triggers even when content is shorter than the viewport.
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Hero image carousel ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroSection(
                  images: images,
                  pageCtrl: _pageCtrl,
                  imgIdx: _imgIdx,
                  onPageChanged: (i) => setState(() => _imgIdx = i),
                  discount: discountPct,
                ),
              ),

              // ── White content card ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ContentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store + delivery badge
                      _StoreRow(
                        storeName: detail.storeName,
                        deliveryTime: detail.storeDeliveryTime,
                        inStock: selected?.inStock ?? false,
                      ),
                      const SizedBox(height: 10),

                      // Product name
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkBrown,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rating row
                      if (product.avgRating > 0)
                        _RatingRow(
                          rating: product.avgRating,
                          count: product.ratingCount,
                          orderCount: detail.orderCount,
                        ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 14),

                      // Price block
                      if (selected != null)
                        _PriceBlock(
                          price: selected.price,
                          mrp: mrp,
                          discountPct: discountPct,
                          savings: savings,
                          variationType: selected.type,
                        ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),

                      // Variant selector
                      if (variations.length > 1) ...[
                        Text(
                          'Select Pack Size',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _VariantChips(
                          variations: variations,
                          selectedIndex: safeIdx,
                          onSelect: (i) => setState(() {
                            _varIdx = i;
                            _qty = 1;
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                            height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 16),
                      ],

                      // Highlights
                      _HighlightsRow(
                          deliveryTime: detail.storeDeliveryTime),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),

                      // Delivery info card
                      _DeliveryCard(
                          deliveryTime: detail.storeDeliveryTime),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),

                      // Description
                      if (product.description.isNotEmpty)
                        _DescriptionSection(text: product.description),

                      // Tags
                      if (detail.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _TagsRow(tags: detail.tags),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Related products ──────────────────────────────────────────
              if (detail.relatedItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _RelatedSection(items: detail.relatedItems),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),      // closes CustomScrollView
        ),        // closes RefreshIndicator
        );
      },
    );
  }
}

// ── Loading / Error ───────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          const Center(
            child:
                CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _BackBtn()),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _BackBtn(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary)),
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
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppColors.darkBrown),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero image carousel ───────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.images,
    required this.pageCtrl,
    required this.imgIdx,
    required this.onPageChanged,
    required this.discount,
  });

  final List<String> images;
  final PageController pageCtrl;
  final int imgIdx;
  final ValueChanged<int> onPageChanged;
  final double discount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image area
        Container(
          height: (MediaQuery.of(context).size.height * 0.42).clamp(200.0, 320.0),
          color: Colors.white,
          child: images.isNotEmpty
              ? PageView.builder(
                  controller: pageCtrl,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _ImgPlaceholder(),
                  ),
                )
              : const _ImgPlaceholder(),
        ),

        // Bottom gradient for smooth transition into white card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  AppColors.scaffoldBg.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        // Back button overlay
        Positioned(top: 0, left: 0, right: 0, child: _BackBtn()),

        // Discount badge
        if (discount > 0)
          Positioned(
            top: 56,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ctaRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${discount.toStringAsFixed(0)}% OFF',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Page dots
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final isActive = i == imgIdx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0E8),
      child:
          const Icon(Icons.grass, size: 80, color: AppColors.borderMedium),
    );
  }
}

// ── White content card ────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: child,
    );
  }
}

// ── Store row ─────────────────────────────────────────────────────────────────

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.storeName,
    required this.deliveryTime,
    required this.inStock,
  });

  final String storeName;
  final String deliveryTime;
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (storeName.isNotEmpty) ...[
          const Icon(Icons.store_outlined,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            storeName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
        ],
        // Stock badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: inStock
                ? AppColors.primaryGreen
                : AppColors.ctaRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            inStock ? 'In Stock' : 'Out of Stock',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        // Delivery time chip
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F3),
            border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.primaryGreen),
              const SizedBox(width: 3),
              Text(
                deliveryTime,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.rating,
    required this.count,
    required this.orderCount,
  });

  final double rating;
  final int count;
  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 13, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Text(
            '$count ratings',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        if (orderCount > 0) ...[
          const SizedBox(width: 8),
          Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.borderMedium,
                shape: BoxShape.circle,
              )),
          const SizedBox(width: 8),
          Text(
            '$orderCount orders',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Price block ───────────────────────────────────────────────────────────────

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.price,
    required this.mrp,
    required this.discountPct,
    required this.savings,
    required this.variationType,
  });

  final double price;
  final double? mrp;
  final double discountPct;
  final double savings;
  final String variationType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            if (mrp != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'MRP ₹${mrp!.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${discountPct.toStringAsFixed(0)}% off',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctaRed,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (savings > 0) ...[
          const SizedBox(height: 4),
          Text(
            'You save ₹${savings.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF388E3C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'for $variationType',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Variant chips ─────────────────────────────────────────────────────────────

class _VariantChips extends StatelessWidget {
  const _VariantChips({
    required this.variations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<VariationModel> variations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(variations.length, (i) {
        final v = variations[i];
        final isSelected = i == selectedIndex;
        final isOOS = !v.inStock;
        final textColor = isSelected ? Colors.white : AppColors.darkBrown;
        final subColor = isSelected
            ? Colors.white.withValues(alpha: 0.8)
            : AppColors.textHint;

        return GestureDetector(
          onTap: isOOS ? null : () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryGreen
                  : isOOS
                      ? const Color(0xFFF5F5F5)
                      : Colors.white,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryGreen
                    : isOOS
                        ? AppColors.borderLight
                        : AppColors.borderMedium,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pack size label
                Text(
                  v.type,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOOS ? AppColors.textHint : textColor,
                    decoration: isOOS
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                if (isOOS)
                  Text(
                    'Out of stock',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  )
                else ...[
                  // Selling price
                  Text(
                    '₹${v.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.primaryGreen,
                    ),
                  ),
                  // Strike-through original price
                  if (v.hasDiscount) ...[
                    Text(
                      '₹${v.actualPrice!.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: subColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: subColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.ctaRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${v.discountPercentage.toStringAsFixed(0)}% off',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.ctaRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Product highlights ────────────────────────────────────────────────────────

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.deliveryTime});
  final String deliveryTime;

  static const _items = [
    (
      icon: Icons.verified_outlined,
      label: '100% Quality\nAssured',
      color: Color(0xFF1A5C38)
    ),
    (
      icon: Icons.eco_outlined,
      label: 'Farm Fresh\nProduct',
      color: Color(0xFF2E7D32)
    ),
    (
      icon: Icons.inventory_2_outlined,
      label: 'Secure\nPackaging',
      color: Color(0xFF1565C0)
    ),
    (
      icon: Icons.local_shipping_outlined,
      label: 'Fast\nDelivery',
      color: Color(0xFFE65100)
    ),
    (
      icon: Icons.assignment_return_outlined,
      label: 'Easy\nReturns',
      color: Color(0xFF6A1B9A)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items.map((h) {
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: h.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: h.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(h.icon, size: 24, color: h.color),
                const SizedBox(height: 6),
                Text(
                  h.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Delivery card ─────────────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.deliveryTime});
  final String deliveryTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _DeliveryRow(
            icon: Icons.local_shipping_outlined,
            title: 'Estimated Delivery',
            subtitle: deliveryTime,
            iconColor: AppColors.primaryGreen,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFD0E8D8)),
          const SizedBox(height: 10),
          _DeliveryRow(
            icon: Icons.location_on_outlined,
            title: 'Delivery Area',
            subtitle: 'Serviceable in select areas',
            iconColor: AppColors.accentGold,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFD0E8D8)),
          const SizedBox(height: 10),
          _DeliveryRow(
            icon: Icons.currency_rupee_rounded,
            title: 'Delivery Charges',
            subtitle: 'Calculated at checkout based on distance',
            iconColor: AppColors.ctaRed,
          ),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.text});
  final String text;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Description',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (widget.text.length > 120) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Read less' : 'Read more',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tags row ──────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        AppColors.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Sticky bottom CTA bar ─────────────────────────────────────────────────────

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.productId,
    required this.selected,
    required this.quantity,
    required this.onQtyChanged,
  });

  final int productId;
  final VariationModel? selected;
  final int quantity;
  final ValueChanged<int> onQtyChanged;

  CartItemModel? _findCartItem(List<CartItemModel> items) {
    if (selected == null) return null;
    for (final item in items) {
      if (item.itemId == productId &&
          item.variation.type == selected!.type) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (selected == null) return const SizedBox.shrink();

    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, cartState) {
        final cartItems = cartState is CartLoaded ? cartState.items : <CartItemModel>[];
        final cartItem = _findCartItem(cartItems);
        final inCart = cartItem != null;
        final displayQty = inCart ? cartItem.quantity : quantity;
        final total = selected!.price * displayQty;
        final isOOS = !selected!.inStock;
        final totalCartItems =
            cartState is CartLoaded ? cartState.totalItems : 0;

        void goToCart() {
          final cartBloc = ctx.read<CartBloc>();
          CustomerBloc? custBloc;
          try {
            custBloc = ctx.read<CustomerBloc>();
          } catch (_) {}
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: cartBloc),
                  if (custBloc != null)
                    BlocProvider.value(value: custBloc),
                ],
                child: const Scaffold(
                  backgroundColor: Color(0xFFF5F0E8),
                  body: CartTab(),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: inCart
              ? _InCartBar(
                  cartItem: cartItem,
                  total: total,
                  totalCartItems: totalCartItems,
                  onViewCart: goToCart,
                )
              : _AddToCartBar(
                  selected: selected!,
                  quantity: quantity,
                  total: total,
                  isOOS: isOOS,
                  onQtyChanged: onQtyChanged,
                  onAdd: () {
                    ctx.read<CartBloc>().add(CartItemAdded(
                          itemId: productId,
                          variation: selected!,
                          quantity: quantity,
                        ));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${selected!.type} × $quantity added to cart!'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.selected,
    required this.quantity,
    required this.total,
    required this.isOOS,
    required this.onQtyChanged,
    required this.onAdd,
  });

  final VariationModel selected;
  final int quantity;
  final double total;
  final bool isOOS;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Qty stepper
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderMedium),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: Icons.remove,
                enabled: quantity > 1 && !isOOS,
                onTap: () => onQtyChanged(max(1, quantity - 1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                enabled: !isOOS,
                onTap: () => onQtyChanged(quantity + 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Total + button
        Expanded(
          child: ElevatedButton(
            onPressed: isOOS ? null : onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.borderMedium,
              elevation: 0,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isOOS
                ? Text('Out of Stock',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ADD TO CART',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)} total',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _InCartBar extends StatelessWidget {
  const _InCartBar({
    required this.cartItem,
    required this.total,
    required this.totalCartItems,
    required this.onViewCart,
  });

  final CartItemModel cartItem;
  final double total;
  final int totalCartItems;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left: quantity stepper for this product ───────────────────────
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text('In Cart',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CartStepBtn(
                    icon: cartItem.quantity <= 1
                        ? Icons.delete_outline
                        : Icons.remove,
                    onTap: () {
                      if (cartItem.quantity <= 1) {
                        context.read<CartBloc>().add(
                            CartItemRemoved(cartId: cartItem.id));
                      } else {
                        context.read<CartBloc>().add(
                              CartItemQuantityUpdated(
                                cartId: cartItem.id,
                                newQuantity: cartItem.quantity - 1,
                                variation: cartItem.variation,
                              ),
                            );
                      }
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${cartItem.quantity}',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  _CartStepBtn(
                    icon: Icons.add,
                    onTap: () {
                      context.read<CartBloc>().add(
                            CartItemQuantityUpdated(
                              cartId: cartItem.id,
                              newQuantity: cartItem.quantity + 1,
                              variation: cartItem.variation,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // ── Right: View Cart CTA ──────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: onViewCart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5C38), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCartItems ${totalCartItems == 1 ? 'item' : 'items'} in cart',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                      Text(
                        'VIEW CART',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon,
      required this.enabled,
      required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? AppColors.darkBrown
                : AppColors.borderMedium),
      ),
    );
  }
}

class _CartStepBtn extends StatelessWidget {
  const _CartStepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// ── Related products section ──────────────────────────────────────────────────

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0E8),
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMILAR PRODUCTS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You May Also Like',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) =>
                  _RelatedCard(product: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatefulWidget {
  const _RelatedCard({required this.product});
  final dynamic product;

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final variation = widget.product.defaultVariation;
    final price = variation?.price ?? widget.product.minPrice;
    final inStock = variation?.inStock ?? false;

    return GestureDetector(
      onTap: () {
        final slug = widget.product.slug as String;
        if (slug.isEmpty) return;
        final cartBloc = context.read<CartBloc>();
        CustomerBloc? customerBloc;
        try {
          customerBloc = context.read<CustomerBloc>();
        } catch (_) {}
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cartBloc),
                if (customerBloc != null)
                  BlocProvider.value(value: customerBloc),
              ],
              child: ProductDetailPage(slug: slug),
            ),
          ),
        );
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — padded container so the product never touches the card edge
            Container(
              height: 130,
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: widget.product.imageFullUrl != null
                  ? Image.network(
                      widget.product.imageFullUrl as String,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const _RelatedImgPlaceholder(),
                    )
                  : const _RelatedImgPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (variation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        variation.type as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '₹${(price as double).toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Add to cart
                    BlocBuilder<CartBloc, CartState>(
                      builder: (ctx, cartState) {
                        final inCartItems = cartState is CartLoaded
                            ? cartState.items
                            : <CartItemModel>[];
                        final cartItem = inCartItems
                            .cast<CartItemModel?>()
                            .firstWhere(
                              (ci) =>
                                  ci!.itemId ==
                                      (widget.product.id as int) &&
                                  ci.variation.type ==
                                      (variation?.type ?? ''),
                              orElse: () => null,
                            );

                        if (cartItem != null) {
                          return _RelatedCartStepper(
                              cartItem: cartItem);
                        }

                        return Row(
                          children: [
                            _miniBtn('-',
                                _qty > 1 && inStock
                                    ? () => setState(() => _qty--)
                                    : null),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Text(
                                '$_qty',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            _miniBtn('+',
                                inStock
                                    ? () => setState(() => _qty++)
                                    : null),
                            const Spacer(),
                            if (inStock)
                              GestureDetector(
                                onTap: () {
                                  ctx.read<CartBloc>().add(
                                        CartItemAdded(
                                          itemId:
                                              widget.product.id as int,
                                          variation: variation,
                                          quantity: _qty,
                                        ),
                                      );
                                }
                                    ,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Add',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'Out of\nstock',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.ctaRed,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(
              color: onTap != null
                  ? AppColors.borderMedium
                  : AppColors.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: onTap != null
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _RelatedCartStepper extends StatelessWidget {
  const _RelatedCartStepper({required this.cartItem});
  final CartItemModel cartItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (cartItem.quantity <= 1) {
                context
                    .read<CartBloc>()
                    .add(CartItemRemoved(cartId: cartItem.id));
              } else {
                context.read<CartBloc>().add(
                      CartItemQuantityUpdated(
                        cartId: cartItem.id,
                        newQuantity: cartItem.quantity - 1,
                        variation: cartItem.variation,
                      ),
                    );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              child: Icon(
                cartItem.quantity <= 1
                    ? Icons.delete_outline
                    : Icons.remove,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '${cartItem.quantity}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<CartBloc>().add(
                    CartItemQuantityUpdated(
                      cartId: cartItem.id,
                      newQuantity: cartItem.quantity + 1,
                      variation: cartItem.variation,
                    ),
                  );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child:
                  Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedImgPlaceholder extends StatelessWidget {
  const _RelatedImgPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0E8),
      child: const Icon(Icons.grass,
          size: 48, color: AppColors.borderMedium),
    );
  }
}
