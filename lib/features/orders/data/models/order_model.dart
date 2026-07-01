/// Comprehensive order model covering running-orders, track, and details APIs.
///
/// API response shapes:
///   running-orders → { "orders": [...] }
///   track          → flat order object or { "order": {...} }
///   details        → flat array of items: [{ "item_details": {...}, "variation": [...] }]
class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderAmount,
    required this.deliveryCharge,
    required this.couponDiscount,
    required this.taxAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.paymentMethod,
    required this.orderType,
    required this.createdAt,
    required this.minDeliveryTime,
    required this.maxDeliveryTime,
    required this.items,
    required this.trackingTimeline,
    this.transactionRef,
    this.otp,
    this.store,
    this.deliveryAddress,
    this.itemCount,
  });

  final int id;
  final double orderAmount;
  final double deliveryCharge;
  final double couponDiscount;
  final double taxAmount;
  final String paymentStatus;
  final String orderStatus;
  final String paymentMethod;
  final String orderType;
  final String createdAt;
  final int minDeliveryTime;
  final int maxDeliveryTime;
  final List<OrderItem> items;
  final List<OrderTimelineEntry> trackingTimeline;
  final String? transactionRef;
  final String? otp;
  final OrderStore? store;
  final OrderAddress? deliveryAddress;

  // Populated from running-orders `details_count` when items list is empty.
  final int? itemCount;

  // ── Computed helpers ──────────────────────────────────────────────────────

  int get displayItemCount =>
      items.isNotEmpty ? items.length : (itemCount ?? 0);

  double get grandTotal => orderAmount;

  double get itemsSubtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  double get derivedSubtotal {
    if (itemsSubtotal > 0) return itemsSubtotal;
    final computed = orderAmount - deliveryCharge - taxAmount + couponDiscount;
    return computed > 0 ? computed : 0;
  }

  bool get isCOD => paymentMethod.toLowerCase().contains('cash');

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  bool get isDelivered => orderStatus.toLowerCase() == 'delivered';

  bool get isCancelled => orderStatus.toLowerCase() == 'cancelled';

  bool get isOutForDelivery =>
      orderStatus.toLowerCase().contains('out_for_delivery') ||
      orderStatus.toLowerCase() == 'picked_up';

  /// Raw payment_method from the API formatted for display.
  String get paymentMethodLabel => _humanizeText(paymentMethod);

  /// Raw payment_status from the API (e.g. "paid", "unpaid").
  String get paymentStatusLabel => _humanizeText(paymentStatus);

  /// Raw order_type from the API (e.g. "delivery", "take_away").
  String get orderTypeLabel => _humanizeText(orderType);

  String get etaLabel {
    if (minDeliveryTime <= 0 && maxDeliveryTime <= 0) return '';
    if (minDeliveryTime > 0 && maxDeliveryTime > 0) {
      return '$minDeliveryTime–$maxDeliveryTime min';
    }
    final single = maxDeliveryTime > 0 ? maxDeliveryTime : minDeliveryTime;
    return '$single min';
  }

  /// Formats the ISO createdAt string to a locale-style display string.
  String get formattedCreatedAt {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      final min = dt.minute.toString().padLeft(2, '0');
      final sec = dt.second.toString().padLeft(2, '0');
      return '${dt.month}/${dt.day}/${dt.year}, $hour:$min:$sec $ampm';
    } catch (_) {
      return createdAt;
    }
  }

  String get statusLabel => _humanizeText(orderStatus);

  // ── copyWith ──────────────────────────────────────────────────────────────

  OrderModel copyWith({
    int? id,
    double? orderAmount,
    double? deliveryCharge,
    double? couponDiscount,
    double? taxAmount,
    String? paymentStatus,
    String? orderStatus,
    String? paymentMethod,
    String? orderType,
    String? createdAt,
    int? minDeliveryTime,
    int? maxDeliveryTime,
    List<OrderItem>? items,
    List<OrderTimelineEntry>? trackingTimeline,
    String? transactionRef,
    String? otp,
    OrderStore? store,
    OrderAddress? deliveryAddress,
    int? itemCount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderAmount: orderAmount ?? this.orderAmount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderType: orderType ?? this.orderType,
      createdAt: createdAt ?? this.createdAt,
      minDeliveryTime: minDeliveryTime ?? this.minDeliveryTime,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      items: items ?? this.items,
      trackingTimeline: trackingTimeline ?? this.trackingTimeline,
      transactionRef: transactionRef ?? this.transactionRef,
      otp: otp ?? this.otp,
      store: store ?? this.store,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String? ?? '';
    final orderStatus =
        (json['order_status'] as String? ?? '').trim().toLowerCase();

    return OrderModel(
      id: _parseInt(json['id'] ?? json['order_id']),
      orderAmount: _parseDouble(json['order_amount'] ?? json['total_ammount']),
      deliveryCharge: _parseDouble(json['delivery_charge']),
      couponDiscount: _parseDouble(
          json['coupon_discount_amount'] ?? json['discount_amount']),
      taxAmount: _parseDouble(json['tax_amount']),
      paymentStatus:
          (json['payment_status'] as String? ?? '').trim().toLowerCase(),
      orderStatus: orderStatus,
      paymentMethod: (json['payment_method'] as String? ?? '').trim(),
      orderType: (json['order_type'] as String? ?? '').trim().toLowerCase(),
      createdAt: createdAt,
      minDeliveryTime: _parseInt(json['min_delivery_time']),
      maxDeliveryTime: _parseInt(json['max_delivery_time']),
      transactionRef: json['transaction_reference'] as String?,
      otp: json['otp'] as String?,
      itemCount: _parseInt(json['details_count'] ?? json['item_count']),
      store: _parseStore(json['store']),
      deliveryAddress:
          _parseAddress(json['delivery_address'] ?? json['shipping_address']),
      items: _parseItems(
          json['details'] ?? json['order_details'] ?? json['items']),
      trackingTimeline: _parseTimeline(
        json,
        orderStatus: orderStatus,
        createdAt: createdAt,
      ),
    );
  }

  static OrderStore? _parseStore(dynamic raw) {
    if (raw is Map<String, dynamic>) return OrderStore.fromJson(raw);
    return null;
  }

  static OrderAddress? _parseAddress(dynamic raw) {
    if (raw is Map<String, dynamic>) return OrderAddress.fromJson(raw);
    return null;
  }

  static List<OrderItem> _parseItems(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList();
    }
    return [];
  }

  static List<OrderTimelineEntry> _parseTimeline(
    Map<String, dynamic> json, {
    required String orderStatus,
    required String createdAt,
  }) {
    final candidates = <dynamic>[
      json['timeline'],
      json['timelines'],
      json['tracking'],
      json['track'],
      json['tracks'],
      json['history'],
      json['histories'],
      json['status_history'],
      json['order_status_history'],
      json['order_histories'],
    ];

    for (final candidate in candidates) {
      final parsed = _parseTimelineList(candidate);
      if (parsed.isNotEmpty) {
        return _markTimelineProgress(parsed, orderStatus);
      }
    }

    if (orderStatus.isEmpty) return const <OrderTimelineEntry>[];

    return [
      OrderTimelineEntry(
        stateKey: orderStatus,
        label: _humanizeText(orderStatus),
        timestamp: createdAt,
        description: '',
        isCurrent: true,
        isCompleted: true,
      ),
    ];
  }

  static List<OrderTimelineEntry> _parseTimelineList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OrderTimelineEntry.fromJson)
          .where((entry) => entry.label.isNotEmpty || entry.stateKey.isNotEmpty)
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'items',
        'timeline',
        'timelines',
        'history',
        'histories',
        'statuses',
      ]) {
        final nested = _parseTimelineList(raw[key]);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const <OrderTimelineEntry>[];
  }

  static List<OrderTimelineEntry> _markTimelineProgress(
    List<OrderTimelineEntry> entries,
    String currentStatus,
  ) {
    if (entries.isEmpty) return const <OrderTimelineEntry>[];

    var currentIndex = -1;
    if (currentStatus.isNotEmpty) {
      for (var i = entries.length - 1; i >= 0; i--) {
        if (entries[i].matches(currentStatus)) {
          currentIndex = i;
          break;
        }
      }
    }

    if (currentIndex == -1) {
      currentIndex = entries.indexWhere((entry) => entry.isCurrent);
    }
    if (currentIndex == -1) currentIndex = entries.length - 1;

    return List<OrderTimelineEntry>.generate(entries.length, (index) {
      final entry = entries[index];
      return entry.copyWith(
        isCurrent: index == currentIndex,
        isCompleted: index <= currentIndex || entry.isCompleted,
      );
    });
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

String _humanizeText(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  final words = value
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) {
    final lower = word.toLowerCase();
    if (lower.length == 1) return lower.toUpperCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).toList();

  return words.join(' ');
}

