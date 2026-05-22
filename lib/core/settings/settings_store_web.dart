// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'settings_store.dart';

class WebSettingsStore implements SettingsStore {
  static const _keyDarkMode = 'smartslides.dark_mode';
  static const _keyOnboardingSeen = 'smartslides.onboarding_seen';

  @override
  Future<void> init() async {}

  @override
  Future<bool> getDarkMode() async {
    final raw = html.window.localStorage[_keyDarkMode];
    if (raw == null) return true; // Default to dark mode for new web users
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  @override
  Future<void> setDarkMode(bool value) async {
    html.window.localStorage[_keyDarkMode] = value ? '1' : '0';
  }

  @override
  Future<bool> getOnboardingSeen() async {
    final raw = html.window.localStorage[_keyOnboardingSeen];
    return raw == '1' || raw?.toLowerCase() == 'true';
  }

  @override
  Future<void> setOnboardingSeen(bool value) async {
    html.window.localStorage[_keyOnboardingSeen] = value ? '1' : '0';
  }
}

final SettingsStore settingsStoreInstance = WebSettingsStore();

