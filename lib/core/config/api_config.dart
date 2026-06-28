import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override at build/run time:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) return _override.trim();

    // Presentations / templates API.
    return 'https://smartslides-api.vercel.app';
  }

  /// Auth + tokens API (watch-ad, profile, login…).
  static String get authBaseUrl =>
      'https://smartslidessessions.vercel.app/api/auth';

  static Map<String, String> get defaultHeaders {
    // Some hosts (proxies/CDNs) behave better with an explicit UA.
    return <String, String>{
      if (!kIsWeb) 'User-Agent': 'SmartSlides/1.0',
      'Accept': 'application/json',
    };
  }
}

