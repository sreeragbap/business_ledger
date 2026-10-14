/// The build flavors. Each has its own entrypoint (`main_dev.dart`,
/// `main_prod.dart`) and its own Firebase options file.
enum Flavor {
  dev('Business Ledger Dev'),
  prod('Business Ledger');

  const Flavor(this.title);

  /// Display name shown in the task switcher and the app bar fallbacks.
  final String title;
}
