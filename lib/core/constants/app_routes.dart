/// Named routes. Screens navigate by name so features never import each other's
/// screens (no circular imports); the route table lives in app.dart.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role';
  static const String customerHome = '/customer';
  static const String providerHome = '/provider';

  /// Panel route for a signed-in user.
  static String home({required bool isProvider}) =>
      isProvider ? providerHome : customerHome;
}
