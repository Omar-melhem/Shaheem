/// Every route path in the app. Widgets and the router use these constants;
/// raw path strings are never written elsewhere.
class RoutesString {
  // Startup and authentication (public, outside the main shell).
  static const String splash = '/';
  static const String noInternet = '/no-internet';
  static const String login = '/login';

  // Main navigation shell (protected). One path per branch, in bar order.
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String currentOrder = '/current-order';
  static const String orderHistory = '/order-history';
  static const String profile = '/profile';
}