// ── Store ─────────────────────────────────────────────────────────────────────

class OrderStore {
  const OrderStore({
    required this.id,
    required this.name,
    this.logoFullUrl,
    this.address,
    this.phone,
    this.deliveryTime,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.coverPhotoFullUrl,
  });

  final int id;
  final String name;
  final String? logoFullUrl;
  final String? address;
  final String? phone;
  final String? deliveryTime;
  final double avgRating;
  final int ratingCount;
  final String? coverPhotoFullUrl;

  factory OrderStore.fromJson(Map<String, dynamic> json) {
    return OrderStore(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      logoFullUrl: json['logo_full_url'] as String? ?? json['logo'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      deliveryTime: json['delivery_time'] as String?,
      avgRating: _parseDouble(json['avg_rating']),
      ratingCount: _parseInt(json['rating_count']),
      coverPhotoFullUrl: json['cover_photo_full_url'] as String?,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ── Delivery address ──────────────────────────────────────────────────────────

class OrderAddress {
  const OrderAddress({
    required this.contactName,
    required this.contactPhone,
    required this.addressType,
    required this.address,
    required this.house,
    required this.floor,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  final String contactName;
  final String contactPhone;
  final String addressType;
  final String address;
  final String house;
  final String floor;
  final double latitude;
  final double longitude;

  String get fullAddress {
    final parts = <String>[];
    if (house.isNotEmpty) parts.add(house);
    if (floor.isNotEmpty) parts.add('Floor $floor');
    if (address.isNotEmpty) parts.add(address);
    return parts.join(', ');
  }

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      contactName: json['contact_person_name'] as String? ?? '',
      contactPhone: json['contact_person_number'] as String? ?? '',
      addressType: json['address_type'] as String? ?? '',
      address: json['address'] as String? ?? '',
      house: json['house'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ── Order item ────────────────────────────────────────────────────────────────

class OrderItem {
  const OrderItem({
    required this.id,
    required this.itemId,
    required this.orderId,
    required this.name,
    required this.variant,
    required this.quantity,
    required this.price,
    required this.taxAmount,
    this.imageFullUrl,
  });

  final int id;
  final int itemId;
  final int orderId;
  final String name;
  final String variant;
  final int quantity;
  final double price;
  final double taxAmount;
  final String? imageFullUrl;

  double get lineTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final itemDetails = _extractItemDetails(json);

    final name = _firstText([
      itemDetails['name'],
      itemDetails['item_name'],
      itemDetails['title'],
      itemDetails['product_name'],
      json['name'],
      json['item_name'],
      json['product_name'],
      json['title'],
    ]);

    final rawVariation = json['variation'] ??
        json['variations'] ??
        itemDetails['variation'] ??
        itemDetails['variations'] ??
        json['variant'];
    final variationData = _parseVariation(rawVariation);
    final variantDisplay = variationData.label;

    String? imageUrl = _extractImageUrl(itemDetails);
    imageUrl ??= _extractImageUrl(json);

    final price = _parseDouble(
      json['price'] ??
          json['unit_price'] ??
          itemDetails['price'] ??
          itemDetails['unit_price'] ??
          variationData.price,
    );

    return OrderItem(
      id: _parseInt(json['id']),
      itemId: _parseInt(json['item_id']),
      orderId: _parseInt(json['order_id']),
      name: name,
      variant: variantDisplay,
      quantity: _parseInt(json['quantity'] ?? json['qty']),
      price: price,
      taxAmount: _parseDouble(json['tax_amount'] ?? json['tax']),
      imageFullUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    );
  }

  static Map<String, dynamic> _extractItemDetails(Map<String, dynamic> json) {
    for (final key in const [
      'item_details',
      'item',
      'product',
      'product_details',
      'food_details',
    ]) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
    }
    return const <String, dynamic>{};
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    final direct = _firstTextOrNull([
      json['image_full_url'],
      json['thumbnail_full_url'],
      json['image'],
      json['thumbnail'],
    ]);
    if (direct != null) return direct;

    for (final key in const ['images_full_url', 'images']) {
      final value = json[key];
      if (value is List) {
        for (final entry in value) {
          if (entry is String && entry.trim().isNotEmpty) return entry.trim();
          if (entry is Map<String, dynamic>) {
            final nested = _firstTextOrNull([
              entry['img'],
              entry['image'],
              entry['image_full_url'],
              entry['path'],
            ]);
            if (nested != null) return nested;
          }
        }
      }
    }

    return null;
  }

  static _ParsedVariation _parseVariation(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return _ParsedVariation(
        label: _firstText([raw['type'], raw['name'], raw['label']]),
        price: _parseDouble(raw['price']),
      );
    }

    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return _ParsedVariation(
          label: _firstText([first['type'], first['name'], first['label']]),
          price: _parseDouble(first['price']),
        );
      }
      if (first is String && first.trim().isNotEmpty) {
        return _ParsedVariation(label: first.trim(), price: 0);
      }
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return _ParsedVariation(label: raw.trim(), price: 0);
    }

    return const _ParsedVariation(label: '', price: 0);
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String? _firstTextOrNull(List<dynamic> values) {
    final text = _firstText(values);
    return text.isEmpty ? null : text;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class _ParsedVariation {
  const _ParsedVariation({required this.label, required this.price});

  final String label;
  final double price;
}

class OrderTimelineEntry {
  const OrderTimelineEntry({
    required this.stateKey,
    required this.label,
    required this.timestamp,
    required this.description,
    required this.isCurrent,
    required this.isCompleted,
  });

  final String stateKey;
  final String label;
  final String timestamp;
  final String description;
  final bool isCurrent;
  final bool isCompleted;

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    final rawState = _firstText([
      json['status'],
      json['order_status'],
      json['state'],
      json['type'],
      json['key'],
      json['slug'],
      json['label'],
      json['title'],
      json['name'],
    ]).toLowerCase();

    final label = _firstText([
      json['label'],
      json['title'],
      json['name'],
      json['status_label'],
    ]);

    return OrderTimelineEntry(
      stateKey: rawState,
      label: label.isNotEmpty ? label : _humanizeText(rawState),
      timestamp: _firstText([
        json['created_at'],
        json['updated_at'],
        json['timestamp'],
        json['time'],
        json['date'],
      ]),
      description: _firstText([
        json['description'],
        json['message'],
        json['note'],
        json['remarks'],
      ]),
      isCurrent: _parseBool(
        json['is_current'] ?? json['current'] ?? json['active'],
      ),
      isCompleted: _parseBool(
        json['is_completed'] ?? json['completed'] ?? json['is_done'],
      ),
    );
  }

  OrderTimelineEntry copyWith({
    String? stateKey,
    String? label,
    String? timestamp,
    String? description,
    bool? isCurrent,
    bool? isCompleted,
  }) {
    return OrderTimelineEntry(
      stateKey: stateKey ?? this.stateKey,
      label: label ?? this.label,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      isCurrent: isCurrent ?? this.isCurrent,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool matches(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return stateKey == normalized || label.trim().toLowerCase() == normalized;
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }
}
