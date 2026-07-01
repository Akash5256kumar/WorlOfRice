abstract final class ApiConstants {
  static const String _base = 'https://appadmin.worldofrice.in/api/v1';
  static const String _appBase = 'https://appadmin.worldofrice.in';

  // Module 2 = Grocery (rice products)
  static const int moduleId = 2;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String signUp = '$_base/auth/sign-up';
  static const String login = '$_base/auth/login';
  static const String logout = '$_base/auth/logout';

  // ── Products / Categories ─────────────────────────────────────────────────
  static const String categories = '$_base/categories';
  static const String combinedData = '$_base/get-combined-data';
  static const String trendingItems = '$_base/items/trading';
  static const String itemDetails = '$_base/items/details';
  static const String relatedStoreItems = '$_base/items/related-store-items';

  // ── Cart ──────────────────────────────────────────────────────────────────
  static const String cartAdd = '$_base/customer/cart/add';
  static const String cartList = '$_base/customer/cart/list';
  static const String cartUpdate = '$_base/customer/cart/update';
  static const String cartRemoveItem = '$_base/customer/cart/remove-item';

  // ── Customer ──────────────────────────────────────────────────────────────
  static const String customerInfo = '$_base/customer/info';
  static const String addressList = '$_base/customer/address/list';
  static const String addressAdd = '$_base/customer/address/add';
  static const String addressUpdate = '$_base/customer/address/update';

  // ── Orders ────────────────────────────────────────────────────────────────
  static const String orderPlace = '$_base/customer/order/place';
  static const String runningOrders = '$_base/customer/order/running-orders';
  static const String trackOrder = '$_base/customer/order/track';
  static const String orderDetails = '$_base/customer/order/details';

  // ── Zone ──────────────────────────────────────────────────────────────────
  static const String getZoneId = '$_base/config/get-zone-id';

  // ── Payment ───────────────────────────────────────────────────────────────
  static const String paymentMobile = '$_appBase/payment-mobile';
  static const String razorpayRedirect = '$_appBase/razorpay/redirect';

q  static const String defaultZoneId = '[2]';

  // ── Headers ───────────────────────────────────────────────────────────────
  // NOTE: header keys must be lowercase — the server rejects camelCase.
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'moduleid': '$moduleId',
    'zoneid': defaultZoneId,
  };

  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
