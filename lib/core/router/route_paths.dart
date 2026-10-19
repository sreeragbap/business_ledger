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

  // --- Business (pushed over the shell) -----------------------------------
  static const String createBusiness = '/businesses/new';
  static const String businessDetails = '/business/details';
  static const String members = '/business/members';
  static const String categories = '/business/categories';
  static const String customFields = '/business/fields';
  static const String parties = '/business/parties';
  static const String projects = '/business/projects';

  // --- Device (pushed over the shell) ---------------------------------------
  /// Cloud sync switch and the outbox.
  static const String sync = '/sync';

  // --- Transactions (pushed over the shell) --------------------------------
  /// A filtered list (the dashboard's "See all").
  static const String transactionList = '/transactions';
  static const String transactionDetail = '/transactions/:transactionId';

  /// Create or edit; not under `/transactions/` so it never matches the
  /// detail path.
  static const String transactionForm = '/transaction-form';

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
