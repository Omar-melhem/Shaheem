/// Every route path in the app. Widgets and the router use these constants;
/// raw path strings are never written elsewhere.
class RoutesString {
  // Startup and authentication (public, outside the main shell).
  static const String splash = '/';
  static const String noInternet = '/no-internet';
  static const String login = '/login';

  // Main navigation shell (protected, D-A70). One path per branch, in bar
  // order: Home, My Orders, Wallet, My Account.
  static const String home = '/home';
  static const String orderHistory = '/order-history';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  /// Sub-route of My Orders for one completed order (D-A83), relative to
  /// [orderHistory]; protected like its branch.
  static const String completedOrderDetailsPath = 'completed/:orderId';

  /// The location of the completed-order page for [orderId] (encoded).
  static String completedOrderDetails(String orderId) =>
      '$orderHistory/completed/${Uri.encodeComponent(orderId)}';

  // Protected pages above the shell (not tabs).

  /// The captain's active order and pickup map (D-A73), Back → Home.
  static const String currentOrder = '/current-order';

  /// Settings with the account-deletion entry (D-A78), Back → My Account.
  static const String settings = '/settings';

  /// App identity and version (D-A77), Back → My Account.
  static const String about = '/about';
}
