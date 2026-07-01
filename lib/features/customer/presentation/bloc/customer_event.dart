import 'package:equatable/equatable.dart';

import '../../data/models/address_model.dart';

sealed class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

/// Load customer profile + addresses from the API.
final class CustomerStarted extends CustomerEvent {
  const CustomerStarted();
}

/// Submit a new address via POST /address/add, then refresh list.
final class CustomerAddressSubmitted extends CustomerEvent {
  const CustomerAddressSubmitted(this.address);
  final AddressModel address;
  @override
  List<Object?> get props => [address];
}

/// Update an existing address via PUT /address/update/{id}, then refresh list.
final class CustomerAddressUpdateSubmitted extends CustomerEvent {
  const CustomerAddressUpdateSubmitted({required this.id, required this.address});
  final int id;
  final AddressModel address;
  @override
  List<Object?> get props => [id, address];
}

/// Mark an address as selected for the current checkout session.
final class CustomerAddressSelected extends CustomerEvent {
  const CustomerAddressSelected(this.addressId);
  final int addressId;
  @override
  List<Object?> get props => [addressId];
}

/// Clear the local auth token and emit unauthenticated state.
final class CustomerLoggedOut extends CustomerEvent {
  const CustomerLoggedOut();
}
