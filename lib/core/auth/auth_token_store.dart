import 'auth_token_store_stub.dart'
    if (dart.library.io) 'auth_token_store_sqlite.dart'
    if (dart.library.html) 'auth_token_store_web.dart';

/// Platform-agnostic interface for storing the auth token.
abstract class AuthTokenStore {
  static AuthTokenStore get instance => authTokenStoreInstance;

  Future<void> init();
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}
