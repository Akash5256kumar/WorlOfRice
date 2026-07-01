/// Computed checkout totals for a given address + cart combination.
class CheckoutSummary {
  const CheckoutSummary({
    required this.subtotal,
    required this.totalWeightKg,
    required this.distanceInKm,
    required this.deliveryCharge,
    required this.tax,
    this.discount = 0,
  });

  final double subtotal;
  final double totalWeightKg;
  final double distanceInKm;
  final double deliveryCharge;
  final double tax;
  final double discount;

  double get grandTotal => subtotal + deliveryCharge + tax - discount;
}
