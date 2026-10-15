/// Which provider a social sign-in goes through.
enum SocialSignInMethod {
  google('google', 'Continue with Google'),
  apple('apple', 'Continue with Apple'),

  /// Email/password test account on the Auth emulator. Offered only when
  /// running with `USE_EMULATOR=true`; Google and Apple need a real app.
  emulatorTestAccount('emulator', 'Continue with test account');

  const SocialSignInMethod(this.key, this.label);

  final String key;

  /// Button copy.
  final String label;

  static SocialSignInMethod fromKey(String? key) =>
      values.firstWhere((method) => method.key == key, orElse: () => google);
}
