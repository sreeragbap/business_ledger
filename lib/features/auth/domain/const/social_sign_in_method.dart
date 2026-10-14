/// Which provider a social sign-in goes through.
enum SocialSignInMethod {
  google('google', 'Continue with Google'),
  apple('apple', 'Continue with Apple');

  const SocialSignInMethod(this.key, this.label);

  final String key;

  /// Button copy.
  final String label;

  static SocialSignInMethod fromKey(String? key) =>
      values.firstWhere((method) => method.key == key, orElse: () => google);
}
