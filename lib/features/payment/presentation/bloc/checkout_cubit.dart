import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/data/models/cart_item_model.dart';
import '../../../customer/data/models/address_model.dart';
import '../../data/models/checkout_summary.dart';
import '../../data/repositories/checkout_repository.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({CheckoutRepository? repo})
      : _repo = repo ?? CheckoutRepository(),
        super(const CheckoutInitial());

  final CheckoutRepository _repo;

  /// Fetches the delivery distance for [address] then computes delivery charge,
  /// tax, and grand total from [cartItems].  Emits [CheckoutReady] on success.
  Future<void> calculate({
    required AddressModel address,
    required List<CartItemModel> cartItems,
  }) async {
    emit(const CheckoutCalculating());
    try {
      final distanceKm =
          await _repo.fetchDistanceKm(address.latitude, address.longitude);
      final subtotal = cartItems.fold(0.0, (s, i) => s + i.lineTotal);
      final totalWeight = cartItems.fold(0.0, (s, i) => s + i.weightTotal);
      final summary = _repo.buildSummary(
        subtotal: subtotal,
        totalWeightKg: totalWeight,
        distanceInKm: distanceKm,
      );
      debugPrint('[CheckoutCubit] dist=${distanceKm.toStringAsFixed(2)}km '
          'weight=${totalWeight}kg delivery=₹${summary.deliveryCharge} '
          'tax=₹${summary.tax} total=₹${summary.grandTotal}');
      emit(CheckoutReady(summary));
    } catch (e) {
      debugPrint('[CheckoutCubit] error: $e');
      emit(CheckoutError(e.toString()));
    }
  }

  void reset() => emit(const CheckoutInitial());
}
