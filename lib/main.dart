import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/navigation/navigation_visibility_controller.dart';
import 'core/settings/settings_store.dart';
import 'core/theme/app_theme.dart';
import 'presentation/contribute/contribute_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/community/community_screen.dart';
import 'core/auth/auth_token_manager.dart';
import 'splash_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.dark,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Load saved theme from storage BEFORE rendering ──
  try {
    await SettingsStore.instance.init();
    final isDark = await SettingsStore.instance.getDarkMode();
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {
    themeModeNotifier.value = ThemeMode.dark;
  }

  // ── 2. Load auth status BEFORE rendering ──
  try {
    await AuthTokenManager.instance.init();
    await AuthTokenManager.instance.checkLoginStatus();
  } catch (_) {}

  AppTheme.applySystemUiForTheme(themeModeNotifier.value);

  runApp(const MyApp());

  // ── 3. Bootstrap ads / orientation in the background ──
  unawaited(_bootstrapApp());
}

Future<void> _bootstrapApp() async {
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartSlides',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _handleNavTap(int index) {
    setHomeChromeVisible(true);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return ValueListenableBuilder<bool>(
      valueListenable: AuthTokenManager.instance.isLoggedInNotifier,
      builder: (context, isLoggedIn, _) {
        final pages = [
          const HomeScreen(),
          const ContributeScreen(),
          if (isLoggedIn) const CommunityScreen(),
          const SettingsScreen(),
        ];
        
        if (_currentIndex >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = pages.length - 1);
          });
        }
        final safeIndex = _currentIndex >= pages.length ? pages.length - 1 : _currentIndex;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(index: safeIndex, children: pages),
              Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<bool>(
                  valueListenable: homeChromeVisibleNotifier,
                  builder: (context, isHomeChromeVisible, child) {
                    final shouldShowNav = safeIndex != 0 || isHomeChromeVisible;

                    return AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      offset: shouldShowNav ? Offset.zero : const Offset(0, 1.0),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: shouldShowNav ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !shouldShowNav,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: appColors.surfaceContainerLow.withOpacity(0.98),
                      border: Border(
                        top: BorderSide(
                          color: appColors.outlineVariant.withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(0, Icons.home_rounded, 'Accueil', safeIndex),
                            _buildNavItem(1, Icons.handshake_outlined, 'Contribuer', safeIndex),
                            if (isLoggedIn) _buildNavItem(2, Icons.people_alt_rounded, 'Community', safeIndex),
                            _buildNavItem(isLoggedIn ? 3 : 2, Icons.settings_rounded, 'Paramètre', safeIndex),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int safeIndex) {
    final isSelected = safeIndex == index;
    final appColors = context.appColors;

    return GestureDetector(
      onTap: () => _handleNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.secondaryContainer.withOpacity(0.32)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? appColors.primary
                  : appColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? appColors.primary
                    : appColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}