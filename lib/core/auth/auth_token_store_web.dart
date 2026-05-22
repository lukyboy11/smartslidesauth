// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'auth_token_store.dart';

class WebAuthTokenStore implements AuthTokenStore {
  static const _key = 'smartslides.auth_token';

  @override
  Future<void> init() async {}

  @override
  Future<void> saveToken(String token) async {
    html.window.localStorage[_key] = token;
  }

  @override
  Future<String?> getToken() async {
    return html.window.localStorage[_key];
  }

  @override
  Future<void> clearToken() async {
    html.window.localStorage.remove(_key);
  }
}

final AuthTokenStore authTokenStoreInstance = WebAuthTokenStore();
