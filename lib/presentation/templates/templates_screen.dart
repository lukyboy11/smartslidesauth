import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES DE DONNÉES
// Ces classes sont isolées et ne dépendent d'aucun state manager externe.
// ─────────────────────────────────────────────────────────────────────────────

/// Représente un template de présentation retourné par l'API.
class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.name,
    required this.url,
    required this.thumbnail,
    this.downloadUrl = '',
  });

  final String id;
  final String name;
  final String url;
  final String thumbnail;
  final String downloadUrl;

  /// Parse un objet JSON en [TemplateItem].
  /// Chaque champ est sécurisé avec un fallback par défaut.
  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sans nom',
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
    );
  }
}

/// Enveloppe la réponse complète de GET /api/templates.
class TemplatesApiResponse {
  const TemplatesApiResponse({
    required this.status,
    required this.count,
    required this.data,
  });

  final String status;
  final int count;
  final List<TemplateItem> data;

  factory TemplatesApiResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? <dynamic>[];

    return TemplatesApiResponse(
      status: json['status']?.toString() ?? '',
      count: json['count'] as int? ?? rawData.length,
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map(TemplateItem.fromJson)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL : TemplatesScreen
// ─────────────────────────────────────────────────────────────────────────────

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  // ── Constantes AdMob ──────────────────────────────────────────────────
  /// ID de test officiel Android pour les pubs interstitielles.
  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // ── État local ─────────────────────────────────────────────────────────
  final Dio _dio = Dio();

  List<TemplateItem> _templates = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _downloadingTemplateId; // ID du template en cours de téléchargement
  double _downloadProgress = 0.0;
  String? _errorMessage;
  InterstitialAd? _interstitialAd;
  TemplateItem? _pendingDownloadTemplate;
  bool _isUploading = false;

  // Animation du FAB
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de "pulse" du FAB pour attirer l'attention
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );

    // Initialise les pubs et récupère la liste des templates
    _initializeAds();
    _fetchTemplates();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _interstitialAd?.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // 1️⃣  RÉSOLUTION DE L'URL DE BASE
  // ─────────────────────────────────────────────────────────────────────

  /// Sur un téléphone physique connecté au même Wi-Fi, on utilise l'IP locale (192.168.11.101).
  String _resolveBaseUrl() {
    return ApiConfig.baseUrl;
  }
  // ─────────────────────────────────────────────────────────────────────
  // 2️⃣  APPEL API : Récupération des templates (GET)
  // ─────────────────────────────────────────────────────────────────────

  /// Appelle GET /api/templates et met à jour l'état.
  /// Gère 3 états : Chargement → Erreur OU Succès.
  Future<void> _fetchTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      http.Response? response;
      Object? lastError;

