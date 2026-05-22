import 'settings_store.dart';

class StubSettingsStore implements SettingsStore {
  bool _darkMode = true;
  bool _onboardingSeen = false;

  @override
  Future<void> init() async {}

  @override
  Future<bool> getDarkMode() async => _darkMode;

  @override
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
  }

  @override
  Future<bool> getOnboardingSeen() async => _onboardingSeen;

  @override
  Future<void> setOnboardingSeen(bool value) async {
    _onboardingSeen = value;
  }
}

final SettingsStore settingsStoreInstance = StubSettingsStore();

