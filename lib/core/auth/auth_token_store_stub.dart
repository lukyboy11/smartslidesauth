import 'auth_token_store.dart';

class StubAuthTokenStore implements AuthTokenStore {
  String? _token;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

final AuthTokenStore authTokenStoreInstance = StubAuthTokenStore();