      // Retry once because cloud backends can be cold on first request.
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final uri = Uri.parse(
            '${_resolveBaseUrl()}/api/templates?t=${DateTime.now().millisecondsSinceEpoch}',
          );
          response = await http
              .get(uri, headers: ApiConfig.defaultHeaders)
              .timeout(const Duration(seconds: 45));
          break;
        } catch (e) {
          lastError = e;
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (response == null) {
        throw Exception(lastError ?? 'Aucune réponse du serveur.');
      }

      // Vérifie le code HTTP avant de parser
      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body.isEmpty ? '(empty body)' : response.body}',
        );
      }

      // Désérialise la réponse JSON en objets Dart
      final Map<String, dynamic> jsonMap =
          jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = TemplatesApiResponse.fromJson(jsonMap);

      if (!mounted) return;

      setState(() {
        _templates = apiResponse.data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        final baseUrl = _resolveBaseUrl();
        _errorMessage =
            'Impossible de charger les templates.\n'
            'Backend: $baseUrl\n'
            'Détail: $error\n'
            'Astuce: le serveur peut être en veille, réessaie dans 10-20 secondes.';
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // 3️⃣  MONÉTISATION (AdMob) : Préchargement de l'interstitielle
  // ─────────────────────────────────────────────────────────────────────

  /// Initialise le SDK AdMob puis précharge une pub interstitielle.
  Future<void> _initializeAds() async {
    await MobileAds.instance.initialize();
    _preloadInterstitialAd();
  }

  /// Charge une nouvelle pub interstitielle en arrière-plan.
  /// Si elle échoue, on la laisse null → le téléchargement se fera sans pub.
void _preloadInterstitialAd() {
    debugPrint('⏳ Demande de publicité envoyée à Google...'); // <-- AJOUT
    
    InterstitialAd.load(
      adUnitId: _androidTestInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ PUBLICITÉ PRÊTE ET CHARGÉE !'); // <-- AJOUT
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        // 👇 C'est ici qu'on va capturer la vraie raison du blocage
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ ERREUR ADMOB : ${error.message} (Code: ${error.code})'); // <-- AJOUT
          _interstitialAd = null;
        },
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────
  // 4️⃣  LOGIQUE DE TÉLÉCHARGEMENT
  //     Clic → Affiche la pub → Fermeture pub → Téléchargement → Ouverture
  // ─────────────────────────────────────────────────────────────────────

  /// Gère le clic sur le bouton "Télécharger" d'un template.
  Future<void> _onDownloadPressed(TemplateItem template) async {
    // Empêche les téléchargements simultanés
    if (_isDownloading) return;

    _pendingDownloadTemplate = template;

    final ad = _interstitialAd;

    // Si aucune pub n'est prête, on lance le téléchargement directement
    if (ad == null) {
      await _startDownload(template);
      _preloadInterstitialAd(); // On recharge une pub pour la prochaine fois
      return;
    }

    // Configure les callbacks pour savoir quand la pub se ferme
    ad.fullScreenContentCallback = FullScreenContentCallback(
      // ✅ L'utilisateur a fermé la pub → on lance le téléchargement
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        _interstitialAd = null;

        final templateToDownload = _pendingDownloadTemplate;
        _pendingDownloadTemplate = null;

        _preloadInterstitialAd(); // Recharge pour la prochaine fois

        if (templateToDownload != null) {
          await _startDownload(templateToDownload);
        }
      },
      // ❌ La pub n'a pas pu s'afficher → on télécharge quand même
      onAdFailedToShowFullScreenContent: (ad, _) async {
        ad.dispose();
        _interstitialAd = null;

        final templateToDownload = _pendingDownloadTemplate;
        _pendingDownloadTemplate = null;

        _preloadInterstitialAd();

        if (templateToDownload != null) {
          await _startDownload(templateToDownload);
        }
      },
    );

    // Affiche la pub interstitielle
    ad.show();
  }

  /// Télécharge le fichier avec Dio, le sauvegarde dans le dossier
  /// temporaire (path_provider) puis l'ouvre avec open_filex.
  Future<void> _startDownload(TemplateItem template) async {
    setState(() {
      _isDownloading = true;
      _downloadingTemplateId = template.id;
      _downloadProgress = 0.0;
    });

    try {
      // Récupère le chemin du dossier temporaire de l'app
      final directory = await getTemporaryDirectory();
      final sanitizedFileName = _sanitizeFileName(template.name);
      final filePath = '${directory.path}/$sanitizedFileName.pptx';

      // Télécharge le fichier depuis l'URL de téléchargement direct
      final dlUrl = template.downloadUrl.isNotEmpty ? template.downloadUrl : template.url;
      await _dio.download(
        dlUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          // Met à jour la barre de progression en temps réel
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Ouvre le fichier automatiquement après le téléchargement
      final result = await OpenFilex.open(filePath);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        _showSnackBar(
          'Fichier téléchargé, mais ouverture impossible : ${result.message}',
          isError: true,
        );
      } else {
        _showSnackBar('${template.name} a été téléchargé et ouvert ! 🎉');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Échec du téléchargement de ${template.name}.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingTemplateId = null;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  /// Nettoie le nom du fichier pour éviter les caractères interdits.
  String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  // ─────────────────────────────────────────────────────────────────────
  // 5️⃣  UPLOAD : Sélection de fichier + envoi POST multipart
  // ─────────────────────────────────────────────────────────────────────

  /// Ouvre le sélecteur de fichier (restreint à pdf, ppt, pptx),
  /// puis prépare l'envoi via POST multipart/form-data.
  Future<void> _pickAndUploadFile() async {
    try {
      // Ouvre le sélecteur natif, restreint aux extensions autorisées
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      // L'utilisateur a annulé la sélection
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;

      // Vérifie qu'on a bien un chemin (non-null sur mobile)
      if (pickedFile.path == null) {
        _showSnackBar(
          'Impossible d\'accéder au fichier sélectionné.',
          isError: true,
        );
        return;
      }

      // Affiche un dialog de confirmation avant l'envoi
      if (!mounted) return;
      final shouldUpload = await _showUploadConfirmDialog(pickedFile);

      if (shouldUpload != true) return;

      // Lance l'envoi du fichier vers le serveur
      await _uploadFileToServer(pickedFile);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Erreur lors de la sélection du fichier : $error',
        isError: true,
      );
    }
  }

  /// Affiche un dialog de confirmation avec les détails du fichier.
  Future<bool?> _showUploadConfirmDialog(PlatformFile file) {
    final appColors = context.appColors;
    final fileSizeMB = (file.size / (1024 * 1024)).toStringAsFixed(2);
    final extension = file.extension?.toUpperCase() ?? '?';

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.cloud_upload,
                color: appColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmer l\'envoi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: appColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Carte d'aperçu du fichier
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Badge d'extension
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      extension,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: appColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: appColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$fileSizeMB MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ce fichier sera envoyé à ton serveur local pour traitement.',
              style: TextStyle(
                fontSize: 13,
                color: appColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: appColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(CupertinoIcons.cloud_upload, size: 16),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  /// Envoie le fichier sélectionné vers POST /api/upload
  /// en multipart/form-data grâce à Dio.
  Future<void> _uploadFileToServer(PlatformFile file) async {
    setState(() => _isUploading = true);

    try {
      final filePath = file.path!;
      final fileName = file.name;

      // Prépare le formulaire multipart avec le fichier
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      debugPrint('──────────────────────────────────────────');
      debugPrint('📤 Upload en cours...');
      debugPrint('   Fichier : $fileName');
      debugPrint('   Chemin  : $filePath');
      debugPrint('   Taille  : ${(file.size / 1024).toStringAsFixed(1)} KB');
      debugPrint('   URL     : ${_resolveBaseUrl()}/api/upload');
      debugPrint('──────────────────────────────────────────');

      // Envoie la requête POST multipart vers le backend
      final response = await _dio.post(
        '${_resolveBaseUrl()}/api/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          // Log de la progression de l'envoi
          if (total > 0) {
            final percent = ((sent / total) * 100).toStringAsFixed(0);
            debugPrint('   Progression : $percent%');
          }
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('$fileName envoyé avec succès ! 🚀');
        // Rafraîchit la liste pour voir le nouveau template
        _fetchTemplates();
      } else {
        _showSnackBar(
          'Le serveur a répondu avec le code ${response.statusCode}.',
          isError: true,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      debugPrint('❌ Erreur Dio : ${e.message}');
      _showSnackBar(
        'Échec de l\'envoi. Vérifie que le serveur est en marche.',
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Erreur inattendue : $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // UTILITAIRES UI
  // ─────────────────────────────────────────────────────────────────────

  /// Affiche une SnackBar stylisée avec un message.
  void _showSnackBar(String message, {bool isError = false}) {
    final appColors = context.appColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError
            ? appColors.errorContainer
            : appColors.inverseSurface,
        content: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle
                  : CupertinoIcons.checkmark_alt_circle,
              color: isError
                  ? appColors.onErrorContainer
                  : appColors.inverseOnSurface,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? appColors.onErrorContainer
                      : appColors.inverseOnSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CONSTRUCTION DE L'UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.surface,
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _isUploading ? null : _pickAndUploadFile,
          icon: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(CupertinoIcons.cloud_upload),
          label: Text(
            _isUploading ? 'Envoi en cours...' : 'Ajouter',
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          elevation: 8,
          backgroundColor: appColors.primary,
          foregroundColor: appColors.onPrimary,
        ),
      ),
      body: Stack(
        children: [
          // ── ORBES ARRIÈRE-PLAN (Style Moderne Glass) ──
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.primary.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.tertiary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // ── CONTENU DYNAMIQUE ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(
                title: const Text('Templates', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: _isLoading ? null : _fetchTemplates,
                    icon: Icon(CupertinoIcons.refresh, color: appColors.primary),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: _buildHeaderBanner(),
              ),
              _buildSliverBody(),
            ],
          ),
        ],
      ),
    );
  }

  /// Bannière d'en-tête premium et colorée
  Widget _buildHeaderBanner() {
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appColors.primary.withOpacity(0.85),
            appColors.primary.withOpacity(1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: appColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore ton catalogue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Découvre, clique, regarde une pub et télécharge des designs incroyables pour briller.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gestion des Slivers pour le contenu
  Widget _buildSliverBody() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: _TemplatesLoadingView());
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: _TemplatesErrorView(
          message: _errorMessage!,
          onRetry: _fetchTemplates,
        ),
      );
    }

    if (_templates.isEmpty) {
      return SliverToBoxAdapter(
        child: _TemplatesEmptyView(onAddTemplate: _pickAndUploadFile),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final template = _templates[index];
            final isThisDownloading = _downloadingTemplateId == template.id;

            return _TemplateCard(
              template: template,
              isDownloading: isThisDownloading,
              downloadProgress: isThisDownloading ? _downloadProgress : 0.0,
              onDownload: () => _onDownloadPressed(template),
            );
          },
          childCount: _templates.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS PRIVÉS : Carte de template
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateCard extends StatefulWidget {
  const _TemplateCard({
    required this.template,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
  });

  final TemplateItem template;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation =
        Tween<double>(begin: 0, end: 8).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: appColors.primary.withOpacity(_elevationAnimation.value * 0.02 + 0.1),
                  blurRadius: 16 + _elevationAnimation.value * 2,
                  offset: Offset(0, 8 + _elevationAnimation.value),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image miniature full scale
                  Image.network(
                    widget.template.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: appColors.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.photo, size: 36, color: appColors.onSurfaceVariant),
                            const SizedBox(height: 6),
                            Text('Aperçu indisponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: appColors.onSurfaceVariant)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: appColors.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: appColors.primary),
                        ),
                      );
                    },
                  ),

                  // 2. Dégradé sombre en bas pour sublimer le texte
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.85),
                          ],
                          stops: const [0.4, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Badge "Ad" Premium
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.play_circle_fill, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Ad', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Bouton de téléchargement "Verre dépoli"
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: widget.isDownloading ? null : widget.onDownload,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isDownloading ? appColors.primary : Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: widget.isDownloading ? 0 : 8, sigmaY: widget.isDownloading ? 0 : 8),
                          child: widget.isDownloading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                              : const Icon(CupertinoIcons.cloud_download, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),

                  // 5. Titre et Barre de progression
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.isDownloading) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: widget.downloadProgress > 0 ? widget.downloadProgress : null,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: appColors.primary,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS D'ÉTAT : Chargement / Erreur / Vide
// ─────────────────────────────────────────────────────────────────────────────

/// Vue de chargement avec des skeleton cards animées.
class _TemplatesLoadingView extends StatelessWidget {
  const _TemplatesLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, index) => _TemplateSkeletonCard(index: index),
      ),
    );
  }
}

