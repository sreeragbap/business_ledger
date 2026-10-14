import 'package:equatable/equatable.dart';

/// The signed-in person, as the app needs them. Built from the Firebase user
/// by `AuthService`; nothing above the service sees a Firebase type.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  /// What to call them: their name, else their email, else a fallback.
  String get greetingName {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name.split(' ').first;
    final mail = email?.trim() ?? '';
    if (mail.isNotEmpty) return mail.split('@').first;
    return 'there';
  }

  /// Up to two initials for an avatar placeholder.
  String get initials {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (email ?? '?');
    final words = source
        .split(RegExp(r'[\s@._-]+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.map((word) => word[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl];
}
