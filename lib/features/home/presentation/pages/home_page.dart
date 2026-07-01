import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/variation_picker_sheet.dart';
import '../../../cart/data/repositories/cart_repository.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/pages/cart_tab.dart';
import '../../../customer/data/repositories/customer_repository.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/bloc/customer_event.dart';
import '../../../customer/presentation/pages/account_tab.dart';
import '../../../product_detail/presentation/pages/product_detail_page.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/home_repository.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  // Shop tab's HomeBloc is owned here so the home tab can dispatch
  // HomeCategorySelected to it before switching to the shop tab.
  late final HomeBloc _shopBloc;

  @override
  void initState() {
    super.initState();
    _shopBloc = HomeBloc(repository: HomeRepository())..add(const HomeStarted());
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _shopBloc.close();
    super.dispose();
  }

  /// Selects [categoryId] in the shop tab then navigates to it.
  void _openShopWithCategory(int? categoryId) {
    _shopBloc.add(HomeCategorySelected(categoryId));
    setState(() => _navIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CartBloc(repository: CartRepository())..add(const CartStarted()),
        ),
        BlocProvider(
          create: (_) => CustomerBloc(repository: CustomerRepository())
            ..add(const CustomerStarted()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: IndexedStack(
          index: _navIndex,
          children: [
            // Home tab has its own HomeBloc (for hero/featured display).
            BlocProvider(
              create: (_) => HomeBloc(repository: HomeRepository())..add(const HomeStarted()),
              child: _HomeTab(
                onShopTap: () => setState(() => _navIndex = 1),
                onCartTap: () => setState(() => _navIndex = 2),
                onAccountTap: () => setState(() => _navIndex = 3),
                onCategoryTap: _openShopWithCategory,
              ),
            ),
            // Shop tab uses the shared _shopBloc so category selection works.
            BlocProvider.value(
              value: _shopBloc,
              child: const _ShopTab(),
            ),
            const CartTab(),
            // Blog tab — commented out, not required
            // const _PlaceholderTab(label: AppStrings.navBlog),
            const AccountTab(),
          ],
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (ctx, cartState) => AppBottomNav(
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
            cartItemCount: cartState is CartLoaded ? cartState.totalItems : 0,
          ),
        ),
      ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.onShopTap,
    required this.onCartTap,
    required this.onAccountTap,
    required this.onCategoryTap,
  });

  final VoidCallback onShopTap;
  final VoidCallback onCartTap;
  final VoidCallback onAccountTap;
  final ValueChanged<int?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _HomeHeader(onCartTap: onCartTap, onAccountTap: onAccountTap),
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  );
                }
                if (state is HomeError) {
                  return _ErrorBody(
                    message: state.message,
                    onRetry: () => context.read<HomeBloc>().add(const HomeStarted()),
                  );
                }
                if (state is HomeLoaded) {
                  return _HomeScrollBody(
                    state: state,
                    onShopTap: onShopTap,
                    onCategoryTap: onCategoryTap,
                  );
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

// ── Sticky header ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onCartTap, required this.onAccountTap});

  final VoidCallback onCartTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
      child: Row(
        children: [
          const AppLogo(size: 48),
          const Spacer(),
          // Favorites button — temporarily disabled
          // _HeaderIconButton(icon: Icons.favorite_border, onTap: () {}),
          // const SizedBox(width: AppDimensions.spaceXS),
          // Cart icon with badge
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final count = state is CartLoaded ? state.totalItems : 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderIconButton(icon: Icons.shopping_cart_outlined, onTap: onCartTap, iconSize: 26),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.ctaRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Account icon removed from header — accessible via bottom nav tab
          // const SizedBox(width: AppDimensions.spaceXS),
          // _HeaderIconButton(icon: Icons.person_outline, onTap: onAccountTap),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.iconSize = AppDimensions.iconSizeM,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: iconSize, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Scrollable body ───────────────────────────────────────────────────────────

class _HomeScrollBody extends StatelessWidget {
  const _HomeScrollBody({
    required this.state,
    required this.onShopTap,
    required this.onCategoryTap,
  });

  final HomeLoaded state;
  final VoidCallback onShopTap;
  final ValueChanged<int?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final featured = products.take(6).toList();
    final trending = state.trendingProducts;

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      onRefresh: () async {
        context.read<HomeBloc>().add(const HomeStarted());
        await context.read<HomeBloc>().stream.firstWhere(
              (s) => s is HomeLoaded || s is HomeError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-scrolling hero carousel
            _HeroBannerCarousel(onCtaTap: onShopTap),
            // Special offers strip
            const _SpecialOffersStrip(),
            // Shop by Category (icon bubbles)
            _HomeCategorySection(
              categories: state.categories,
              onShopTap: onShopTap,
              onCategoryTap: onCategoryTap,
            ),
            // Best Sellers grid
            _BestSellerSection(products: featured, isLoading: state.isLoadingMore, onShopTap: onShopTap),
            // Trending horizontal scroll
            if (trending.isNotEmpty) _TrendingSection(products: trending),
            // Why Choose Us
            const _WhyChooseUsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Auto-scrolling hero banner carousel ──────────────────────────────────────

class _HeroBannerCarousel extends StatefulWidget {
  const _HeroBannerCarousel({required this.onCtaTap});

  final VoidCallback onCtaTap;

  @override
  State<_HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<_HeroBannerCarousel> {
  final _ctrl = PageController();
  int _current = 0;
  Timer? _timer;

  static const _banners = [
    AppAssets.banner1,
    AppAssets.banner2,
    AppAssets.banner3,
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carouselHeight = (MediaQuery.of(context).size.height * 0.26).clamp(130.0, 210.0);
    return SizedBox(
      height: carouselHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: widget.onCtaTap,
              child: Image.asset(
                _banners[i],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dot indicators
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Special offers strip ──────────────────────────────────────────────────────

class _SpecialOffersStrip extends StatelessWidget {
  const _SpecialOffersStrip();

  static const _offers = [
    (
      icon: Icons.local_shipping_outlined,
      label: 'Free Delivery',
      sub: 'On first order',
      color: Color(0xFF1A5C38)
    ),
    (
      icon: Icons.verified_outlined,
      label: '100% Organic',
      sub: 'Certified fresh',
      color: Color(0xFF1565C0)
    ),
    (
      icon: Icons.replay_rounded,
      label: 'Easy Returns',
      sub: '7-day policy',
      color: Color(0xFF6A1B9A)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _offers.map((o) {
            return Container(
              width: 130,
              margin: const EdgeInsets.only(right: 10, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: o.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: o.color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: o.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(o.icon, size: 18, color: o.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.label,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: o.color)),
                        Text(o.sub,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Home category section (icon bubbles) ──────────────────────────────────────

class _HomeCategorySection extends StatelessWidget {
  const _HomeCategorySection({
    required this.categories,
    required this.onShopTap,
    required this.onCategoryTap,
  });

  final List<CategoryModel> categories;
  final VoidCallback onShopTap;
  final ValueChanged<int?> onCategoryTap;

  static const _catColors = [
    Color(0xFF1A5C38),
    Color(0xFFE65100),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF2C1F0E),
  ];

  static const _catIcons = [
    Icons.grain,
    Icons.eco_outlined,
    Icons.spa_outlined,
    Icons.local_florist_outlined,
    Icons.grass_outlined,
    Icons.inventory_2_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shop by Category',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown)),
                ],
              ),
              GestureDetector(
                onTap: onShopTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text('View All',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final cat = categories[i];
                final color = _catColors[i % _catColors.length];
                final icon = _catIcons[i % _catIcons.length];
                return GestureDetector(
                  onTap: () => onCategoryTap(cat.id),
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 12, bottom: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: color.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: Icon(icon, size: 26, color: color),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Categories ────────────────────────────────────────────────────────────────

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  // Index 0 = "All", 1..n = categories in order.
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(_CategoriesSection old) {
    super.didUpdateWidget(old);
    if (old.categories.length != widget.categories.length) {
      _rebuildKeys();
    }
    if (old.selectedId != widget.selectedId) {
      _scrollToSelected();
    }
  }

  void _rebuildKeys() {
    _keys = List.generate(
      widget.categories.length + 1, // +1 for "All"
      (_) => GlobalKey(),
    );
  }

  /// Scrolls the selected pill into the centre of the viewport
  /// after the current frame completes.
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = widget.selectedId == null
          ? 0
          : widget.categories.indexWhere((c) => c.id == widget.selectedId) + 1;
      if (idx < 0 || idx >= _keys.length) return;
      final ctx = _keys[idx].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5, // centre the pill in the scroll view
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceL,
        AppDimensions.spaceXXL,
        0,                    // no right — scroll view goes edge-to-edge
        AppDimensions.spaceL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spaceL),
            child: Text(
              AppStrings.homeCategories,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeXL,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppDimensions.spaceL),
            child: Row(
              children: [
                _CategoryPill(
                  key: _keys[0],
                  label: 'All',
                  isActive: widget.selectedId == null,
                  onTap: () => widget.onSelect(null),
                ),
                ...List.generate(widget.categories.length, (i) {
                  final cat = widget.categories[i];
                  return _CategoryPill(
                    key: _keys[i + 1],
                    label: cat.name,
                    isActive: cat.id == widget.selectedId,
                    onTap: () => widget.onSelect(cat.id),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spaceS),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXL,
            vertical: AppDimensions.spaceS,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : AppColors.cardBg,
            border: Border.all(
              color: isActive ? AppColors.primaryGreen : AppColors.borderMedium,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.textWhite : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Best Sellers grid ─────────────────────────────────────────────────────────

class _BestSellerSection extends StatelessWidget {
  const _BestSellerSection({
    required this.products,
    required this.isLoading,
    required this.onShopTap,
  });

  final List<ProductModel> products;
  final bool isLoading;
  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best Sellers',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown)),
                  Text('Top picks from our collection',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              GestureDetector(
                onTap: onShopTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text('View All',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen))
          else if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No products available',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.70,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.all(4),
                child: _TappableProductCard(product: products[i]),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Trending Now horizontal scroll ────────────────────────────────────────────

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Trending Now',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBrown)),
                        const SizedBox(width: 4),
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Text('Most ordered this week',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => SizedBox(
                width: 160,
                child: _TappableProductCard(product: products[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableProductCard extends StatelessWidget {
  const _TappableProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (product.slug.isEmpty) return;
        final cartBloc = context.read<CartBloc>();
        final customerBloc = context.read<CustomerBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cartBloc),
                BlocProvider.value(value: customerBloc),
              ],
              child: ProductDetailPage(slug: product.slug),
            ),
          ),
        );
      },
      child: _ProductCard(product: product),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final variation = product.defaultVariation;
    final price = variation?.price ?? product.minPrice;

    // Use variation-level discount fields when available
    final double? mrp;
    final int? discountPct;
    if (variation != null && variation.hasDiscount) {
      mrp = variation.actualPrice;
      discountPct = variation.discountPercentage.round();
    } else if (product.discount > 0) {
      if (product.discountType == 'percent') {
        discountPct = product.discount.round();
        mrp = price * 100 / (100 - product.discount);
      } else {
        final m = price + product.discount;
        discountPct = m > 0 ? (product.discount / m * 100).round() : null;
        mrp = m;
      }
    } else {
      mrp = null;
      discountPct = null;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE8E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image — 62% of card height, cream bg, no fixed pixels ──────────
          Expanded(
            flex: 62,
            child: Stack(
              children: [
                Positioned.fill(
                  left: 6, top: 6, right: 6, bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: const Color(0xFFF5F0E8),
                      child: _ProductImage(
                          imageUrl: product.imageFullUrl, fit: BoxFit.contain),
                    ),
                  ),
                ),
                // Discount badge
                if (discountPct != null && discountPct > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.ctaRed,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('$discountPct% OFF',
                          style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                // Rating badge
                if (product.avgRating > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 8, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(product.avgRating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Info — 38% of card height ──────────────────────────────────────
          Expanded(
            flex: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name (single line — variant shown as badge on image)
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  // Price + Add button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            if (mrp != null)
                              Text(
                                '₹${mrp.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _AddButton(
                        onTap: () async {
                          if (product.variations.isEmpty) return;
                          final variations = product.variations;
                          final cartBloc = context.read<CartBloc>();
                          if (variations.length == 1) {
                            cartBloc.add(CartItemAdded(
                              itemId: product.id,
                              variation: variations.first,
                              quantity: 1,
                            ));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart!'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                            return;
                          }
                          final defaultIdx = variation != null
                              ? variations.indexOf(variation)
                              : 0;
                          if (!context.mounted) return;
                          final picked = await showVariationPickerSheet(
                            context,
                            productName: product.name,
                            variations: variations,
                            initialIndex: defaultIdx < 0 ? 0 : defaultIdx,
                          );
                          if (picked != null && context.mounted) {
                            cartBloc.add(CartItemAdded(
                              itemId: product.id,
                              variation: picked,
                              quantity: 1,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${picked.type} added!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl, this.fit = BoxFit.contain});

  final String? imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const _PlaceholderImage();
        },
        errorBuilder: (_, __, ___) => const _PlaceholderImage(),
      );
    }
    return const _PlaceholderImage();
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
        ),
      ),
      child: const Icon(Icons.grass, size: 48, color: Color(0xFFBBBBBB)),
    );
  }
}

// _Badge and _SizeBadge removed — replaced by inline badges in _ProductCard

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded,
            size: 20, color: Colors.white),
      ),
    );
  }
}

// ── Why Choose Us ─────────────────────────────────────────────────────────────

class _WhyChooseUsSection extends StatelessWidget {
  const _WhyChooseUsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.homeWhyChooseUs,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text('Why millions choose us',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                  child: _WhyCard(
                      icon: Icons.military_tech_outlined,
                      title: 'Quality',
                      subtitle: 'Premium grains',
                      color: Color(0xFF1A5C38))),
              SizedBox(width: 10),
              Expanded(
                  child: _WhyCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Variety',
                      subtitle: '150+ types',
                      color: Color(0xFF1565C0))),
              SizedBox(width: 10),
              Expanded(
                  child: _WhyCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Delivery',
                      subtitle: 'Fast & fresh',
                      color: Color(0xFFE65100))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                  child: _WhyCard(
                      icon: Icons.eco_outlined,
                      title: 'Organic',
                      subtitle: 'Farm sourced',
                      color: Color(0xFF2E7D32))),
              SizedBox(width: 10),
              Expanded(
                  child: _WhyCard(
                      icon: Icons.verified_outlined,
                      title: 'Certified',
                      subtitle: 'FSSAI approved',
                      color: Color(0xFF6A1B9A))),
              SizedBox(width: 10),
              Expanded(
                  child: _WhyCard(
                      icon: Icons.support_agent_outlined,
                      title: 'Support',
                      subtitle: '24/7 help',
                      color: Color(0xFF00838F))),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
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

  bool get _isNoInternet => message.toLowerCase().contains('no internet');
  bool get _isTimeout => message.toLowerCase().contains('timed out');

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    if (_isNoInternet) {
      icon = Icons.wifi_off_rounded;
      title = 'No Internet Connection';
    } else if (_isTimeout) {
      icon = Icons.timer_off_rounded;
      title = 'Connection Timed Out';
    } else {
      icon = Icons.cloud_off_rounded;
      title = 'Something Went Wrong';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXXL),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shop tab ──────────────────────────────────────────────────────────────────

class _ShopTab extends StatefulWidget {
  const _ShopTab();

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  Timer? _debounce;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      context.read<HomeBloc>().add(const HomeNextPageRequested());
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      context.read<HomeBloc>().add(const HomeStarted());
      await context.read<HomeBloc>().stream.firstWhere(
            (s) => s is HomeLoaded || s is HomeError,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<HomeBloc>().add(HomeSearchChanged(query.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Search header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceL,
              AppDimensions.spaceM,
              AppDimensions.spaceL,
              AppDimensions.spaceM,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search rice varieties…',
                hintStyle: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _searchCtrl,
                  builder: (_, val, __) => val.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            context.read<HomeBloc>().add(const HomeSearchChanged(''));
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                filled: true,
                fillColor: AppColors.scaffoldBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoaded) {
                  return _ShopScrollBody(
                    state: state,
                    scrollCtrl: _scrollCtrl,
                    onRefresh: _onRefresh,
                  );
                }
                if (state is HomeError) {
                  return _ErrorBody(
                    message: state.message,
                    onRetry: () => context.read<HomeBloc>().add(const HomeStarted()),
                  );
                }
                // HomeLoading or HomeInitial — show spinner
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopScrollBody extends StatelessWidget {
  const _ShopScrollBody({
    required this.state,
    required this.scrollCtrl,
    required this.onRefresh,
  });

  final HomeLoaded state;
  final ScrollController scrollCtrl;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: CustomScrollView(
      controller: scrollCtrl,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Category pills
        SliverToBoxAdapter(
          child: _CategoriesSection(
            categories: state.categories,
            selectedId: state.selectedCategoryId,
            onSelect: (id) => context.read<HomeBloc>().add(HomeCategorySelected(id)),
          ),
        ),
        // Products count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceL, 0, AppDimensions.spaceL, AppDimensions.spaceS,
            ),
            child: Text(
              '${state.totalSize} products',
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        // Products grid
        if (state.products.isEmpty && !state.isLoadingMore)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    state.searchQuery.isNotEmpty
                        ? 'No results for "${state.searchQuery}"'
                        : 'No products found',
                    style: GoogleFonts.poppins(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.spaceS,
                mainAxisSpacing: AppDimensions.spaceS,
                childAspectRatio: 0.74,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: _TappableProductCard(product: state.products[i]),
                ),
                childCount: state.products.length,
              ),
            ),
          ),
        // Load-more spinner
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spaceXXL),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spaceXXL)),
      ],
    ),    // closes CustomScrollView
    );    // closes RefreshIndicator
  }
}

// // ── Placeholder tabs ──────────────────────────────────────────────────────────
// 
// class _PlaceholderTab extends StatelessWidget {
//   const _PlaceholderTab({required this.label});
// 
//   final String label;
// 
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//         '$label\n${AppStrings.comingSoon}',
//         textAlign: TextAlign.center,
//         style: GoogleFonts.poppins(
//           fontSize: AppDimensions.fontSizeXL,
//           fontWeight: FontWeight.w600,
//           color: AppColors.textSecondary,
//         ),
//       ),
//     );
//   }
// }

