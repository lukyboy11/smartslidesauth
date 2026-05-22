import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/config/api_config.dart';
import 'core/settings/settings_store.dart';
import 'core/theme/app_theme.dart';
import 'main.dart';
import 'presentation/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final Timer _navigationTimer;
  late final AnimationController _iconAnimationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup a simple fade-in animation for the icon
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward(); // Plays once and stays on screen

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // 2. Start warming backend immediately in background
    _prewarmBackend();

    // 3. Navigate after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _goNext();
    });
  }

  // Silently ping backend during splash so it's warm when home loads
  Future<void> _prewarmBackend() async {
    try {
      await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/templates?limit=10'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Fail silently — this is just a warm-up ping
    }
  }

  Future<void> _goNext() async {
    bool seen = false;
    try {
      await SettingsStore.instance.init();
      seen = await SettingsStore.instance.getOnboardingSeen();
    } catch (_) {
      seen = false;
    }

    if (!mounted) return;

    final next = seen ? const MainNavigation() : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splashColors = AppPalettes.light;

    return Scaffold(
      backgroundColor: splashColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with a clean fade-in effect
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/logo/SMARTSLIDES.png', // Ensure this matches your pubspec.yaml
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.auto_awesome, size: 80, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'SmartSlides',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: splashColors.onSurface,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Study smarter. Present better.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: splashColors.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const _PulsingDots(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '© 2025 Developed with ♥ by Clover Labs',
                style: TextStyle(
                  fontSize: 11,
                  color: splashColors.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splashColors = AppPalettes.light;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final double opacity =
                ((_controller.value + (index * 0.3)) % 1.0).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: splashColors.primary.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}