/// Skeleton card avec animation de shimmer.
class _TemplateSkeletonCard extends StatefulWidget {
  const _TemplateSkeletonCard({required this.index});
  final int index;

  @override
  State<_TemplateSkeletonCard> createState() => _TemplateSkeletonCardState();
}

class _TemplateSkeletonCardState extends State<_TemplateSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Décalage de l'animation par carte pour un effet cascade
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Card(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: appColors.surfaceContainerHighest
                        .withOpacity(_shimmerAnimation.value),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: appColors.surfaceContainerHighest
                            .withOpacity(_shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 90,
                      decoration: BoxDecoration(
                        color: appColors.surfaceContainerHighest
                            .withOpacity(_shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: appColors.surfaceContainerHighest
                            .withOpacity(_shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vue d'erreur avec bouton de réessai.
class _TemplatesErrorView extends StatelessWidget {
  const _TemplatesErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur dans un cercle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: appColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 36,
                color: appColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oups !',
              style: context.textTheme.titleLarge?.copyWith(
                color: appColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: appColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue affichée quand la liste de templates est vide.
/// Inclut un CTA pour ajouter un template.
class _TemplatesEmptyView extends StatelessWidget {
  const _TemplatesEmptyView({required this.onAddTemplate});

  final VoidCallback onAddTemplate;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration vide
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: appColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.rectangle_stack_badge_person_crop,
                size: 40,
                color: appColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun template',
              style: context.textTheme.titleLarge?.copyWith(
                color: appColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun template disponible pour le moment.\nCommence par en ajouter un !',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: appColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTemplate,
              icon: const Icon(CupertinoIcons.cloud_upload, size: 18),
              label: const Text('Ajouter un template'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
