import 'settings_store_stub.dart'
    if (dart.library.io) 'settings_store_sqlite.dart'
    if (dart.library.html) 'settings_store_web.dart';

/// Single small API to persist/read app settings (dark mode).
abstract class SettingsStore {
  static SettingsStore get instance => settingsStoreInstance;

  Future<void> init();
  Future<bool> getDarkMode();
  Future<void> setDarkMode(bool value);
  Future<bool> getOnboardingSeen();
  Future<void> setOnboardingSeen(bool value);
}

