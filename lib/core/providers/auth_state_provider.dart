import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the user is currently authenticated (past the lock screen).
/// Reset to false when the app is locked.
class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void authenticate() => state = true;
  void lock() => state = false;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);
