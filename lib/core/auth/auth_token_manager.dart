import 'package:flutter/foundation.dart';
import 'auth_token_store.dart';

/// Thin wrapper that adds a reactive [isLoggedInNotifier] on top of
/// the platform-specific [AuthTokenStore].
class AuthTokenManager {
  static final AuthTokenManager instance = AuthTokenManager._();

  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);

  AuthTokenManager._();

  Future<void> init() async {
    await AuthTokenStore.instance.init();
  }

  Future<void> saveToken(String token) async {
    await AuthTokenStore.instance.saveToken(token);
    isLoggedInNotifier.value = true;
  }

  Future<String?> getToken() async {
    return AuthTokenStore.instance.getToken();
  }

  Future<void> clearToken() async {
    await AuthTokenStore.instance.clearToken();
    isLoggedInNotifier.value = false;
  }

  Future<void> checkLoginStatus() async {
    final token = await AuthTokenStore.instance.getToken();
    isLoggedInNotifier.value = token != null;
  }
}
