import 'package:equatable/equatable.dart';

import '../../data/models/address_model.dart';
import '../../data/models/customer_model.dart';

sealed class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

final class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

final class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

/// While a new address is being saved via POST /address/add.
final class CustomerAddressSaving extends CustomerState {
  const CustomerAddressSaving();
}

final class CustomerUnauthenticated extends CustomerState {
  const CustomerUnauthenticated();
}

final class CustomerLoaded extends CustomerState {
  const CustomerLoaded({
    required this.customer,
    required this.addresses,
    this.selectedAddressId,
  });

  final CustomerModel customer;
  final List<AddressModel> addresses;

  /// Null = no address chosen yet (checkout should block pay button).
  final int? selectedAddressId;

  AddressModel? get selectedAddress => selectedAddressId == null
      ? null
      : addresses.where((a) => a.id == selectedAddressId).firstOrNull;

  CustomerLoaded copyWith({
    CustomerModel? customer,
    List<AddressModel>? addresses,
    int? selectedAddressId,
    bool clearSelection = false,
  }) {
    return CustomerLoaded(
      customer: customer ?? this.customer,
      addresses: addresses ?? this.addresses,
      selectedAddressId:
          clearSelection ? null : (selectedAddressId ?? this.selectedAddressId),
    );
  }

  @override
  List<Object?> get props => [customer, addresses, selectedAddressId];
}

final class CustomerError extends CustomerState {
  const CustomerError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
