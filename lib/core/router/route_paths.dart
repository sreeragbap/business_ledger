/// Every URL path segment used by `AppRouter`, in one place.
///
/// auto_route joins a child path onto its parent, so tab segments are
/// relative ([dashboard]) and their resolved forms ([homeDashboard]) are for
/// anywhere a real URL is needed. An absolute path inside `children` breaks
/// nested routing.
abstract final class RoutePaths {
  // --- Top level -------------------------------------------------------------
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String lock = '/lock';
  static const String businessPicker = '/businesses';
  static const String home = '/home';

  // --- Tabs (segments, relative to [home]) ----------------------------------
  static const String dashboard = 'dashboard';
  static const String transactions = 'transactions';
  static const String reports = 'reports';
  static const String settings = 'settings';

  // --- Tabs (resolved) -------------------------------------------------------
  static const String homeDashboard = '$home/$dashboard';
  static const String homeTransactions = '$home/$transactions';
  static const String homeReports = '$home/$reports';
  static const String homeSettings = '$home/$settings';
}
