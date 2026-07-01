/// Maps one address from `GET /api/v1/customer/address/list`
/// and matches the body shape of `POST /api/v1/customer/address/add`.
///
/// Confirmed field names from live address/list response (2026-05-27):
/// { id, address_type, contact_person_name, contact_person_number,
///   house, floor, road, address (always null), additional_information,
///   latitude, longitude, zone_id, zone_ids }
class AddressModel {
  const AddressModel({
    required this.id,
    required this.addressType,
    required this.contactName,
    required this.contactNumber,
    required this.house,
    required this.floor,
    required this.road,
    required this.address,
    required this.additionalInfo,
    required this.latitude,
    required this.longitude,
    required this.zoneId,
    required this.zoneIds,
  });

  final int id;
  final String addressType;
  final String contactName;
  final String contactNumber;
  final String house;
  final String floor;

  /// `road` field from API — usually null.
  final String? road;

  /// `address` field from API — the API currently returns null for this field.
  /// Use [additionalInfo] as the full human-readable address string instead.
  final String? address;

  /// Full human-readable address string (`additional_information` from API).
  /// This is what the web app sends as the `address` value during checkout.
  final String additionalInfo;

  final double latitude;
  final double longitude;

  /// Primary zone ID for this address (from `zone_id` in API response).
  final int zoneId;

  /// All zone IDs covering this address (from `zone_ids` in API response).
  final List<int> zoneIds;

  /// The address text to send during checkout.
  /// API's `address` field is always null, so we fall back to [additionalInfo].
  String get checkoutAddress {
    if (additionalInfo.isNotEmpty) return additionalInfo;
    return [house, floor].where((s) => s.isNotEmpty).join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Parse zone_ids array: [4, 2]
    final rawZoneIds = json['zone_ids'];
    final zoneIds = <int>[];
    if (rawZoneIds is List) {
      for (final z in rawZoneIds) {
        if (z is int) zoneIds.add(z);
        if (z is String) zoneIds.add(int.tryParse(z) ?? 0);
      }
    }

    return AddressModel(
      id: json['id'] as int,
      addressType: json['address_type'] as String? ?? 'Home',
      contactName: json['contact_person_name'] as String? ?? '',
      contactNumber: json['contact_person_number'] as String? ?? '',
      house: json['house'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      road: json['road'] as String?,
      address: json['address'] as String?,          // will be null from API
      additionalInfo: json['additional_information'] as String? ?? '',
      latitude: double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: double.tryParse('${json['longitude']}') ?? 0.0,
      zoneId: json['zone_id'] as int? ?? 0,
      zoneIds: zoneIds,
    );
  }

  /// Builds the POST body for `address/add`.
  Map<String, dynamic> toAddBody({String? guestId}) => {
        if (guestId != null) 'guest_id': guestId,
        'address_type': addressType,
        'contact_person_name': contactName,
        'contact_person_number': contactNumber,
        'house': house,
        'floor': floor,
        'road': road,
        'address': address,
        'additional_information': additionalInfo,
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Builds the PUT body for `address/update/{id}`.
  Map<String, dynamic> toUpdateBody() => {
        'address_type': addressType,
        'contact_person_name': contactName,
        'contact_person_number': contactNumber,
        'house': house,
        'floor': floor,
        'road': road,
        'address': address,
        'additional_information': additionalInfo,
        'latitude': latitude,
        'longitude': longitude,
      };

  AddressModel copyWith({
    int? id,
    String? addressType,
    String? contactName,
    String? contactNumber,
    String? house,
    String? floor,
    String? road,
    String? address,
    String? additionalInfo,
    double? latitude,
    double? longitude,
    int? zoneId,
    List<int>? zoneIds,
  }) {
    return AddressModel(
      id: id ?? this.id,
      addressType: addressType ?? this.addressType,
      contactName: contactName ?? this.contactName,
      contactNumber: contactNumber ?? this.contactNumber,
      house: house ?? this.house,
      floor: floor ?? this.floor,
      road: road ?? this.road,
      address: address ?? this.address,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoneId: zoneId ?? this.zoneId,
      zoneIds: zoneIds ?? this.zoneIds,
    );
  }
}
