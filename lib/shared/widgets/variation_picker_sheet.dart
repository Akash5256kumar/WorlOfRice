import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../features/home/data/models/variation_model.dart';

/// Shows a modal bottom sheet for selecting a product variation (size/weight).
///
/// Returns the chosen [VariationModel], or `null` if dismissed.
Future<VariationModel?> showVariationPickerSheet(
  BuildContext context, {
  required String productName,
  required List<VariationModel> variations,
  int initialIndex = 0,
  String confirmLabel = 'Add to Cart',
}) {
  if (variations.isEmpty) return Future.value(null);
  return showModalBottomSheet<VariationModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VariationPickerSheet(
      productName: productName,
      variations: variations,
      initialIndex: initialIndex.clamp(0, variations.length - 1),
      confirmLabel: confirmLabel,
    ),
  );
}

class _VariationPickerSheet extends StatefulWidget {
  const _VariationPickerSheet({
    required this.productName,
    required this.variations,
    required this.initialIndex,
    required this.confirmLabel,
  });

  final String productName;
  final List<VariationModel> variations;
  final int initialIndex;
  final String confirmLabel;

  @override
  State<_VariationPickerSheet> createState() => _VariationPickerSheetState();
}

class _VariationPickerSheetState extends State<_VariationPickerSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  VariationModel get _selected => widget.variations[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spaceL,
        AppDimensions.spaceM,
        AppDimensions.spaceL,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.spaceXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          // Product name
          Text(
            widget.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            'Select Size / Weight',
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          // Variation grid
          Wrap(
            spacing: AppDimensions.spaceS,
            runSpacing: AppDimensions.spaceS,
            children: List.generate(widget.variations.length, (i) {
              final v = widget.variations[i];
              final isSelected = i == _selectedIndex;
              final isOutOfStock = !v.inStock;
              return GestureDetector(
                onTap: isOutOfStock ? null : () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minWidth: 72),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : isOutOfStock
                            ? AppColors.scaffoldBg
                            : AppColors.cardBg,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : isOutOfStock
                              ? AppColors.borderLight
                              : AppColors.borderMedium,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        v.type,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textWhite
                              : isOutOfStock
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                        ),
                      ),
                      if (isOutOfStock)
                        Text(
                          'Out of stock',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppColors.textHint,
                          ),
                        )
                      else ...[
                        Text(
                          '₹${v.price.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: AppDimensions.fontSizeS,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.textWhite
                                : AppColors.primaryGreen,
                          ),
                        ),
                        if (v.hasDiscount) ...[
                          Text(
                            '₹${v.actualPrice!.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: isSelected
                                  ? AppColors.textWhite.withValues(alpha: 0.65)
                                  : AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: isSelected
                                  ? AppColors.textWhite.withValues(alpha: 0.65)
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.spaceXL),
          // Price + confirm button row
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_selected.price.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: AppDimensions.fontSizeXXL,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    if (_selected.hasDiscount) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹${_selected.actualPrice!.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.ctaRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_selected.discountPercentage.toStringAsFixed(0)}% off',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ctaRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Save ₹${_selected.savings.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ] else
                      Text(
                        _selected.type,
                        style: GoogleFonts.poppins(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceL),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 18),
                        const SizedBox(width: AppDimensions.spaceXS),
                        Text(
                          widget.confirmLabel,
                          style: GoogleFonts.poppins(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
