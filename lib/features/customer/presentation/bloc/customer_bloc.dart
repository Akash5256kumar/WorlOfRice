import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc({CustomerRepository? repository})
      : _repo = repository ?? CustomerRepository(),
        super(const CustomerInitial()) {
    on<CustomerStarted>(_onStarted);
    on<CustomerAddressSubmitted>(_onAddressSubmitted);
    on<CustomerAddressUpdateSubmitted>(_onAddressUpdateSubmitted);
    on<CustomerAddressSelected>(_onAddressSelected);
    on<CustomerLoggedOut>(_onLoggedOut);
  }

  final CustomerRepository _repo;

  // ── Load profile ───────────────────────────────────────────────────────────

  Future<void> _onStarted(
      CustomerStarted event, Emitter<CustomerState> emit) async {
    emit(const CustomerLoading());
    try {
      final token = await ApiService().getToken();
      if (token == null) {
        emit(const CustomerUnauthenticated());
        return;
      }
      final customer = await _repo.getCustomerInfo();
      final addresses = await _repo.getAddresses();
      emit(CustomerLoaded(customer: customer, addresses: addresses));
      debugPrint('[CustomerBloc] loaded profile (${addresses.length} addresses)');
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        emit(const CustomerUnauthenticated());
      } else {
        emit(CustomerError(e.message));
      }
    } catch (e) {
      debugPrint('[CustomerBloc] error: $e');
      emit(CustomerError(e.toString()));
    }
  }

  // ── Add address via POST /address/add ──────────────────────────────────────

  Future<void> _onAddressSubmitted(
      CustomerAddressSubmitted event, Emitter<CustomerState> emit) async {
    final prev = state;
    emit(const CustomerAddressSaving());
    try {
      await _repo.addAddress(event.address);
      debugPrint('[CustomerBloc] address added, refreshing list…');

      // Re-fetch addresses from server so IDs are populated.
      final addresses = await _repo.getAddresses();

      if (prev is CustomerLoaded) {
        emit(prev.copyWith(addresses: addresses));
      } else {
        // Fallback: trigger a full reload.
        add(const CustomerStarted());
      }
    } catch (e) {
      debugPrint('[CustomerBloc] addAddress error: $e');
      // Restore previous state so the UI is not stuck on saving.
      if (prev is CustomerLoaded) {
        emit(prev);
      }
      emit(CustomerError(e.toString()));
    }
  }

  // ── Update address via PUT /address/update/{id} ────────────────────────────

  Future<void> _onAddressUpdateSubmitted(
      CustomerAddressUpdateSubmitted event, Emitter<CustomerState> emit) async {
    final prev = state;
    emit(const CustomerAddressSaving());
    try {
      await _repo.updateAddress(event.id, event.address);
      debugPrint('[CustomerBloc] address updated (id=${event.id}), refreshing…');
      final addresses = await _repo.getAddresses();
      if (prev is CustomerLoaded) {
        emit(prev.copyWith(addresses: addresses));
      } else {
        add(const CustomerStarted());
      }
    } catch (e) {
      debugPrint('[CustomerBloc] updateAddress error: $e');
      if (prev is CustomerLoaded) emit(prev);
      emit(CustomerError(e.toString()));
    }
  }

  // ── Select address for checkout ────────────────────────────────────────────

  void _onAddressSelected(
      CustomerAddressSelected event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      emit((state as CustomerLoaded)
          .copyWith(selectedAddressId: event.addressId));
      debugPrint('[CustomerBloc] selected address ${event.addressId}');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _onLoggedOut(
      CustomerLoggedOut event, Emitter<CustomerState> emit) async {
    await _repo.logout(); // best-effort server invalidation
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('[CustomerBloc] logged out — token cleared');
    emit(const CustomerUnauthenticated());
  }
}
