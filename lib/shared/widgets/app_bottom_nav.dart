import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';

/// Bottom navigation bar matching the React design:
/// - Background: #2C1F0E (dark brown)
/// - Top border: #4A3A2A
/// - Active icon + label: accentGold (#D4A017) with gold dot indicator
/// - Inactive icon: white at 70% opacity
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: AppStrings.navHome),
    _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: AppStrings.navShop),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: AppStrings.navCart),
    // Blog tab — commented out, not required
    // _NavItem(icon: Icons.article_outlined, activeIcon: Icons.article, label: AppStrings.navBlog),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: AppStrings.navAccount),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBg,
        border: Border(
          top: BorderSide(color: AppColors.bottomNavBorder, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavItemWidget(
                item: _items[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
                badge: i == 2 && cartItemCount > 0 ? cartItemCount : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItemWidget extends StatelessWidget {
  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.accentGold
        : Colors.white.withValues(alpha: 0.70);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: color,
                  size: AppDimensions.iconSizeL,
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeXS,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // Gold active dot indicator (React: w-1 h-1 bg-[#D4A017] rounded-full)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4.0 : 0.0,
              height: isActive ? 4.0 : 0.0,
              decoration: const BoxDecoration(
                color: AppColors.accentGold,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
