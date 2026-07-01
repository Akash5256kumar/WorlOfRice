import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/address_model.dart';
import '../../data/models/customer_model.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import 'add_address_page.dart';
import '../../../../../features/orders/presentation/pages/running_orders_page.dart';

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Logout',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.darkBrown),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ctaRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<CustomerBloc>().add(const CustomerLoggedOut());
  }
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      // Only react when an authenticated session transitions to unauthenticated
      // (i.e., the user just logged out — not the initial unauthenticated load).
      listenWhen: (prev, curr) =>
          prev is CustomerLoaded && curr is CustomerUnauthenticated,
      listener: (context, state) => context.go(AppRoutes.auth),
      child: SafeArea(
        child: Column(
          children: [
          // Header
          Container(
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
            alignment: Alignment.centerLeft,
            child: Text(
              'My Account',
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeXL,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading || state is CustomerInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  );
                }
                if (state is CustomerUnauthenticated) {
                  return const _UnauthenticatedView();
                }
                if (state is CustomerError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<CustomerBloc>().add(const CustomerStarted()),
                  );
                }
                if (state is CustomerLoaded) {
                  return _ProfileView(
                    customer: state.customer,
                    addresses: state.addresses,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ── Unauthenticated ───────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'Sign in to view your profile',
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeXL,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Access your orders, addresses and more',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXXL),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
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

// ── Profile view ──────────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.customer, required this.addresses});

  final CustomerModel customer;
  final List<AddressModel> addresses;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      onRefresh: () async {
        context.read<CustomerBloc>().add(const CustomerStarted());
        await context.read<CustomerBloc>().stream.firstWhere(
              (s) => s is CustomerLoaded || s is CustomerError,
            );
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name
          _ProfileHeader(customer: customer),
          const SizedBox(height: AppDimensions.spaceXL),
          // Stats row
          _StatsRow(customer: customer),
          const SizedBox(height: AppDimensions.spaceXL),
          // My Orders quick-access
          _MyOrdersTile(),
          const SizedBox(height: AppDimensions.spaceXL),
          // Info card
          _InfoCard(customer: customer),
          const SizedBox(height: AppDimensions.spaceXL),
          // Addresses
          _AddressesSection(addresses: addresses),
          const SizedBox(height: AppDimensions.spaceXL),
          // Policies
          const _PoliciesSection(),
          const SizedBox(height: AppDimensions.spaceXXL),
          // Logout
          _LogoutButton(),
          const SizedBox(height: AppDimensions.spaceXXL),
        ],
      ),
    ),    // closes SingleChildScrollView
    );    // closes RefreshIndicator
  }
}

class _MyOrdersTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RunningOrdersPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Orders',
                    style: GoogleFonts.poppins(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Track, view & manage your orders',
                    style: GoogleFonts.poppins(
                      fontSize: AppDimensions.fontSizeXS,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: customer.imageFullUrl != null
              ? ClipOval(
                  child: Image.network(
                    customer.imageFullUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialAvatar(initials: customer.initials),
                  ),
                )
              : _InitialAvatar(initials: customer.initials),
        ),
        const SizedBox(width: AppDimensions.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.fullName.isNotEmpty ? customer.fullName : 'User',
                style: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              if (customer.email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  customer.email,
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (customer.phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      customer.phone,
                      style: GoogleFonts.poppins(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (customer.isPhoneVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppColors.primaryGreen),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Orders',
            value: '${customer.orderCount}',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            value: '₹${customer.walletBalance.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _StatCard(
            icon: Icons.stars_outlined,
            label: 'Points',
            value: customer.loyaltyPoints.toStringAsFixed(0),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppDimensions.iconSizeM, color: AppColors.primaryGreen),
          const SizedBox(height: AppDimensions.spaceXXS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          if (customer.refCode.isNotEmpty)
            _InfoRow(
              icon: Icons.card_giftcard_outlined,
              label: 'Referral Code',
              value: customer.refCode,
              isLast: false,
            ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Zone',
            value: customer.zoneId != null ? 'Zone #${customer.zoneId}' : 'Not set',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppDimensions.iconSizeM, color: AppColors.primaryGreen),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: AppDimensions.fontSizeXS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}

// ── Addresses section ─────────────────────────────────────────────────────────

class _AddressesSection extends StatelessWidget {
  const _AddressesSection({required this.addresses});

  final List<AddressModel> addresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Addresses',
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<CustomerBloc>(),
                      child: const AddAddressPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
              label: Text(
                'Add',
                style: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceS),
        if (addresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceXL),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.location_off_outlined, size: 40, color: AppColors.borderMedium),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'No saved addresses',
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...addresses.map((addr) => _AddressCard(address: addr)),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final AddressModel address;

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'office':
      case 'work':
        return Icons.business_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(address.addressType),
              size: AppDimensions.iconSizeM,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.addressType,
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (address.contactName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address.contactName,
                    style: GoogleFonts.poppins(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (address.additionalInfo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address.additionalInfo,
                    style: GoogleFonts.poppins(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action menu
          Builder(
            builder: (ctx) => InkWell(
              onTap: () async {
                final choice = await showMenu<String>(
                  context: ctx,
                  position: (() {
                    final box = ctx.findRenderObject() as RenderBox;
                    final overlay = Overlay.of(ctx)
                        .context
                        .findRenderObject() as RenderBox;
                    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
                    return RelativeRect.fromLTRB(
                      pos.dx,
                      pos.dy + box.size.height,
                      overlay.size.width - pos.dx - box.size.width,
                      overlay.size.height - pos.dy - box.size.height,
                    );
                  })(),
                  items: const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                );
                if (choice == 'delete' && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Delete address coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_vert,
                    size: 18, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Policies section ──────────────────────────────────────────────────────────

class _PoliciesSection extends StatelessWidget {
  const _PoliciesSection();

  static const _policies = [
    (
      label: 'Terms & Conditions',
      icon: Icons.gavel_outlined,
      url: 'https://www.worldofrice.in/terms-and-conditions',
    ),
    (
      label: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      url: 'https://www.worldofrice.in/privacy-policy',
    ),
    (
      label: 'Refund & Return Policy',
      icon: Icons.assignment_return_outlined,
      url: 'https://www.worldofrice.in/refund-and-return-policy',
    ),
    (
      label: 'Shipping & Delivery Policy',
      icon: Icons.local_shipping_outlined,
      url: 'https://www.worldofrice.in/shipping-and-delivery-policy',
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) _showLaunchError(context);
    } catch (_) {
      // PlatformException thrown when the channel isn't ready or no app can
      // handle the URL — fall back to in-app browser view.
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        if (context.mounted) _showLaunchError(context);
      }
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the page. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal',
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _policies.length; i++) ...[
                _PolicyTile(
                  icon: _policies[i].icon,
                  label: _policies[i].label,
                  onTap: () => _open(context, _policies[i].url),
                ),
                if (i < _policies.length - 1)
                  const Divider(height: 1, color: AppColors.borderLight),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSizeM, color: AppColors.primaryGreen),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.ctaRed),
        label: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ctaRed,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.ctaRed.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
