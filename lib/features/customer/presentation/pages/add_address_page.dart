import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/address_model.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

/// Full-screen form to add a new delivery address.
///
/// On submit it:
/// 1. Requests / checks GPS permission.
/// 2. Fetches the device's current position.
/// 3. Dispatches [CustomerAddressSubmitted] with real lat/lng so the
///    backend's zone check (`coordinates` error) passes.
class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  String _addressType = 'Home';
  bool _fetchingLocation = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _additionalCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseCtrl.dispose();
    _floorCtrl.dispose();
    _streetCtrl.dispose();
    _additionalCtrl.dispose();
    super.dispose();
  }

  // ── GPS helpers ───────────────────────────────────────────────────────────

  /// Returns the device's current position, handling all permission states.
  /// Throws a descriptive [Exception] if location cannot be obtained.
  Future<Position> _getCurrentPosition() async {
    // 1. Is location service enabled on the device?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable GPS and try again.');
    }

    // 2. Check / request permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permission denied. Please allow location access to add an address.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission is permanently denied. Please enable it in app settings.');
    }

    // 3. Fetch position (low accuracy is fine — just need zone check to pass).
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _fetchingLocation = true);

    Position position;
    try {
      position = await _getCurrentPosition();
    } catch (e) {
      if (!mounted) return;
      setState(() => _fetchingLocation = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (!mounted) return;
    setState(() => _fetchingLocation = false);

    final address = AddressModel(
      id: 0,
      addressType: _addressType,
      contactName: _nameCtrl.text.trim(),
      contactNumber: _phoneCtrl.text.trim(),
      house: _houseCtrl.text.trim(),
      floor: _floorCtrl.text.trim(),
      road: null,
      address: _streetCtrl.text.trim(),
      additionalInfo: _additionalCtrl.text.trim(),
      latitude: position.latitude,
      longitude: position.longitude,
      zoneId: 0,    // resolved by backend from lat/lng
      zoneIds: [],
    );

    if (!mounted) return;
    context.read<CustomerBloc>().add(CustomerAddressSubmitted(address));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerLoaded) {
          Navigator.of(context).pop(true);
        } else if (state is CustomerError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.darkBrown),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Add New Address',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.darkBrown,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8E0D5)),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final isSaving = state is CustomerAddressSaving;
        final isWorking = isSaving || _fetchingLocation;

        return Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                children: [
                  // ── Address type ─────────────────────────────────────
                  _SectionLabel(label: 'Address Type'),
                  const SizedBox(height: 10),
                  _AddressTypeSelector(
                    selected: _addressType,
                    onChanged: (v) => setState(() => _addressType = v),
                  ),
                  const SizedBox(height: 24),

                  // ── Contact ──────────────────────────────────────────
                  _SectionLabel(label: 'Contact Details'),
                  const SizedBox(height: 10),
                  _FormCard(children: [
                    _FormField(
                      label: 'Full Name',
                      hint: 'e.g. Rahul Sharma',
                      controller: _nameCtrl,
                      icon: Icons.person_outline_rounded,
                      inputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const _FieldDivider(),
                    _FormField(
                      label: 'Phone Number',
                      hint: '10-digit mobile number',
                      controller: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (v.trim().length != 10) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Address details ──────────────────────────────────
                  _SectionLabel(label: 'Address Details'),
                  const SizedBox(height: 10),
                  _FormCard(children: [
                    _FormField(
                      label: 'House / Flat No.',
                      hint: 'e.g. 42-B, Green Apartment',
                      controller: _houseCtrl,
                      icon: Icons.home_outlined,
                      inputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'House number is required'
                          : null,
                    ),
                    const _FieldDivider(),
                    _FormField(
                      label: 'Floor (optional)',
                      hint: 'e.g. 6th Floor',
                      controller: _floorCtrl,
                      icon: Icons.layers_outlined,
                      inputAction: TextInputAction.next,
                    ),
                    const _FieldDivider(),
                    _FormField(
                      label: 'Street / Area',
                      hint: 'e.g. MG Road, Koramangala',
                      controller: _streetCtrl,
                      icon: Icons.location_on_outlined,
                      inputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Street address is required'
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Additional info ──────────────────────────────────
                  _SectionLabel(label: 'Additional Information (optional)'),
                  const SizedBox(height: 10),
                  _FormCard(children: [
                    _FormField(
                      label: '',
                      hint: 'Landmark, delivery instructions…',
                      controller: _additionalCtrl,
                      icon: Icons.info_outline_rounded,
                      inputAction: TextInputAction.done,
                      maxLines: 3,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Location info banner ─────────────────────────────
                  _LocationInfoBanner(),
                ],
              ),
            ),

            // ── Sticky save bar ──────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SaveBar(
                isSaving: isWorking,
                isFetchingLocation: _fetchingLocation,
                onSave: _submit,
              ),
            ),

            // ── Full-screen overlay ──────────────────────────────────────
            if (isWorking)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primaryGreen),
                        const SizedBox(height: 16),
                        Text(
                          _fetchingLocation
                              ? 'Getting your location…'
                              : 'Saving address…',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Location info banner ──────────────────────────────────────────────────────

class _LocationInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded,
              size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your current GPS location will be used to verify the delivery zone.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryGreen,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address type selector ─────────────────────────────────────────────────────

class _AddressTypeSelector extends StatelessWidget {
  const _AddressTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _types = [
    ('Home', Icons.home_rounded),
    ('Work', Icons.business_rounded),
    ('Other', Icons.location_on_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_types.length, (i) {
        final t = _types[i];
        final isSelected = selected == t.$1;
        final isLast = i == _types.length - 1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isLast ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : const Color(0xFFE0D8CE),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$2,
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    t.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ── Form field ────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.inputAction,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: inputAction,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
            fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label.isEmpty ? null : label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: Icon(icon, size: 20, color: AppColors.primaryGreen),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 48),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          labelStyle: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary),
          hintStyle: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textHint),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
          errorStyle: GoogleFonts.poppins(fontSize: 11),
        ),
      ),
    );
  }
}

// ── Field divider ─────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: const Color(0xFFF0EAE0),
    );
  }
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.isFetchingLocation,
    required this.onSave,
  });

  final bool isSaving;
  final bool isFetchingLocation;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad > 0 ? bottomPad + 8 : 20),
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
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            isFetchingLocation
                ? 'Getting Location…'
                : isSaving
                    ? 'Saving…'
                    : 'Save Address',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.borderMedium,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
