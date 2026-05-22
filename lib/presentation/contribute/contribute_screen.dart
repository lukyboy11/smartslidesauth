import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class ContributeScreen extends StatelessWidget {
  const ContributeScreen({super.key});

  // ── Contact for personalization requests
  static final Uri _personalizeUri = Uri.parse(
    'https://wa.me/212610962163?text=Bonjour%20Smart%20Slides%2C%20je%20voudrais%20personnaliser%20ma%20présentation.',
  );

  // ── Contact for contributing presentations
  static final Uri _contributeUri = Uri.parse(
    'https://wa.me/212615905041?text=Bonjour%20Smart%20Slides%2C%20je%20voudrais%20contribuer%20et%20partager%20une%20présentation.',
  );

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Impossible d\'ouvrir WhatsApp pour le moment.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: appColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 720 ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header
                      _EntranceReveal(
                        delayMs: 0,
                        child: _Header(
                          title: 'Contribuer',
                          textTheme: textTheme,
                          appColors: appColors,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Intro hero card
                      _EntranceReveal(
                        delayMs: 80,
                        child: _HeroCard(
                          textTheme: textTheme,
                          appColors: appColors,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Section title
                      _EntranceReveal(
                        delayMs: 140,
                        child: Text(
                          'Choisissez votre action',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: appColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Card 1: Personalize
                      _EntranceReveal(
                        delayMs: 200,
                        child: _ActionCard(
                          appColors: appColors,
                          textTheme: textTheme,
                          icon: Icons.tune_rounded,
                          tag: 'Personnalisation',
                          title: 'Personnaliser ma présentation',
                          description:
                              'Vous souhaitez une présentation sur mesure ? '
                              'Contactez-nous directement et nous vous aidons à créer quelque chose d\'unique.',
                          buttonLabel: 'Nous contacter',
                          pills: const [
                            _Pill(icon: Icons.draw_outlined, label: 'Sur mesure'),
                            _Pill(icon: Icons.speed_rounded, label: 'Rapide'),
                            _Pill(icon: Icons.star_outline_rounded, label: 'Premium'),
                          ],
                          onTap: () => _launchUri(context, _personalizeUri),
                          gradientColors: [
                            appColors.primary,
                            appColors.secondary,
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Card 2: Contribute
                      _EntranceReveal(
                        delayMs: 280,
                        child: _ActionCard(
                          appColors: appColors,
                          textTheme: textTheme,
                          icon: Icons.upload_file_rounded,
                          tag: 'Contribution',
                          title: 'Partager une présentation',
                          description:
                              'Vous avez une présentation de qualité ? '
                              'Partagez-la avec la communauté et aidez des milliers d\'étudiants.',
                          buttonLabel: 'Envoyer ma présentation',
                          pills: const [
                            _Pill(icon: Icons.groups_rounded, label: 'Communauté'),
                            _Pill(icon: Icons.favorite_outline_rounded, label: 'Gratuit'),
                            _Pill(icon: Icons.verified_outlined, label: 'Validé'),
                          ],
                          onTap: () => _launchUri(context, _contributeUri),
                          gradientColors: [
                            appColors.primary,
                            appColors.secondary,
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Bottom info strip
                      _EntranceReveal(
                        delayMs: 360,
                        child: _InfoStrip(
                          appColors: appColors,
                          textTheme: textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.textTheme,
    required this.appColors,
  });

  final String title;
  final TextTheme textTheme;
  final AppPalette appColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [appColors.primary, appColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.handshake_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.03,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// HERO CARD — intro only, no button
// ══════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.textTheme,
    required this.appColors,
  });

  final TextTheme textTheme;
  final AppPalette appColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: appColors.outlineVariant),
        gradient: LinearGradient(
          colors: [
            appColors.primary,
            appColors.secondary,
            appColors.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue 👋',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.04,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Deux façons de rejoindre Smart Slides',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Que vous vouliez personnaliser vos présentations ou aider la communauté à grandir — nous sommes là pour vous.',
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.88),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ACTION CARD — reusable for both sections
// ══════════════════════════════════════════════════════

class _Pill {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.appColors,
    required this.textTheme,
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.pills,
    required this.onTap,
    required this.gradientColors,
  });

  final AppPalette appColors;
  final TextTheme textTheme;
  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final String buttonLabel;
  final List<_Pill> pills;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: appColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: appColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon + tag row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withOpacity(0.15),
                      gradientColors.last.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: gradientColors.first.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  tag,
                  style: textTheme.labelMedium?.copyWith(
                    color: gradientColors.first,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Title
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: appColors.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // ── Description
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: appColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // ── Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills.map((p) => _FeaturePill(
              icon: p.icon,
              label: p.label,
              appColors: appColors,
              color: gradientColors.first,
            )).toList(),
          ),
          const SizedBox(height: 20),

          // ── WhatsApp button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // WhatsApp icon built from shapes
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      buttonLabel,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// FEATURE PILL
// ══════════════════════════════════════════════════════

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.appColors,
    required this.color,
  });

  final IconData icon;
  final String label;
  final AppPalette appColors;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: appColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: appColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// INFO STRIP — bottom reassurance bar
// ══════════════════════════════════════════════════════

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.appColors,
    required this.textTheme,
  });

  final AppPalette appColors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: appColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: appColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos messages sont privés. Personne d\'autre ne peut les voir.',
              style: textTheme.bodySmall?.copyWith(
                color: appColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ENTRANCE ANIMATION
// ══════════════════════════════════════════════════════

class _EntranceReveal extends StatelessWidget {
  const _EntranceReveal({
    required this.child,
    required this.delayMs,
  });

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 560 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}