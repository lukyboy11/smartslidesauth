import 'package:flutter/material.dart';

import '../../core/settings/settings_store.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      title: 'Thousands of Presentations',
      description:
          'Access a growing library of ready-to-use slides, PDFs and templates — all in one place, always available.',
      // ╔══════════════════════════════════════════════════╗
      // ║  IMAGE SLOT 1                                    ║
      // ║  When your image is ready:                       ║
      // ║  1. Put your PNG in assets/images/               ║
      // ║  2. Replace '' with 'assets/images/slide_1.png'  ║
      // ╚══════════════════════════════════════════════════╝
      imagePath: 'assets/onboarding/slide1.png',
    ),
    _SlideData(
      title: 'Find What You Need Fast',
      description:
          'Search by keyword, filter by type or category, and instantly find the presentation that fits your needs.',
      // ╔══════════════════════════════════════════════════╗
      // ║  IMAGE SLOT 2                                    ║
      // ║  When your image is ready:                       ║
      // ║  1. Put your PNG in assets/images/               ║
      // ║  2. Replace '' with 'assets/images/slide_2.png'  ║
      // ╚══════════════════════════════════════════════════╝
      imagePath: 'assets/onboarding/slide2.png',
    ),
    _SlideData(
      title: 'Download & Present',
      description:
          'Download any file directly to your device and open it instantly — ready to present anywhere, anytime.',
      // ╔══════════════════════════════════════════════════╗
      // ║  IMAGE SLOT 3                                    ║
      // ║  When your image is ready:                       ║
      // ║  1. Put your PNG in assets/images/               ║
      // ║  2. Replace '' with 'assets/images/slide_3.png'  ║
      // ╚══════════════════════════════════════════════════╝
      imagePath: 'assets/onboarding/slide3.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SettingsStore.instance.setOnboardingSeen(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: appColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(),

                        // ════════════════════════════════════════
                        // IMAGE AREA
                        // Height: 280px — change if needed
                        // When imagePath is empty → invisible space
                        // When imagePath is set   → your image shows
                        // No background, no border, no container
                        // PNG transparent background works perfectly
                        // ════════════════════════════════════════
                        SizedBox(
                          height: 280,
                          child: slide.imagePath.isNotEmpty
                              ? Image.asset(
                                  slide.imagePath,
                                  fit: BoxFit.contain,
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 32),

                        // ── Slide counter
                        Text(
                          '${index + 1} of ${_slides.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: appColors.primary.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: appColors.onSurface,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: appColors.onSurfaceVariant,
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: index == _page ? 28 : 8,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? appColors.primary
                        : appColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isLast) {
                      await _finish();
                      return;
                    }
                    await _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    foregroundColor: appColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide Data ──
class _SlideData {
  const _SlideData({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;

  // ── SET YOUR IMAGE PATH HERE ──
  // Leave as '' until your image is ready
  // Then replace with: 'assets/images/your_image.png'
  final String imagePath;
}