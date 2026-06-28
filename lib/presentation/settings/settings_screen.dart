import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_token_manager.dart';
import '../../core/settings/settings_store.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../auth/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String _androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  String get _rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosTestRewardedAdUnitId;
    }
    return _androidTestRewardedAdUnitId;
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = themeModeNotifier.value == ThemeMode.dark;
  bool _loading = true;
  int? _tokenBalance;
  bool _loadingTokens = false;
  bool _claimingReward = false;
  RewardedAd? _rewardedAd;
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
    AuthTokenManager.instance.isLoggedInNotifier.addListener(_onAuthChanged);
    _load();
    if (!kIsWeb) {
      _preloadRewardedAd();
    }
  }

  @override
  void dispose() {
    AuthTokenManager.instance.isLoggedInNotifier.removeListener(_onAuthChanged);
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (AuthTokenManager.instance.isLoggedInNotifier.value) {
      _loadTokenBalance();
      if (!kIsWeb) {
        _preloadRewardedAd();
      }
    } else {
      setState(() {
        _tokenBalance = null;
        _adReady = false;
      });
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }
  }

  Future<void> _load() async {
    try {
      final value = await SettingsStore.instance.getDarkMode();
      if (!mounted) return;
      setState(() {
        _isDark = value;
        _loading = false;
      });
      if (AuthTokenManager.instance.isLoggedInNotifier.value) {
        await _loadTokenBalance();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTokenBalance() async {
    final jwt = await AuthTokenManager.instance.getToken();
    if (jwt == null || !mounted) return;

    setState(() => _loadingTokens = true);
    final result = await AuthService.getProfile(jwt: jwt);
    if (!mounted) return;

    setState(() {
      _loadingTokens = false;
      if (result['success'] == true) {
        _tokenBalance = result['token'] as int? ?? 0;
      }
    });
  }

  void _preloadRewardedAd() {
    RewardedAd.load(
      adUnitId: widget._rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _rewardedAd = ad;
            _adReady = true;
          });
        },
        onAdFailedToLoad: (_) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = null;
            _adReady = false;
          });
        },
      ),
    );
  }

  Future<void> _watchAdForTokens() async {
    if (!AuthTokenManager.instance.isLoggedInNotifier.value) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Les publicités récompensées sont disponibles sur mobile.',
          ),
          backgroundColor: context.appColors.primary,
        ),
      );
      return;
    }

    final ad = _rewardedAd;
    if (ad == null || !_adReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chargement de la publicité...'),
          backgroundColor: context.appColors.primary,
        ),
      );
      _preloadRewardedAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (mounted) {
          setState(() {
            _rewardedAd = null;
            _adReady = false;
          });
        }
        _preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (mounted) {
          setState(() {
            _rewardedAd = null;
            _adReady = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Impossible d\'afficher la publicité'),
              backgroundColor: context.appColors.error,
            ),
          );
        }
        _preloadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        _claimAdReward();
      },
    );
  }

  Future<void> _claimAdReward() async {
    final jwt = await AuthTokenManager.instance.getToken();
    if (jwt == null || !mounted) return;

    setState(() => _claimingReward = true);
    final result = await AuthService.watchAd(jwt: jwt);
    if (!mounted) return;

    setState(() => _claimingReward = false);

    if (result['success'] == true) {
      setState(() => _tokenBalance = result['token'] as int? ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+${result['rewarded']} tokens ! Solde : ${result['token']}',
          ),
          backgroundColor: context.appColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Erreur lors de l\'ajout des tokens',
          ),
          backgroundColor: context.appColors.error,
        ),
      );
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _isDark = value);

    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    AppTheme.applySystemUiForTheme(value ? ThemeMode.dark : ThemeMode.light);

    try {
      await SettingsStore.instance.setDarkMode(value);
    } catch (_) {}
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
                ValueListenableBuilder<bool>(
                  valueListenable: AuthTokenManager.instance.isLoggedInNotifier,
                  builder: (context, isLoggedIn, _) {
                    if (!isLoggedIn) return const SizedBox.shrink();

                    return Column(
                      children: [
                        Container(
                          decoration: AppTheme.cardDecoration(appColors),
                          child: ListTile(
                            leading: Icon(
                              Icons.toll_rounded,
                              color: appColors.primary,
                            ),
                            title: Text(
                              'Mes tokens',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: appColors.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Solde de votre compte',
                              style: TextStyle(
                                color: appColors.onSurfaceVariant,
                              ),
                            ),
                            trailing: _loadingTokens
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appColors.primary,
                                    ),
                                  )
                                : Text(
                                    '${_tokenBalance ?? '—'}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: appColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: AppTheme.cardDecoration(appColors),
                          child: ListTile(
                            onTap: _claimingReward ? null : _watchAdForTokens,
                            leading: Icon(
                              Icons.play_circle_outline_rounded,
                              color: appColors.primary,
                            ),
                            title: Text(
                              'Get Token',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: appColors.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              kIsWeb
                                  ? 'Disponible sur mobile uniquement'
                                  : 'Regardez une vidéo pub pour +5 tokens',
                              style: TextStyle(
                                color: appColors.onSurfaceVariant,
                              ),
                            ),
                            trailing: _claimingReward
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appColors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: appColors.primary,
                                    size: 16,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
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
                            await Navigator.push(
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
                          isLoggedIn
                              ? 'Fermer votre session'
                              : 'Se connecter ou s\'inscrire',
                          style: TextStyle(color: appColors.onSurfaceVariant),
                        ),
                        trailing: Icon(
                          isLoggedIn
                              ? Icons.logout_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: appColors.primary,
                          size: 16,
                        ),
                        leading: Icon(
                          isLoggedIn
                              ? Icons.logout_rounded
                              : Icons.person_outline_rounded,
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
