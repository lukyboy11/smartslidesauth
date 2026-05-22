import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/settings/settings_store.dart';
import '../../main.dart';
import '../auth/auth_screen.dart';
import '../../core/auth/auth_token_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = themeModeNotifier.value == ThemeMode.dark;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await SettingsStore.instance.getDarkMode();
      if (!mounted) return;
      setState(() {
        _isDark = value;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _isDark = value);

    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    AppTheme.applySystemUiForTheme(value ? ThemeMode.dark : ThemeMode.light);

    try {
      await SettingsStore.instance.setDarkMode(value);
    } catch (_) {
      // Ignore persistence errors; UI remains responsive.
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.surface,
      appBar: AppBar(
        backgroundColor: appColors.surfaceContainerLow.withOpacity(0.7),
        elevation: 0,
        title: Text(
          'Paramètre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: appColors.onSurface,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: appColors.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: AppTheme.cardDecoration(appColors),
                  child: SwitchListTile(
                    value: _isDark,
                    onChanged: _setDarkMode,
                    title: Text(
                      _isDark ? 'Dark mode' : 'Light mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: appColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _isDark
                          ? 'Mode sombre activé'
                          : 'Mode clair activé',
                      style: TextStyle(color: appColors.onSurfaceVariant),
                    ),
                    secondary: Icon(
                      _isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: appColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.cardDecoration(appColors),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: AuthTokenManager.instance.isLoggedInNotifier,
                    builder: (context, isLoggedIn, child) {
                      return ListTile(
                        onTap: () async {
                          if (isLoggedIn) {
                            await AuthTokenManager.instance.clearToken();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Déconnexion réussie'),
                                  backgroundColor: appColors.primary,
                                ),
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          }
                        },
                        title: Text(
                          isLoggedIn ? 'Se déconnecter' : 'Account / Connexion',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: appColors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          isLoggedIn ? 'Fermer votre session' : 'Se connecter ou s\'inscrire',
                          style: TextStyle(color: appColors.onSurfaceVariant),
                        ),
                        trailing: Icon(
                          isLoggedIn ? Icons.logout_rounded : Icons.arrow_forward_ios_rounded,
                          color: appColors.primary,
                          size: 16,
                        ),
                        leading: Icon(
                          isLoggedIn ? Icons.logout_rounded : Icons.person_outline_rounded,
                          color: appColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

